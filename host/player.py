"""FPGA PCM receiver/player. No sound synthesis occurs on the PC."""
import sys,threading,time,argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
(ROOT/'reports/usb_audio').mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(ROOT/'usb_audio/python_deps'))
import numpy as np
import serial,serial.tools.list_ports
import sounddevice as sd
from protocol import FrameParser
from audio_buffer import AudioBuffer
def preferred_output(devices,apis):
    """Prefer the local WASAPI route qualified by the hardware playback test."""
    return next((i for i,d in enumerate(devices) if d['max_output_channels']>0 and 'realtek' in d['name'].lower() and 'wasapi' in apis[d['hostapi']]['name'].lower()),None)
class Player:
    def __init__(self,port,baud,device=None):
        self.port,self.baud,self.device=port,baud,device;self.buffer=AudioBuffer();self.parser=FrameParser()
        self.stop_event=threading.Event();self.error='';self.frames=0;self.audio_status=0;self.stream=None;self.serial=None
        self.peak=0;self.max_buffer_ms=0.;self.started_at=None
        self.volume=.2;self._gain=.2;self._gain_target=.2;self._gain_remaining=0
    def set_volume(self,percent):
        value=float(percent)
        if not np.isfinite(value):raise ValueError('音量必须是有限数值')
        self.volume=max(0.,min(100.,value))/100
    def render_audio(self,frames):
        audio=self.buffer.render(frames,self.output_rate)
        target=self.volume
        if target!=self._gain_target:
            self._gain_target=target;self._gain_remaining=max(1,int(self.output_rate*.02))
        if self._gain_remaining:
            n=min(frames,self._gain_remaining)
            gain=np.full(frames,self._gain_target,np.float32)
            gain[:n]=self._gain+(self._gain_target-self._gain)*np.arange(1,n+1)/self._gain_remaining
            self._gain=float(gain[n-1]);self._gain_remaining-=n
            return audio*gain
        return audio*self._gain
    def start(self):
        self.serial=serial.Serial(self.port,self.baud,timeout=.05)
        try:
            self.serial.reset_input_buffer()
            self.started_at=time.monotonic()
            info=sd.query_devices(self.device,'output');self.output_rate=int(info['default_samplerate'])
        except Exception:
            self.serial.close();raise
        def callback(outdata,frames,ti,status):
            if status:self.audio_status+=1
            outdata[:,0]=self.render_audio(frames)
        try:
            self.stream=sd.OutputStream(device=self.device,samplerate=self.output_rate,channels=1,dtype='float32',latency='low',callback=callback)
            self.stream.start()
        except Exception:
            self.serial.close();raise
        self.thread=threading.Thread(target=self.receive,daemon=True);self.thread.start()
    def receive(self):
        try:
            while not self.stop_event.is_set():
                data=self.serial.read(max(1,self.serial.in_waiting))
                for f in self.parser.feed(data):
                    self.buffer.push(f);self.frames+=1
                    self.peak=max(self.peak,max(abs(x) for x in f.samples))
                    self.max_buffer_ms=max(self.max_buffer_ms,self.buffer.queued_ms)
        except Exception as e:self.error=str(e);self.buffer.reset()
    def stats(self):return dict(seconds=round(time.monotonic()-self.started_at,2) if self.started_at else 0,frames=self.frames,crc_errors=self.parser.crc_errors,header_errors=self.parser.header_errors,gaps=self.buffer.gaps,peak=self.peak,buffer_ms=round(self.buffer.queued_ms,1),max_buffer_ms=round(self.max_buffer_ms,1),underruns=self.buffer.underruns,overruns=self.buffer.overruns,audio_status=self.audio_status,error=self.error)
    def close(self):
        self.stop_event.set()
        if hasattr(self,'thread'):self.thread.join(timeout=1)
        if self.serial:self.serial.close()
        if self.stream:self.stream.stop();self.stream.close()
        self.buffer.reset()
def gui():
    import tkinter as tk
    from tkinter import ttk,messagebox
    root=tk.Tk();root.title('Pocket Lab-F1 USB 音频播放器');root.geometry('640x430');root.minsize(640,430)
    ports=list(serial.tools.list_ports.comports());port=tk.StringVar(value=next((p.device for p in ports if 'CH340' in p.description),ports[0].device if ports else ''))
    baud=tk.StringVar(value='460800');device=tk.StringVar(value='默认扬声器')
    outputs={f'{i}: {d["name"]}':i for i,d in enumerate(sd.query_devices()) if d['max_output_channels']>0}
    preferred=preferred_output(sd.query_devices(),sd.query_hostapis())
    if preferred is not None:device.set(next(label for label,i in outputs.items() if i==preferred))
    ttk.Label(root,text='FPGA 合成音频 → USB 串口 → 电脑扬声器',font=('',13)).pack(pady=12)
    for label,var,values in [('串口（连接板载串口 Type-C）',port,[p.device for p in ports]),('串口速率',baud,['921600','460800']),('声音输出',device,['默认扬声器']+list(outputs))]:
        ttk.Label(root,text=label).pack();ttk.Combobox(root,textvariable=var,values=values,width=72).pack()
    holder=[None]
    volume=tk.DoubleVar(value=20);volume_text=tk.StringVar(value='音量：20%')
    def change_volume(value):
        percent=round(float(value));volume_text.set(f'音量：{percent}%')
        if holder[0]:holder[0].set_volume(percent)
    ttk.Label(root,textvariable=volume_text).pack(pady=(12,0))
    volume_row=ttk.Frame(root);volume_row.pack(fill='x',padx=35)
    ttk.Label(volume_row,text='0% 静音').pack(side='left')
    ttk.Scale(volume_row,from_=0,to=100,orient='horizontal',variable=volume,command=change_volume).pack(side='left',fill='x',expand=True,padx=12)
    ttk.Label(volume_row,text='100%').pack(side='left')
    status=tk.StringVar(value='拖动滑块即可调节音量；请选择串口后点击开始。');ttk.Label(root,textvariable=status,wraplength=610).pack(pady=12)
    def stop():
        if holder[0]:holder[0].close();holder[0]=None
        status.set('已停止')
    def start():
        stop()
        try:
            p=Player(port.get(),int(baud.get()),outputs.get(device.get()));p.set_volume(round(volume.get()));p.start();holder[0]=p
            (ROOT/'host/player_settings.json').write_text(json.dumps(dict(port=port.get(),baud=baud.get(),device=device.get()),ensure_ascii=False))
        except Exception as e:messagebox.showerror('启动失败',str(e))
    buttons=ttk.Frame(root);buttons.pack();ttk.Button(buttons,text='开始播放',command=start).pack(side='left',padx=10);ttk.Button(buttons,text='停止',command=stop).pack(side='left')
    def update():
        if holder[0]:
            stats=holder[0].stats()
            if stats['error']:
                status.set('连接已中断，请检查数据线后点击停止，再重新开始。'+stats['error'])
            else:
                status.set(f"播放 {stats['seconds']:.0f} 秒｜收到 {stats['frames']} 包｜缓存 {stats['buffer_ms']:.1f} 毫秒\n校验错误 {stats['crc_errors']}｜缺包 {stats['gaps']}｜缓冲不足 {stats['underruns']}｜声音幅值 {stats['peak']}")
            (ROOT/'reports/usb_audio/player-live.json').write_text(json.dumps(stats,indent=2))
        root.after(500,update)
    def closing():stop();root.destroy()
    root.protocol('WM_DELETE_WINDOW',closing);update();root.mainloop()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--list',action='store_true');ap.add_argument('--port');ap.add_argument('--baud',type=int,default=460800);ap.add_argument('--device',type=int);ap.add_argument('--seconds',type=float);ap.add_argument('--report');a=ap.parse_args()
    if a.list:print(list(serial.tools.list_ports.comports()));print(sd.query_devices());return
    if not a.port:return gui()
    p=Player(a.port,a.baud,a.device);p.start();start=time.monotonic()
    next_report=0.
    try:
        while a.seconds is None or time.monotonic()-start<a.seconds:
            if p.error:raise RuntimeError(p.error)
            if time.monotonic()-start>=next_report:
                stats=p.stats();print(json.dumps(stats),flush=True)
                if a.report:Path(a.report).write_text(json.dumps(stats,indent=2))
                next_report+=30
            time.sleep(.1)
    except KeyboardInterrupt:pass
    finally:
        stats=p.stats();p.close();print(stats)
        if a.report:Path(a.report).write_text(json.dumps(stats,indent=2))
if __name__=='__main__':main()

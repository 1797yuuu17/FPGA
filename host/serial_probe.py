"""Read framed FPGA PCM; strict integrity/throughput gate, no audio playback."""
import sys, argparse,time,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'usb_audio/python_deps'))
import serial
from protocol import FrameParser
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--port',required=True);ap.add_argument('--baud',type=int,default=921600)
    ap.add_argument('--seconds',type=float,default=600);ap.add_argument('--framed',action='store_true');ap.add_argument('--report');a=ap.parse_args()
    p=FrameParser();frames=0;gaps=0;last=None;first=None;peak=0;raw=0
    with serial.Serial(a.port,a.baud,timeout=.05) as s:
        s.reset_input_buffer();start=time.monotonic()
        while time.monotonic()-start<a.seconds:
            data=s.read(max(1,s.in_waiting));raw+=len(data)
            for f in p.feed(data):
                if last is not None and (f.seq!=(last.seq+1)&65535 or f.first_sample!=(last.first_sample+128)&0xffffffff):gaps+=1
                if first is None:first=time.monotonic()
                last=f;frames+=1;peak=max(peak,max(abs(x) for x in f.samples))
    duration=time.monotonic()-start;rate=last.rate if last else 0
    ok=bool(frames and gaps==0 and p.crc_errors==0 and p.header_errors==0 and frames*128>=rate*max(0,duration-.5)*.98)
    result=dict(pass_test=ok,seconds=duration,frames=frames,bytes=raw,gaps=gaps,crc_errors=p.crc_errors,header_errors=p.header_errors,peak=peak,rate=rate)
    print(json.dumps(result,indent=2))
    if a.report:Path(a.report).write_text(json.dumps(result,indent=2))
    return 0 if ok else 1
if __name__=='__main__':sys.exit(main())

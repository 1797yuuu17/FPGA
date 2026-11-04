"""Bounded PCM queue with continuous linear resampling and clock-drift servo."""
import threading
import numpy as np
class AudioBuffer:
    def __init__(self):
        self.lock=threading.Lock();self.gaps=self.underruns=self.overruns=0
        self.rate=25000;self.next_seq=self.next_index=None;self.reset()
    def reset(self):
        with self.lock:
            self.data=np.empty(0,np.float32);self.phase=0.;self.started=False;self.last=0.;self.correction=0.
            self.next_seq=self.next_index=None
    @property
    def queued_ms(self): return len(self.data)*1000/self.rate
    def push(self,frame):
        with self.lock:
            gap=self.next_seq is not None and (frame.seq!=self.next_seq or frame.first_sample!=self.next_index or frame.rate!=self.rate)
            if gap:
                self.gaps+=1;self.data=np.empty(0,np.float32);self.phase=0.;self.started=False;self.correction=0.
            self.rate=frame.rate
            self.next_seq=(frame.seq+1)&65535;self.next_index=(frame.first_sample+128)&0xffffffff
            self.data=np.concatenate((self.data,np.asarray(frame.samples,np.float32)/32768))
            if len(self.data)>self.rate*.1:
                self.overruns+=1;self.data=self.data[-int(self.rate*.04):];self.phase=0.;self.started=False
    def render(self,frames,output_rate):
        with self.lock:
            silence=np.zeros(frames,np.float32)
            fade_in=False
            if not self.started:
                if len(self.data)<self.rate*.04:
                    silence[:min(64,frames)]=np.linspace(self.last,0,min(64,frames))
                    self.last=0.;return silence
                self.started=True;self.last=0.
                fade_in=True
            error=(len(self.data)-self.rate*.04)/self.rate
            wanted=max(-.005,min(.005,error*.2))
            self.correction+=.01*(wanted-self.correction)
            step=self.rate/output_rate*(1+self.correction)
            x=self.phase+np.arange(frames)*step
            if x[-1]+1>=len(self.data):
                self.underruns+=1;out=np.linspace(self.last,0,frames,dtype=np.float32)
                self.data=np.empty(0,np.float32);self.phase=0.;self.started=False;self.last=0.;return out
            out=np.interp(x,np.arange(len(self.data)),self.data).astype(np.float32)
            # Fade only on start/recovery; preserve every steady-state sample.
            if fade_in:
                ramp=min(64,frames);out[:ramp]*=np.linspace(0,1,ramp)
            end=self.phase+frames*step;used=int(end);self.phase=end-used;self.data=self.data[used:]
            self.last=float(out[-1]);return out

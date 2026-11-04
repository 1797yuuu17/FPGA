import sys,unittest
from pathlib import Path
r=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(r/'usb_audio/python_deps'),str(r/'host')]
import numpy as np
from audio_buffer import AudioBuffer
from protocol import AudioFrame
class BufferTests(unittest.TestCase):
    def test_steady_stream_preserves_interpolation(self):
        b=AudioBuffer();x=np.sin(np.arange(1500)*.17).astype(np.float32)
        b.data=x.copy();b.started=True;b.phase=.25
        step=25000/48000*(1+.01*.004)
        expected=np.interp(.25+np.arange(480)*step,np.arange(len(x)),x)
        actual=b.render(480,48000)
        np.testing.assert_allclose(actual,expected,atol=1e-6)
    def test_silence_bound_and_reset(self):
        b=AudioBuffer();self.assertTrue(np.all(b.render(480,48000)==0))
        for i in range(50):b.push(AudioFrame(0,i,i*128,(1000,)*128))
        self.assertLessEqual(b.queued_ms,100)
        b.reset();self.assertEqual(b.queued_ms,0)
    def test_rate_and_drift(self):
        for profile,rate in [(0,24975),(0,25025),(1,12487.5),(1,12512.5)]:
            b=AudioBuffer();seq=0;clock=0
            for i in range(180000):
                clock+=rate/100
                while clock>=128:
                    b.push(AudioFrame(profile,seq&65535,(seq*128)&0xffffffff,(1000,)*128));seq+=1;clock-=128
                b.render(480,48000)
            self.assertLess(b.overruns,3);self.assertLess(b.underruns,3)
            self.assertLess(b.queued_ms,100)
    def test_gap_clears_old_sound(self):
        b=AudioBuffer()
        for i in range(10):b.push(AudioFrame(0,i,i*128,(1000,)*128))
        b.render(480,48000)
        b.push(AudioFrame(0,0,0,(0,)*128))
        self.assertFalse(b.started);self.assertEqual(b.gaps,1)
        last=b.last;out=b.render(480,48000)
        self.assertAlmostEqual(float(out[0]),last,places=6)
        self.assertEqual(float(out[63]),0.)
if __name__=='__main__':unittest.main()

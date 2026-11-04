import sys, unittest, struct
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from protocol import FrameParser, encode_frame, crc16

class ProtocolTests(unittest.TestCase):
    def test_crc(self): self.assertEqual(crc16(b'123456789'),0x29b1)
    def test_split_and_corruption(self):
        a=encode_frame(0,65535,0xffffff80,list(range(-64,64)))
        b=encode_frame(0,0,0,[123]*128)
        p=FrameParser(); frames=[]
        for x in a+b: frames+=p.feed(bytes([x]))
        self.assertEqual(len(frames),2); self.assertEqual(frames[0].samples[0],-64)
        broken=bytearray(a); broken[90]^=1
        p=FrameParser(); self.assertEqual(len(p.feed(b'junk'+broken+b)),1)
        self.assertEqual(p.crc_errors,1)
    def test_bad_header_and_embedded_magic(self):
        a=encode_frame(1,2,256,[0x4c50,0x3146]*64)
        p=FrameParser(); self.assertEqual(p.feed(a)[0].rate,12500)
        bad=bytearray(a); bad[12]=127
        self.assertEqual(len(p.feed(bad+a)),1)

if __name__=='__main__': unittest.main()

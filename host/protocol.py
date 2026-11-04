"""Pocket Lab F1 PCM wire protocol, version 1."""
from dataclasses import dataclass
import binascii, struct
MAGIC=b'PLF1'
def crc16(data): return binascii.crc_hqx(data,0xffff)
@dataclass
class AudioFrame:
    profile:int
    seq:int
    first_sample:int
    samples:tuple
    @property
    def rate(self): return (25000,12500)[self.profile]
def encode_frame(profile,seq,index,samples):
    body=struct.pack('<BBHIH',1,profile,seq,index,128)+struct.pack('<128h',*samples)
    return MAGIC+body+struct.pack('<H',crc16(body))
class FrameParser:
    def __init__(self): self.buffer=bytearray(); self.crc_errors=0; self.header_errors=0
    def feed(self,data):
        self.buffer.extend(data); result=[]
        while True:
            at=self.buffer.find(MAGIC)
            if at<0:
                self.buffer=self.buffer[-3:]; break
            if at: del self.buffer[:at]
            if len(self.buffer)<14: break
            v,p,s,i,n=struct.unpack_from('<BBHIH',self.buffer,4)
            if v!=1 or p not in (0,1) or n!=128:
                self.header_errors+=1; del self.buffer[0]; continue
            if len(self.buffer)<272: break
            if crc16(self.buffer[4:270])!=struct.unpack_from('<H',self.buffer,270)[0]:
                self.crc_errors+=1;del self.buffer[0];continue
            result.append(AudioFrame(p,s,i,struct.unpack_from('<128h',self.buffer,14)))
            del self.buffer[:272]
        return result

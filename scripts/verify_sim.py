"""Check ModelSim PASS markers and decode UART against exported PCM."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'host'))
from protocol import FrameParser

tests = ['tb_dual_audio', 'tb_dual_recording', 'tb_usb_recorder',
         'tb_usb_recording_song', 'tb_usb_recorder_long']
for test in tests:
    log = (root / 'reports/dual_audio' / (test + '.log')).read_text()
    if ('PASS ' + test not in log or '** Error:' in log or '** Fatal:' in log):
        raise SystemExit('FAIL ' + test)
parser = FrameParser()
frames = parser.feed(bytes(int(x, 16) for x in
    (root / 'dual_audio/serial_dual.hex').read_text().split()))
expected = [int(x) for x in (root / 'dual_audio/pcm_dual.txt').read_text().split()]
actual = [x for frame in frames for x in frame.samples]
valid = (len(frames) >= 3 and parser.crc_errors == 0 and parser.header_errors == 0
    and all(f.profile == 1 and f.seq == i and f.first_sample == i * 128
            for i, f in enumerate(frames))
    and actual == expected[:len(actual)] and any(actual))
if not valid:
    raise SystemExit('FAIL UART/PCM comparison')
print(f'PASS: {len(tests)} simulations; {len(actual)} UART samples match PCM; CRC errors=0')

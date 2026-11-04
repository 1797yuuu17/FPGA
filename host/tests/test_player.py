import sys,unittest
from unittest.mock import patch,Mock
from pathlib import Path
r=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(r/'usb_audio/python_deps'),str(r/'host')]
from player import Player, preferred_output
import numpy as np
class PlayerTests(unittest.TestCase):
    def test_live_volume_default_full_and_mute(self):
        p=Player('COM_TEST',460800);p.output_rate=48000
        p.buffer.render=Mock(side_effect=lambda frames,rate:np.full(frames,.5,np.float32))
        np.testing.assert_allclose(p.render_audio(64),.1)
        p.set_volume(100)
        out=p.render_audio(1200)
        self.assertGreater(out[0],.1);self.assertLess(out[0],.101)
        self.assertTrue(np.all(np.diff(out)>=0))
        np.testing.assert_allclose(out[-100:],.5)
        p.set_volume(0);out=p.render_audio(1200)
        self.assertTrue(np.all(np.diff(out)<=0));np.testing.assert_allclose(out[-100:],0)
    def test_volume_limits(self):
        p=Player('COM_TEST',460800)
        p.set_volume(-50);self.assertEqual(p.volume,0)
        p.set_volume(150);self.assertEqual(p.volume,1)
        with self.assertRaises(ValueError):p.set_volume(float('nan'))
    def test_gui_prefers_tested_local_wasapi_route(self):
        devices=[dict(name='Realtek Audio',hostapi=0,max_output_channels=2),dict(name='Steam Streaming',hostapi=1,max_output_channels=2),dict(name='Realtek Audio',hostapi=1,max_output_channels=2)]
        self.assertEqual(preferred_output(devices,[dict(name='MME'),dict(name='Windows WASAPI')]),2)
        self.assertIsNone(preferred_output([],[]))
    def test_output_device_failure_releases_serial(self):
        handle=Mock()
        with patch('player.serial.Serial',return_value=handle),patch('player.sd.query_devices',side_effect=RuntimeError('device unplugged')):
            p=Player('COM_TEST',460800)
            with self.assertRaisesRegex(RuntimeError,'device unplugged'):p.start()
            handle.close.assert_called_once()
if __name__=='__main__':unittest.main()

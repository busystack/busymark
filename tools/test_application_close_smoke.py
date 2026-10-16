import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from application_close_smoke import accepted, run_case


class NaturalExitAcceptanceTest(unittest.TestCase):
    def run_inferior(self, suffix, timeout=5, plain=False):
        with tempfile.TemporaryDirectory(prefix="bm-close-unit-") as tmp:
            root = Path(tmp)
            source = (
                "import json,pathlib,sys,os,signal,time,resource,ctypes;"
                "resource.setrlimit(resource.RLIMIT_CORE,(0,0));"
                # Limit this deliberately crashing test inferior's core capture;
                # piped system crash handlers may ignore RLIMIT_CORE alone.
                "ctypes.CDLL(None).prctl(4,0,0,0,0);"
                "report=pathlib.Path(sys.argv[1]);"
                "support=report.parent/'support';support.mkdir();"
                "(support/'recovery.json').write_text(json.dumps({'cleanShutdown':True}));"
                "report.write_text(json.dumps({'phase':'close-requested',"
                "'applicationSupport':str(support)}));" + suffix
            )
            if plain:
                source = "import sys;" + suffix
            return run_case([sys.executable, "-c", source], root / "case", root / "profile", "plain", timeout, plain=plain)

    def test_natural_zero_exit_is_accepted(self):
        self.assertTrue(accepted(self.run_inferior("sys.exit(0)")))

    def test_zero_exit_without_an_owned_window_close_is_rejected(self):
        with patch('application_close_smoke.Desktop') as desktop:
            desktop.return_value.window.return_value = None
            record = self.run_inferior("sys.exit(0)", plain=True)
        self.assertEqual(record['exitCode'], 0)
        self.assertFalse(accepted(record))
        self.assertIn('owned-window close', record['error'])

    def test_fatal_signal_is_rejected_despite_success_checkpoint(self):
        for name in ["SIGABRT", "SIGSEGV"]:
            with self.subTest(signal=name):
                record = self.run_inferior(f"os.kill(os.getpid(),signal.{name})")
                self.assertLess(record["exitCode"], 0)
                self.assertFalse(accepted(record))

    def test_hang_is_rejected_and_cleanup_is_explicit(self):
        record = self.run_inferior("time.sleep(30)", timeout=.3)
        self.assertIsNone(record["exitCode"])
        self.assertIn("deadline", record["error"])
        self.assertTrue(record["cleanupRequired"])
        self.assertFalse(accepted(record))


if __name__ == "__main__":
    unittest.main()

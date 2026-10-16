import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from application_close_smoke import ObservationIncomplete, accepted, process_children, run_case, signal_owned


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
            return run_case([sys.executable, "-c", source], root / "case", root / "profile", "plain", timeout, plain=plain, child_grace=.15, term_grace=.15, kill_grace=2)

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

    def test_unavailable_child_enumeration_is_incomplete_not_empty(self):
        with patch('application_close_smoke.process_children', side_effect=ObservationIncomplete('children mechanism inaccessible')):
            record = self.run_inferior('sys.exit(0)')
        self.assertTrue(record['verificationIncomplete'])
        self.assertTrue(record['launchSkipped'])
        self.assertFalse(accepted(record))

    def test_missing_proc_mechanism_is_not_a_process_exit_race(self):
        with patch('application_close_smoke.process_state', return_value={'pid': os.getpid(), 'status': 'gone'}):
            record = self.run_inferior('sys.exit(0)')
        self.assertTrue(record['verificationIncomplete'])
        self.assertTrue(record['launchSkipped'])

    def test_already_exited_child_is_an_ordinary_observation_race(self):
        import subprocess
        child = subprocess.Popen([sys.executable, '-c', 'pass'])
        child.wait()
        self.assertEqual(process_children(child.pid), [])

    def test_failed_enumeration_after_launch_preserves_incomplete_failure(self):
        def inaccessible(pid, expected=None):
            if pid != os.getpid():
                raise ObservationIncomplete('live child task inaccessible')
            return process_children(pid, expected)
        with patch('application_close_smoke.process_children', side_effect=inaccessible):
            record = self.run_inferior('time.sleep(30)')
        self.assertTrue(record['verificationIncomplete'])
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(all(r['terminationVerified'] for r in record['cleanupOutcomes']))

    def orphan(self, ignores_term):
        return self.run_inferior("""
child = os.fork()
if child == 0:
    if IGNORE_TERM:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
    (report.parent / 'child-ready').write_text(str(os.getpid()))
    time.sleep(30)
    os._exit(0)
while not (report.parent / 'child-ready').exists():
    time.sleep(.001)
os._exit(0)
""".replace('IGNORE_TERM', repr(ignores_term)))

    def test_parent_exits_before_child_cleanup_waits_for_child(self):
        record = self.orphan(False)
        self.assertEqual(record['exitCode'], 0)
        self.assertTrue(record['survivingChildren'])
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(all(r['terminationVerified'] for r in record['cleanupOutcomes']))
        self.assertTrue(any(r.get('term') == 'sent' and 'kill' not in r for r in record['cleanupOutcomes']))

    def test_child_ignoring_term_is_killed_and_failure_is_preserved(self):
        record = self.orphan(True)
        self.assertEqual(record['exitCode'], 0)
        self.assertTrue(record['survivingChildren'])
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(any(r.get('term') == 'sent' and r.get('kill') == 'sent' and r['terminationVerified'] for r in record['cleanupOutcomes']))

    def test_cohort_stops_when_survivor_verification_is_unresolved(self):
        import application_close_smoke
        with tempfile.TemporaryDirectory(prefix='bm-close-stop-') as tmp:
            output = str(Path(tmp) / 'evidence')
            record = {'exitCode': 0, 'unresolvedSurvivors': [{'pid': 123, 'status': 'unavailable'}]}
            with patch.object(sys, 'argv', ['close', '--output', output, '--cycles', '2', '--scenarios', 'plain', '--', 'unused']), patch.object(application_close_smoke, 'run_case', return_value=record) as run:
                self.assertEqual(application_close_smoke.main(), 1)
                self.assertEqual(run.call_count, 1)
            self.assertEqual(json.loads((Path(output) / 'summary.json').read_text())['failures'], 1)

    def test_cleanup_refuses_a_mismatched_process_identity(self):
        self.assertEqual(signal_owned(os.getpid(), 'not-this-process-start', 9), 'reused')

    def test_hang_is_rejected_and_cleanup_is_explicit(self):
        record = self.run_inferior("time.sleep(30)", timeout=.3)
        self.assertIsNone(record["exitCode"])
        self.assertIn("deadline", record["error"])
        self.assertTrue(record["cleanupRequired"])
        self.assertFalse(accepted(record))


if __name__ == "__main__":
    unittest.main()

"""Real fixture retirement controls; all processes and files are disposable."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).parent))
import run_owned_fixture as fixture
from owned_processes import ObservationIncomplete, identity, process_state, signal_owned


class OwnedFixtureTest(unittest.TestCase):
    blocked = False

    def setUp(self):
        self.assertFalse(self.blocked, 'Previous fixture retirement is unresolved')
        temp = tempfile.TemporaryDirectory(prefix='bm-owned-fixture-')
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)

    def launch(self, source):
        report = self.root / 'result.json'
        command = [sys.executable, str(Path(fixture.__file__)), '--report', str(report),
                   '--duration', '5', '--', sys.executable, '-c', source]
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True)
        stamp = identity(process.pid)

        def retire():
            if process.poll() is None:
                signal_owned(process.pid, stamp, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    type(self).blocked = True
                    raise AssertionError('Owned supervisor cleanup remains unresolved')
            for stream in (process.stdin, process.stdout, process.stderr):
                stream.close()
        self.addCleanup(retire)
        return process, report

    def finished(self, process, report):
        process.wait(timeout=10)
        output, errors = process.communicate()
        self.assertTrue(report.is_file(), errors)
        record = json.loads(report.read_text())
        self.assertFalse(record.get('unresolvedSurvivors'), record)
        self.assertFalse(record.get('verificationIncomplete'), record)
        return record, output

    def test_natural_exit_is_verified_and_preserves_output(self):
        process, report = self.launch("print('production fixture result')")
        record, output = self.finished(process, report)
        self.assertEqual(process.returncode, 0)
        self.assertTrue(record['ok'], record)
        self.assertIn('production fixture result', output)
        self.assertFalse(record['cleanupRequired'])

    def test_nonzero_exit_stays_failed_after_complete_cleanup(self):
        process, report = self.launch('raise SystemExit(7)')
        record, _ = self.finished(process, report)
        self.assertEqual(record['exitCode'], 7)
        self.assertFalse(record['ok'])
        self.assertNotEqual(process.returncode, 0)

    def orphan(self, ignore_term):
        # Child readiness is a pipe barrier, after installing its handler.
        # It keeps inherited stdout open after the parent naturally exits.
        child = ("import os,signal; "
                 + ('signal.signal(signal.SIGTERM, signal.SIG_IGN); ' if ignore_term else '')
                 + "os.write(int(os.environ['READY_FD']), b'R'); "
                   "signal.pause()")
        return ("import os,subprocess,sys; "
                "r,w=os.pipe(); "
                f"subprocess.Popen([sys.executable,'-c',{child!r}], "
                "env={**os.environ,'READY_FD':str(w)},pass_fds=[w],start_new_session=True); "
                "os.close(w); assert os.read(r,1)==b'R'; os.close(r)")

    def test_parent_exit_does_not_hide_child_or_held_output_pipe(self):
        process, report = self.launch(self.orphan(False))
        record, _ = self.finished(process, report)
        self.assertEqual(record['exitCode'], 0)
        self.assertFalse(record['ok'])
        self.assertIn('surviving descendants', record['error'])
        self.assertTrue(record['cleanupRequired'])
        self.assertTrue(all(r['terminationVerified'] for r in record['cleanupOutcomes']))

    def test_sigterm_resistant_orphan_is_killed_and_failure_is_retained(self):
        process, report = self.launch(self.orphan(True))
        record, _ = self.finished(process, report)
        self.assertFalse(record['ok'])
        self.assertTrue(any(r.get('kill') == 'sent' for r in record['cleanupOutcomes']))
        self.assertTrue(all(r['terminationVerified'] for r in record['cleanupOutcomes']))

    def test_eof_retires_owned_runtime_without_reading_pid_files(self):
        ready = self.root / 'ready'
        source = ("import pathlib,signal; "
                  f"pathlib.Path({str(ready)!r}).write_text('ready'); signal.pause()")
        process, report = self.launch(source)
        # Wait on explicit runtime readiness, not a fixed shutdown delay.
        import time
        deadline = time.monotonic() + 5
        while not ready.exists() and time.monotonic() < deadline:
            time.sleep(.01)
        self.assertTrue(ready.exists())
        (self.root / 'process.pid').write_text(str(os.getpid()))
        observer_birth = identity(os.getpid())
        process.stdin.close()
        process.wait(timeout=10)
        record = json.loads(report.read_text())
        self.assertFalse(record['ok'])
        self.assertTrue(record['cancelled'])
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertNotIn(str(os.getpid()), record['observedIdentities'])
        self.assertEqual(process_state(os.getpid(), observer_birth)['status'], 'running')

    def test_unavailable_observation_prevents_launch_and_records_failure(self):
        report = self.root / 'unavailable.json'
        with patch.object(fixture, 'ChildTracker', side_effect=ObservationIncomplete('inaccessible proc')), \
             patch.object(fixture.subprocess, 'Popen') as launch:
            record = fixture.run(['/bin/true'], report)
        launch.assert_not_called()
        self.assertFalse(record['ok'])
        self.assertIn('inaccessible proc', record['error'])
        self.assertEqual(record['verificationIncomplete'], ['inaccessible proc'])
        self.assertEqual(record, json.loads(report.read_text()))

    def test_launch_failure_is_recorded_without_owning_an_absent_process(self):
        report = self.root / 'absent.json'
        record = fixture.run([str(self.root / 'absent')], report)
        self.assertFalse(record['ok'])
        self.assertIn('FileNotFoundError', record['error'])
        self.assertNotIn('pid', record)
        self.assertFalse(record['unresolvedSurvivors'])

    def test_failed_observation_stays_failed_after_verified_cleanup(self):
        report = self.root / 'lost-observation.json'
        tracker = Mock()
        tracker.seen, tracker.admitted_by = {}, {}
        tracker.errors = ['descendant observation unavailable']
        tracker.outstanding.side_effect = [ObservationIncomplete('lost live observation'), []]
        process = Mock(pid=12345)
        process.poll.return_value = process.wait.return_value = 0
        with patch.object(fixture, 'ChildTracker', return_value=tracker), \
             patch.object(fixture.subprocess, 'Popen', return_value=process), \
             patch.object(fixture, 'identity', return_value='owned'), \
             patch.object(fixture, 'cleanup_owned', return_value=([], [])) as cleanup:
            record = fixture.run(['/owned/fixture'], report)
        cleanup.assert_called_once_with(tracker, 1, 2)
        tracker.close.assert_called_once()
        self.assertFalse(record['ok'])
        self.assertIn('lost live observation', record['error'])
        self.assertTrue(record['verificationIncomplete'])
        self.assertFalse(record['unresolvedSurvivors'])

    def test_existing_report_is_not_overwritten(self):
        report = self.root / 'previous.json'
        report.write_text('historical failure')
        with patch.object(fixture.subprocess, 'Popen') as launch:
            record = fixture.run(['/bin/true'], report)
        launch.assert_not_called()
        self.assertFalse(record['ok'])
        self.assertIn('reportingError', record)
        self.assertEqual(report.read_text(), 'historical failure')


if __name__ == '__main__':
    unittest.main()

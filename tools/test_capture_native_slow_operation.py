#!/usr/bin/env python3
"""Regression checks for the opt-in watchdog, using owned synthetic processes."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).parent))
import capture_native_slow_operation as watchdog
from application_close_smoke import ObservationIncomplete, cleanup_owned


class WatchdogCleanupTest(unittest.TestCase):
    def test_inaccessible_observation_is_a_recorded_failure_before_launch(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / 'result'
            with mock.patch.object(sys, 'argv', ['capture', '--output', str(output), '--', '/bin/true']), \
                    mock.patch.object(watchdog, 'ChildTracker', side_effect=ObservationIncomplete('inaccessible /proc')), \
                    mock.patch.object(watchdog.subprocess, 'Popen') as launch:
                self.assertEqual(watchdog.main(), 1)
            launch.assert_not_called()
            result = json.loads((output / 'result.json').read_text())
            self.assertFalse(result['ok'])
            self.assertIn('inaccessible /proc', result['error'])

    def test_changed_identity_is_never_signalled(self):
        import owned_processes as observer
        tracker = mock.Mock(seen={123: 'old'})
        tracker.outstanding.side_effect = [[{'pid': 123, 'status': 'running'}], [], [], []]
        with mock.patch.object(observer.os, 'pidfd_open', return_value=9, create=True), \
                mock.patch.object(observer.os, 'close'), \
                mock.patch.object(observer, 'process_state', return_value={'pid': 123, 'status': 'reused'}), \
                mock.patch.object(observer.signal, 'pidfd_send_signal', create=True) as send:
            outcomes, remaining = cleanup_owned(tracker, 0, 0)
        send.assert_not_called()
        self.assertFalse(remaining)
        self.assertEqual(outcomes[0]['term'], 'reused')
        self.assertTrue(outcomes[0]['terminationVerified'])

    def test_debugger_failure_is_not_converted_to_success_by_cleanup(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            debugger = root / 'gdb'
            debugger.write_text('#!/bin/sh\nexit 7\n')
            debugger.chmod(0o700)
            result = subprocess.run([
                sys.executable, str(Path(watchdog.__file__)), '--output', str(root / 'capture'),
                '--detach-until-slow', '--', '/bin/true',
            ], env={**os.environ, 'PATH': str(root)}, capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            record = json.loads((root / 'capture/result.json').read_text())
            self.assertFalse(record['ok'])
            self.assertEqual(record['debuggerExitCode'], 7)
            self.assertFalse(record['unresolvedSurvivors'])
            self.assertFalse(record['verificationIncomplete'])

    def test_orphan_ignoring_sigterm_is_verified_in_attached_and_detached_modes(self):
        for detached in [False, True]:
            with self.subTest(detached=detached), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                source = root / 'orphan.c'
                source.write_text(r'''
#include <signal.h>
#include <unistd.h>
int main(void) {
  int ready[2]; if (pipe(ready)) return 2;
  pid_t child = fork(); if (child < 0) return 3;
  if (!child) {
    close(ready[0]); signal(SIGTERM, SIG_IGN);
    if (write(ready[1], "r", 1) != 1) return 4;
    close(ready[1]); for (;;) pause();
  }
  close(ready[1]); char value;
  if (read(ready[0], &value, 1) != 1) return 5;
  close(ready[0]); return 0;
}
''')
                binary = root / 'orphan'
                subprocess.run(['cc', '-g', '-O0', str(source), '-o', str(binary)], check=True)
                command = [sys.executable, str(Path(watchdog.__file__)), '--output', str(root / 'capture'),
                           '--duration', '2', '--', str(binary)]
                if detached:
                    command.insert(command.index('--'), '--detach-until-slow')
                result = subprocess.run(command, capture_output=True, text=True, timeout=25)
                record = json.loads((root / 'capture/result.json').read_text())
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertFalse(record['ok'])
                self.assertTrue(record['exited'], record)
                self.assertIn('surviving owned descendants', record['error'])
                self.assertFalse(record['verificationIncomplete'], record)
                self.assertFalse(record['unresolvedSurvivors'], record)
                killed = [x for x in record['cleanupOutcomes'] if x.get('kill') == 'sent']
                self.assertEqual(len(killed), 1, record)
                self.assertTrue(killed[0]['terminationVerified'], record)


class DetachedCaptureTest(unittest.TestCase):
    def run_probe(self, delay):
        with tempfile.TemporaryDirectory(prefix='busymark-watchdog-test-') as temp:
            root = Path(temp)
            source = root / 'probe.c'
            source.write_text(r'''
#include <stdio.h>
#include <time.h>
#include <unistd.h>
static long stamp(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1000000L + t.tv_nsec / 1000;
}
int main(int argc, char **argv) {
  fprintf(stderr, "busymark-native synthetic begin time_us=%ld\n", stamp());
  usleep(DELAY);
  fprintf(stderr, "busymark-native synthetic end time_us=%ld\n", stamp());
  sleep(10);
}
''')
            binary = root / 'probe'
            subprocess.run(['cc', '-g', '-O0', f'-DDELAY={delay}',
                            str(source), '-o', str(binary)], check=True)
            output = root / 'capture'
            template = root / 'template'
            template.mkdir()
            (template / 'fixture.txt').write_text('disposable fixture')
            result = subprocess.run([
                sys.executable,
                str(Path(__file__).with_name('capture_native_slow_operation.py')),
                '--output', str(output), '--threshold-ms', '150',
                '--duration', '1', '--operation', 'synthetic',
                '--profile-template', str(template),
                '--detach-until-slow', '--', str(binary),
            ], capture_output=True, text=True, timeout=25)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            summary = json.loads((output / 'result.json').read_text())
            self.assertTrue(summary['detachedUntilSlow'])
            self.assertTrue((output / 'detached.json').exists())
            self.assertEqual((template / 'fixture.txt').read_text(),
                             'disposable fixture')
            self.assertEqual((output / 'profile/fixture.txt').read_text(),
                             'disposable fixture')
            for pid in json.loads((output / 'detached.json').read_text())['pids']:
                stat = Path(f'/proc/{pid}/stat')
                if stat.exists():
                    self.assertEqual(stat.read_text().rsplit(') ', 1)[1].split()[0], 'Z')
            return summary, (output / 'gdb-mi.log').read_text(), [
                json.loads(p.read_text())
                for p in output.glob('capture-*/active-at-stop.json')
            ]

    def test_attach_observes_operation_already_blocked(self):
        summary, log, captures = self.run_probe(3000000)
        self.assertEqual(summary['captures'], 1, log)
        self.assertEqual(len(captures), 1, log)
        self.assertIn('synthetic', captures[0]['operations'])
        self.assertIn('nanosleep', log)

    def test_completed_operation_does_not_trigger_attach(self):
        summary, log, captures = self.run_probe(1000)
        self.assertEqual(summary['captures'], 0, log)
        self.assertEqual(captures, [])

    def test_profile_cannot_recursively_copy_its_capture_output(self):
        with tempfile.TemporaryDirectory(prefix='busymark-watchdog-template-') as temp:
            result = subprocess.run([
                sys.executable,
                str(Path(__file__).with_name('capture_native_slow_operation.py')),
                '--profile-template', temp, '--output', str(Path(temp) / 'capture'),
                '--', '/bin/true',
            ], capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 2)
            self.assertIn('must not be inside', result.stderr)
            self.assertFalse((Path(temp) / 'capture').exists())


if __name__ == '__main__':
    unittest.main()

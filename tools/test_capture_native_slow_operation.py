#!/usr/bin/env python3
"""Regression checks for the opt-in watchdog, using owned synthetic processes."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


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

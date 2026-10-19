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
from urllib.parse import unquote, urljoin, urlparse

sys.path.insert(0, str(Path(__file__).parent))
import capture_native_slow_operation as watchdog
from application_close_smoke import ObservationIncomplete, cleanup_owned


class SpanCorrelationTest(unittest.TestCase):
    def test_actual_dart_producer_correlates_async_sync_and_worker_spans(self):
        project = Path(__file__).resolve().parent.parent
        config_path = project / '.dart_tool/package_config.json'
        config = json.loads(config_path.read_text())
        flutter = next(p for p in config['packages'] if p['name'] == 'flutter')
        package = Path(unquote(urlparse(urljoin(config_path.as_uri(), flutter['rootUri'])).path))
        dart = package.parent.parent / 'bin/cache/dart-sdk/bin/dart'
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'trace.dart'
            source.write_text("import 'dart:async';\nimport 'dart:isolate';\nimport '" +
                              (project / 'lib/src/core/performance_trace.dart').as_uri() + "';\n" + r'''
Future<void> main() async {
  final first = Completer<void>(), second = Completer<void>();
  final a = PerformanceTrace.async('shared', () => first.future);
  final b = PerformanceTrace.async('shared', () => second.future);
  second.complete(); await b; first.complete(); await a;
  PerformanceTrace.sync('shared', () => PerformanceTrace.sync('shared', () {}));
  await Isolate.run(() => PerformanceTrace.sync('shared', () {}));
}
''')
            executable = Path(temp) / 'trace'
            compilation = subprocess.run([str(dart), 'compile', 'exe',
                '--packages=' + str(config_path), '-DBUSYMARK_PERFORMANCE_TRACE=true',
                str(source), '-o', str(executable)], capture_output=True, text=True, timeout=60)
            self.assertEqual(compilation.returncode, 0, compilation.stdout + compilation.stderr)
            for mode, command in [
                ('JIT', [str(dart), '--packages=' + str(config_path),
                         '-DBUSYMARK_PERFORMANCE_TRACE=true', str(source)]),
                ('AOT', [str(executable)]),
            ]:
                with self.subTest(mode=mode):
                    result = subprocess.run(command, capture_output=True, text=True, timeout=30)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    spans, sizes, invocations = watchdog._OperationSpans(), [], set()
                    for line in result.stderr.splitlines():
                        spans.observe(line, 0)
                        sizes.append(len(spans.active))
                        invocations.update(spans.active)
                    self.assertEqual(sizes, [1, 2, 1, 0, 1, 2, 1, 0, 1, 0], result.stderr)
                    self.assertEqual(len(invocations), 5)

    def event(self, spans, phase, span, *, pid=10, origin='busymark-dart', name='shared'):
        spans.observe(f'{origin} {name} {phase} time_us=123 pid={pid} span={span}', 124)

    def test_nested_and_non_lifo_completion_preserve_other_invocations(self):
        for finished, remaining in [(1, 2), (2, 1)]:
            with self.subTest(finished=finished):
                spans = watchdog._OperationSpans()
                self.event(spans, 'begin', 1)
                self.event(spans, 'begin', 2)
                self.event(spans, 'end', finished)
                self.assertEqual(list(spans.active), [f'busymark-dart/10/{remaining}'])
                self.event(spans, 'end', remaining)
                self.assertFalse(spans.active)

    def test_process_and_producer_ids_are_independent(self):
        spans = watchdog._OperationSpans()
        self.event(spans, 'begin', 1)
        self.event(spans, 'begin', 1, pid=20)
        self.event(spans, 'begin', 1, origin='busymark-native')
        self.event(spans, 'end', 1)
        self.assertEqual(len(spans.active), 2)

    def test_signed_vm_task_ids_remain_distinct(self):
        spans = watchdog._OperationSpans()
        self.event(spans, 'begin', -1)
        self.event(spans, 'begin', 1)
        self.event(spans, 'end', -1)
        self.assertEqual(list(spans.active), ['busymark-dart/10/1'])

    def test_restoration_names_can_contain_path_spaces(self):
        spans = watchdog._OperationSpans()
        name = 'restore-buffer-file:/workspace/my notes.md'
        self.event(spans, 'begin', 1, name=name)
        self.assertEqual(next(iter(spans.active.values()))['name'], name)
        self.event(spans, 'end', 1, name=name)
        self.assertFalse(spans.active)

    def test_legacy_single_spans_remain_readable(self):
        for prefix in ['busymark-native synthetic {phase} time_us=123',
                       'bm-native synthetic {phase} 123']:
            spans = watchdog._OperationSpans()
            for _ in range(2):
                spans.observe(prefix.format(phase='begin'), 124)
                self.assertIn('synthetic', spans.active)
                spans.observe(prefix.format(phase='end'), 125)
                self.assertFalse(spans.active)

    def test_ambiguous_legacy_overlap_does_not_erase_pending_work(self):
        spans = watchdog._OperationSpans()
        line = 'busymark-native synthetic begin time_us=123'
        spans.observe(line, 124)
        with self.assertRaisesRegex(ObservationIncomplete, 'Ambiguous overlapping legacy'):
            spans.observe(line, 125)
        self.assertEqual(len(spans.active), 1)

    def test_invalid_or_changed_identity_fails(self):
        spans = watchdog._OperationSpans()
        with self.assertRaisesRegex(ObservationIncomplete, 'Malformed'):
            spans.observe('busymark-dart shared begin time_us=123 pid=10 span=bad', 124)
        with self.assertRaisesRegex(ObservationIncomplete, 'Malformed'):
            spans.observe('busymark-dart shared begin time_us=123 span=1', 124)
        with self.assertRaisesRegex(ObservationIncomplete, 'without admitted'):
            self.event(spans, 'end', 1)
        self.event(spans, 'begin', 1)
        with self.assertRaisesRegex(ObservationIncomplete, 'Duplicate'):
            self.event(spans, 'begin', 1)
        with self.assertRaisesRegex(ObservationIncomplete, 'changed operation'):
            self.event(spans, 'end', 1, name='different')
        self.assertEqual(len(spans.active), 1)


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


class OverlapCaptureTest(unittest.TestCase):
    def test_real_native_spans_survive_either_completion_order(self):
        project = Path(__file__).resolve().parent.parent
        for first_finishes in [False, True]:
            with self.subTest(first_finishes=first_finishes), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                source = root / 'overlap.cc'
                source.write_text(r'''
#include "linux/runner/performance_trace.h"
#include <memory>
#include <unistd.h>
int main(int argc, char**) {
  auto first = std::make_unique<BusyMarkPerformanceSpan>("synthetic");
  auto second = std::make_unique<BusyMarkPerformanceSpan>("synthetic");
  if (argc > 1) first.reset(); else second.reset();
  // One admitted operation remains pending; no timer determines the overlap.
  for (;;) pause();
}
''')
                binary = root / 'overlap'
                flags = subprocess.check_output(['pkg-config', '--cflags', '--libs', 'glib-2.0'], text=True).split()
                subprocess.run(['c++', '-std=c++17', '-g', '-O0', '-I', str(project),
                                str(source), '-o', str(binary), *flags], check=True)
                command = [sys.executable, str(Path(watchdog.__file__)), '--output', str(root / 'capture'),
                           '--threshold-ms', '80', '--duration', '1', '--operation', 'synthetic',
                           '--detach-until-slow', '--', str(binary)]
                if first_finishes:
                    command.append('first')
                result = subprocess.run(command, capture_output=True, text=True, timeout=25)
                record = json.loads((root / 'capture/result.json').read_text())
                self.assertFalse(record['verificationIncomplete'], record)
                self.assertFalse(record['unresolvedSurvivors'], record)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(record['captures'], 1, record)


if __name__ == '__main__':
    unittest.main()

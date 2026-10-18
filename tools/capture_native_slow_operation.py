#!/usr/bin/env python3
"""Capture slow native or awaited Dart operations with an external GDB/MI watchdog.

Diagnostic runs only: debugger stops and symbol loading perturb timing. Use a
separate uninstrumented release cohort for performance claims. The executable
must emit BusyMark native, visualization or Dart begin/end events. This tool creates
an isolated application profile and preserves the desktop/driver environment.
"""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import threading
import sys

from application_close_smoke import ChildTracker, ObservationIncomplete, cleanup_owned, identity, process_state
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--threshold-ms', type=float, default=500)
    parser.add_argument('--duration', type=float, default=20)
    parser.add_argument('--expect-exit', action='store_true')
    parser.add_argument('--profile-template', type=Path,
                        help='copy a disposable fixture profile; leave its source unchanged')
    parser.add_argument(
        '--detach-until-slow', action='store_true',
        help='detach at native main and attach only after a slow operation; '
             'GDB remains the process ancestor, without changing ptrace policy')
    parser.add_argument('--operation', action='append',
                        help='capture only this operation (repeatable; default: all)')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command
    if command[:1] == ['--']:
        command = command[1:]
    if not command:
        parser.error('an executable and optional arguments are required')
    output = args.output.expanduser().resolve()
    template = args.profile_template.expanduser().resolve() if args.profile_template else None
    if template is not None and output.is_relative_to(template):
        parser.error('the capture output must not be inside its profile template')
    output.mkdir(parents=True, exist_ok=False)
    record = {'expectedExit': args.expect_exit, 'detachedUntilSlow': args.detach_until_slow,
              'captures': 0, 'exited': False, 'command': command}
    resources = {}
    tracker = None
    try:
        tracker = ChildTracker()
        _capture(args, command, output, template, tracker, resources, record)
        debugger = resources.get('debugger')
        if debugger is not None and debugger.poll() is not None and not record.get('exited'):
            raise RuntimeError('Debugger exited before verified capture completion')
        if record.get('exitCode') not in (None, 0):
            raise RuntimeError('Application exited with nonzero status')
        if args.expect_exit and record.get('exitCode') != 0:
            raise RuntimeError('Successful natural application exit was not verified')
        record['terminationReason'] = 'observed-exit' if record.get('exited') else 'capture-duration-budget'
    except BaseException as error:
        record['error'] = repr(error)
    finally:
        resources['retiring'] = True
        debugger = resources.get('debugger')
        def cleanup_error(stage, error):
            record.setdefault('cleanupErrors', []).append({'stage': stage, 'error': repr(error)})
        if debugger is not None and debugger.poll() is None:
            try:
                send = resources.get('send')
                if send is not None:
                    if resources.get('attached') and not resources.get('exited'):
                        send('-exec-interrupt --all')
                    send('-gdb-exit')
                    deadline = time.monotonic() + 10
                    while debugger.poll() is None and time.monotonic() < deadline:
                        tracker.scan()
                        time.sleep(.025)
                    if debugger.poll() is None:
                        raise RuntimeError('Debugger did not retire on request')
            except BaseException as error:
                cleanup_error('debugger retirement', error)
        if tracker is not None:
            try:
                record['survivorsBeforeCleanup'] = tracker.outstanding()
                if record.get('exited') and any(x['pid'] != (debugger.pid if debugger else None)
                                                for x in record['survivorsBeforeCleanup']):
                    record.setdefault('error', 'Application exited with surviving owned descendants')
                record['observedIdentities'] = dict(tracker.seen)
                record['cleanupOutcomes'], record['unresolvedSurvivors'] = cleanup_owned(tracker, .5, 3)
            except BaseException as error:
                cleanup_error('owned descendants', error)
                record['unresolvedSurvivors'] = [{'status': 'unavailable', 'error': repr(error)}]
            try:
                tracker.close()
            except BaseException as error:
                cleanup_error('observer close', error)
            record['verificationIncomplete'] = tracker.errors
        if debugger is not None and debugger.poll() is not None:
            debugger.wait()
            record['debuggerExitCode'] = debugger.returncode
        reader = resources.get('reader')
        if reader is not None:
            reader.join(timeout=2)
            if reader.is_alive():
                cleanup_error('debugger reader', RuntimeError('Reader did not retire'))
        for stream in [debugger.stdin if debugger else None, debugger.stdout if debugger else None, resources.get('log')]:
            if stream is not None:
                try:
                    stream.close()
                except BaseException as error:
                    cleanup_error('stream close', error)
        record['ok'] = not any(record.get(k) for k in ['error', 'fatalSignal', 'debuggerErrors', 'cleanupErrors', 'verificationIncomplete', 'unresolvedSurvivors'])
        try:
            (output / 'result.json').write_text(json.dumps(record, indent=2))
        except OSError as error:
            record.update(ok=False, reportingError=repr(error))
            print('Native capture result publication failed: ' + repr(error), file=sys.stderr)
    print(json.dumps(record), flush=True)
    return 0 if record['ok'] else 1


def _capture(args, command, output, template, tracker, resources, record):
    environment = os.environ.copy()
    if template is not None:
        shutil.copytree(template, output / 'profile')
    for key, directory in {
        'HOME': 'home', 'XDG_CONFIG_HOME': 'config', 'XDG_DATA_HOME': 'data',
        'XDG_CACHE_HOME': 'cache', 'XDG_STATE_HOME': 'state', 'TMPDIR': 'tmp',
    }.items():
        path = output / 'profile' / directory
        path.mkdir(parents=True, exist_ok=True)
        environment[key] = str(path)
    environment['BUSYMARK_NATIVE_TRACE'] = '1'
    environment['BUSYMARK_VISUALIZATION_TRACE'] = '1'
    log = resources['log'] = (output / 'gdb-mi.log').open('x')
    debugger = subprocess.Popen(
        ['gdb', '-q', '--nx', '--interpreter=mi2', '--args', *command],
        env=environment, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, bufsize=1,
    )
    resources['debugger'] = debugger
    tracker.root = debugger.pid
    stamp = identity(debugger.pid)
    if stamp is None:
        raise ObservationIncomplete('Debugger identity unavailable after launch')
    tracker.seen[debugger.pid] = stamp
    lock = threading.Lock()
    active = {}
    captured = set()
    process_ids = set()
    inferior_result = {}
    stopped = threading.Event()
    exited = threading.Event()
    detached = threading.Event()
    debugger_attached = True
    resources["attached"] = True
    event = re.compile(
        r'(?:busymark-native|busymark-dart|visualization-init) (\S+) (begin|end) time_us=(\d+)'
    )
    # An external interposer can trace an unmodified archived executable.
    legacy_event = re.compile(r'bm-native (\S+) (begin|end) (\d+)')

    def send(value):
        debugger.stdin.write(value + '\n')
        debugger.stdin.flush()

    def read_lines():
        for line in debugger.stdout:
            log.write(f'{time.monotonic_ns()} {line}')
            log.flush()
            match = re.search(r'thread-group-started,.*pid="(\d+)"', line)
            with lock:
                if match:
                    process_ids.add(int(match[1]))
                match = event.search(line) or legacy_event.search(line)
                if match:
                    if match[2] == 'begin':
                        active[match[1]] = (int(match[3]), time.monotonic_ns() / 1000)
                    else:
                        active.pop(match[1], None)
            if '^error' in line:
                record.setdefault('debuggerErrors', []).append(line.strip())
            if 'reason=\"signal-received\"' in line and not resources.get('retiring'):
                if resources.get('requestedStop') and re.search(r'signal-name="SIG(?:INT|STOP)"', line):
                    record.setdefault('controlledStops', []).append(line.strip())
                else:
                    record['fatalSignal'] = line.strip()
            if '*stopped' in line:
                stopped.set()
            if '=thread-group-exited' in line:
                match = re.search(r'exit-code="([0-7]+)"', line)
                if match:
                    inferior_result['exitCode'] = int(match[1], 8)
                if match or not args.detach_until_slow:
                    exited.set()
            if line.startswith('900^done'):
                detached.set()

    def read():
        try:
            read_lines()
        except BaseException as error:
            record.setdefault('debuggerErrors', []).append('Reader failed: ' + repr(error))

    reader = threading.Thread(target=read, daemon=True)
    resources['reader'] = reader
    resources['send'] = send
    reader.start()
    send('-gdb-set pagination off')
    send('-gdb-set confirm off')
    send('-gdb-set mi-async on')
    send('-gdb-set disable-randomization off')
    send('-gdb-set debuginfod enabled off')
    if args.detach_until_slow:
        send('-break-insert -t main')
    send('-exec-run')
    def remember_descendants():
        tracker.scan()
        if tracker.errors:
            raise ObservationIncomplete('; '.join(tracker.errors))

    def identify(pid):
        expected = tracker.seen.get(pid)
        if expected is None:
            return None
        state = process_state(pid, expected)
        return expected if state['status'] == 'running' else None

    def wait_for(flag, seconds):
        deadline = time.monotonic() + seconds
        while not flag.is_set() and time.monotonic() < deadline:
            remember_descendants()
            if record.get('debuggerErrors') or debugger.poll() is not None:
                raise RuntimeError('Debugger failed while waiting for a stop/detach')
            flag.wait(.025)
        return flag.is_set()

    try:
        if args.detach_until_slow:
            if not wait_for(stopped, 20):
                raise RuntimeError('GDB did not stop at native main')
            remember_descendants()
            send('900-target-detach')
            if not wait_for(detached, 5):
                raise RuntimeError('GDB did not detach at native main')
            debugger_attached = False
            resources["attached"] = False
            (output / 'detached.json').write_text(json.dumps({
                'pids': sorted(process_ids),
                'monotonic_ns': time.monotonic_ns(),
                'ownership': 'GDB launched the inferior and remains its ancestor',
            }))
        deadline = time.monotonic() + args.duration
        while debugger.poll() is None and not exited.is_set() and time.monotonic() < deadline:
            remember_descendants()
            if record.get('debuggerErrors') or record.get('fatalSignal'):
                raise RuntimeError('Debugger/application failure during capture')
            if args.detach_until_slow:
                if process_ids and not any(identify(pid) is not None for pid in process_ids):
                    exited.set()
                    break
            with lock:
                slow = [(name, start) for name, (start, received) in active.items()
                        if (name, start) not in captured and
                        (args.operation is None or name in args.operation) and
                        time.monotonic_ns() / 1000 - start > args.threshold_ms * 1000 and
                        # GDB can deliver buffered inferior output late while
                        # loading libraries. Require a full observation interval
                        # as well, so that backlog cannot manufacture a stall.
                        time.monotonic_ns() / 1000 - received > args.threshold_ms * 1000]
                pids = set(process_ids)
            if slow:
                captured.update(slow)
                capture = output / f'capture-{len(captured)}'
                capture.mkdir()
                (capture / 'operations.json').write_text(json.dumps(slow))
                (capture / 'clock.json').write_text(json.dumps({
                    'monotonic_ns': time.monotonic_ns(),
                    'wall_ns': time.time_ns(),
                }))
                # Expand descendants from each inferior only. Never inspect or
                # signal unrelated desktop or WebKit processes by name.
                remember_descendants()
                pids = set(tracker.seen) - {debugger.pid}
                pending = list(pids)
                while pending:
                    current = pending.pop()
                    proc = Path('/proc') / str(current)
                    try:
                        for task in (proc / 'task').iterdir():
                            for field in ['status', 'wchan', 'syscall']:
                                try:
                                    (capture / f'{current}-{task.name}-{field}').write_text(
                                        (task / field).read_text())
                                except OSError as error:
                                    (capture / f'{current}-{task.name}-{field}.error').write_text(str(error))
                        (capture / f'{current}-maps').write_text((proc / 'maps').read_text())
                        (capture / f'{current}-stat').write_text((proc / 'stat').read_text())
                        (capture / f'{current}-cmdline').write_bytes((proc / 'cmdline').read_bytes())
                        (capture / f'{current}-exe').write_text(os.readlink(proc / 'exe'))
                    except OSError as error:
                        (capture / f'{current}.error').write_text(str(error))
                stopped.clear()
                resources['requestedStop'] = True
                if debugger_attached:
                    send('-exec-interrupt --all')
                else:
                    eligible = [pid for pid in process_ids if identify(pid) is not None]
                    if not eligible:
                        raise ObservationIncomplete('No still-matching owned inferior to attach')
                    send(f'-target-attach {min(eligible)}')
                if wait_for(stopped, 5):
                    resources['requestedStop'] = False
                    debugger_attached = True
                    resources["attached"] = True
                    with lock:
                        (capture / 'active-at-stop.json').write_text(json.dumps({
                            'monotonic_ns': time.monotonic_ns(),
                            'operations': active,
                        }))
                    send('-interpreter-exec console "thread apply all bt"')
                    if args.detach_until_slow:
                        detached.clear()
                        send('900-target-detach')
                        if not wait_for(detached, 5):
                            raise RuntimeError('GDB did not detach after capture')
                        debugger_attached = False
                        resources["attached"] = False
                    else:
                        send('-exec-continue')
                else:
                    raise RuntimeError('GDB did not report a capture stop')
            time.sleep(.025)
    finally:
        record.update(**inferior_result, captures=len(captured), exited=exited.is_set())
        resources['exited'] = exited.is_set()


if __name__ == '__main__':
    raise SystemExit(main())

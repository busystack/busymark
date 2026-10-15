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
import signal
import shutil
import subprocess
import threading
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
    log = (output / 'gdb-mi.log').open('w')
    debugger = subprocess.Popen(
        ['gdb', '-q', '--nx', '--interpreter=mi2', '--args', *command],
        env=environment, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, bufsize=1,
    )
    lock = threading.Lock()
    active = {}
    captured = set()
    process_ids = set()
    inferior_result = {}
    stopped = threading.Event()
    exited = threading.Event()
    detached = threading.Event()
    debugger_attached = True
    event = re.compile(
        r'(?:busymark-native|busymark-dart|visualization-init) (\S+) (begin|end) time_us=(\d+)'
    )
    # An external interposer can trace an unmodified archived executable.
    legacy_event = re.compile(r'bm-native (\S+) (begin|end) (\d+)')

    def send(value):
        debugger.stdin.write(value + '\n')
        debugger.stdin.flush()

    def read():
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

    reader = threading.Thread(target=read, daemon=True)
    reader.start()
    send('-gdb-set pagination off')
    send('-gdb-set confirm off')
    send('-gdb-set mi-async on')
    send('-gdb-set disable-randomization off')
    send('-gdb-set debuginfod enabled off')
    if args.detach_until_slow:
        send('-break-insert -t main')
    send('-exec-run')
    owned_identities = {}

    def identify(pid):
        try:
            proc = Path('/proc') / str(pid)
            fields = (proc / 'stat').read_text().rsplit(') ', 1)[1].split()
            return fields[19], os.readlink(proc / 'exe')
        except OSError:
            return None

    def remember_descendants():
        pending = list(process_ids)
        seen = set()
        while pending:
            pid = pending.pop()
            if pid in seen:
                continue
            seen.add(pid)
            identity = identify(pid)
            if identity is not None:
                owned_identities[pid] = identity
            try:
                for task in (Path('/proc') / str(pid) / 'task').iterdir():
                    pending.extend(map(int, (task / 'children').read_text().split()))
            except OSError:
                pass

    try:
        if args.detach_until_slow:
            if not stopped.wait(20):
                raise RuntimeError('GDB did not stop at native main')
            remember_descendants()
            send('900-target-detach')
            if not detached.wait(5):
                raise RuntimeError('GDB did not detach at native main')
            debugger_attached = False
            (output / 'detached.json').write_text(json.dumps({
                'pids': sorted(process_ids),
                'monotonic_ns': time.monotonic_ns(),
                'ownership': 'GDB launched the inferior and remains its ancestor',
            }))
        deadline = time.monotonic() + args.duration
        while debugger.poll() is None and not exited.is_set() and time.monotonic() < deadline:
            if args.detach_until_slow:
                remember_descendants()
                if not any(identify(pid) == identity
                           for pid, identity in owned_identities.items()
                           if pid in process_ids):
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
                pending = list(pids)
                while pending:
                    current = pending.pop()
                    proc = Path('/proc') / str(current)
                    try:
                        for task in (proc / 'task').iterdir():
                            children = (task / 'children').read_text()
                            for child in map(int, children.split()):
                                if child not in pids:
                                    pids.add(child)
                                    pending.append(child)
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
                if debugger_attached:
                    send('-exec-interrupt --all')
                else:
                    send(f'-target-attach {min(process_ids)}')
                if stopped.wait(5):
                    debugger_attached = True
                    with lock:
                        (capture / 'active-at-stop.json').write_text(json.dumps({
                            'monotonic_ns': time.monotonic_ns(),
                            'operations': active,
                        }))
                    send('-interpreter-exec console "thread apply all bt"')
                    if args.detach_until_slow:
                        detached.clear()
                        send('900-target-detach')
                        if not detached.wait(5):
                            raise RuntimeError('GDB did not detach after capture')
                        debugger_attached = False
                    else:
                        send('-exec-continue')
                else:
                    (capture / 'interrupt.error').write_text('GDB did not report a stop')
            time.sleep(.025)
    finally:
        if args.detach_until_slow:
            remember_descendants()
        if debugger.poll() is None:
            if not exited.is_set() and debugger_attached:
                stopped.clear()
                send('-exec-interrupt --all')
                stopped.wait(5)
                # GDB owns the inferior. Kill that inferior, then exit the debugger.
                send('-interpreter-exec console "kill"')
            send('-gdb-exit')
            try:
                debugger.wait(timeout=10)
            except subprocess.TimeoutExpired:
                debugger.terminate()
                debugger.wait(timeout=5)
        if args.detach_until_slow:
            # A detached inferior survives GDB exit. Signal only processes
            # discovered below the launched inferior, with matching identities.
            for sig in [signal.SIGTERM, signal.SIGKILL]:
                for pid, identity in owned_identities.items():
                    if identify(pid) == identity:
                        try:
                            os.kill(pid, sig)
                        except ProcessLookupError:
                            pass
                if sig == signal.SIGTERM:
                    time.sleep(.1)
        reader.join(timeout=2)
        log.close()
    result = {**inferior_result, 'captures': len(captured),
              'expectedExit': args.expect_exit, 'exited': exited.is_set(),
              'detachedUntilSlow': args.detach_until_slow}
    (output / 'result.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result), flush=True)
    if args.expect_exit and inferior_result.get('exitCode') != 0:
        raise SystemExit(1)


if __name__ == '__main__':
    main()

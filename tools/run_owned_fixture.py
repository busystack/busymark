#!/usr/bin/python3
"""Supervise one test fixture using the maintained Linux ownership contract.

stdin EOF or ``stop\n`` requests retirement; never accept a PID from the fixture.
The supervisor must have no unrelated children. No production application uses it.
"""
import argparse
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import time

from owned_processes import ChildTracker, ObservationIncomplete, cleanup_owned, identity


def run(command, report, duration=60, child_grace=1, term_grace=1, kill_grace=2):
    record = {'command': command}
    tracker = process = None
    stopping = False
    owns_report = False
    previous_handlers = {}

    def stop(*_):
        nonlocal stopping
        stopping = True

    try:
        # Refuse to replace evidence, including a previous failed attempt.
        with report.open('x'):
            pass
        owns_report = True
        for number in (signal.SIGTERM, signal.SIGINT):
            previous_handlers[number] = signal.signal(number, stop)
        tracker = ChildTracker()
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL)
        tracker.root = process.pid
        stamp = identity(process.pid)
        if stamp is None:
            raise ObservationIncomplete('Fixture identity unavailable after launch')
        tracker.seen[process.pid] = stamp
        record.update(pid=process.pid, identity=stamp)
        deadline = time.monotonic() + duration
        exited_at = None
        control = b''
        while True:
            outstanding = tracker.outstanding()
            if tracker.errors:
                raise ObservationIncomplete('; '.join(tracker.errors))
            code = process.poll()
            if code is not None:
                record['exitCode'] = code
                if exited_at is None:
                    exited_at = time.monotonic()
                if not outstanding:
                    break
                if time.monotonic() - exited_at >= child_grace:
                    raise RuntimeError('Fixture exited with surviving descendants')
            if stopping:
                record['cancelled'] = True
                break
            if time.monotonic() >= deadline:
                raise TimeoutError('Fixture execution deadline exceeded')
            if select.select([sys.stdin], [], [], .02)[0]:
                chunk = os.read(sys.stdin.fileno(), 256)
                control += chunk
                if not chunk or control == b'stop\n':
                    stopping = True
                elif len(control) >= 256 or b'\n' in control:
                    raise ValueError('Invalid fixture control request')
    except BaseException as error:
        record['error'] = repr(error)
        if isinstance(error, ObservationIncomplete):
            record.setdefault('verificationIncomplete', []).append(str(error))
    finally:
        if tracker is not None:
            try:
                record['survivorsBeforeCleanup'] = tracker.outstanding()
                record['cleanupRequired'] = bool(record['survivorsBeforeCleanup'])
                record['cleanupOutcomes'], record['unresolvedSurvivors'] = cleanup_owned(
                    tracker, term_grace, kill_grace)
                record['observedIdentities'] = dict(tracker.seen)
                record['admittedAncestry'] = dict(tracker.admitted_by)
            except BaseException as error:
                record.setdefault('cleanupErrors', []).append({'stage': 'owned descendants', 'error': repr(error)})
                record['unresolvedSurvivors'] = [{'status': 'unavailable'}]
            try:
                tracker.close()
            except BaseException as error:
                record.setdefault('cleanupErrors', []).append({'stage': 'observer close', 'error': repr(error)})
            record['verificationIncomplete'] = list(dict.fromkeys(
                record.get('verificationIncomplete', []) + tracker.errors))
        if process is not None and process.poll() is not None:
            record['exitCode'] = process.wait()
        for number, previous in previous_handlers.items():
            signal.signal(number, previous)
        record['ok'] = record.get('exitCode') == 0 and not any(record.get(key) for key in (
            'error', 'cancelled', 'cleanupRequired', 'cleanupErrors',
            'verificationIncomplete', 'unresolvedSurvivors'))
        try:
            if not owns_report:
                raise OSError('Fixture report was not acquired; refusing to overwrite it')
            report.write_text(json.dumps(record, indent=2) + '\n')
        except OSError as error:
            record.update(ok=False, reportingError=repr(error))
            print('Fixture result publication failed: ' + repr(error), file=sys.stderr)
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--duration', type=float, default=60)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command or args.duration <= 0:
        parser.error('A command and positive execution deadline are required')
    record = run(command, args.report, duration=args.duration)
    print('OWNED_FIXTURE ' + json.dumps(record), flush=True)
    return 0 if record['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())

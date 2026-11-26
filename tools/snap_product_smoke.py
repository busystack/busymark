#!/usr/bin/env python3
"""Observe installed strict Snap product smoke through its normal launcher."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time

from application_close_smoke import LoadedEngine
import owned_processes as owned


def file_identity(file_stat):
    return {'device': file_stat.st_dev, 'inode': file_stat.st_ino}


def verify_installation(record, runner, engine, instance, errors):
    # snap-confine maps an instance-specific mount to the base snap name.
    # /proc can report that namespace path even for a parallel instance.
    if record.get('executableIdentity') != file_identity(runner):
        errors.append('Running executable is not the installed instance payload')
    mapped = record.get('loadedEngine', {})
    if {key: mapped.get(key) for key in ('device', 'inode')} != file_identity(engine):
        errors.append('Mapped engine is not from the installed instance')
    if mapped.get('confinement') != f'snap.{instance}.busymark (enforce)':
        errors.append('Enforced BusyMark Snap label was not verified')


def observe_executable(tracker, record):
    pid = tracker.root
    stamp = tracker.seen[pid]
    with owned.ProcessHandle(pid) as process:
        if process.state(stamp)['status'] != 'running':
            return
        path = os.readlink('exe', dir_fd=process.fd)
        identity = file_identity(os.stat('exe', dir_fd=process.fd))
        if process.state(stamp)['status'] == 'running':
            record.update(executable=path, executableIdentity=identity)


def product_passed(kind, backend, report_path):
    if not report_path.is_file():
        return False
    report = json.loads(report_path.read_text())
    if report.get('ok') is not True:
        return False
    if kind == 'visualization':
        pdf = report_path.with_name('visualization-smoke.pdf')
        return pdf.is_file() and pdf.stat().st_size > 0
    checks = report.get('checks', {})
    if backend == 'x11':
        return (checks.get('bundledDictionaryFileCount') == 0
                and checks.get('dictionaryInstalledDuringRun') is True
                and checks.get('installedDictionaryCount') == 1)
    return all(checks.get(check) is True for check in (
        'sourceEditorTransaction', 'formattedRichEditorTransaction',
        'tableCellEditorTransaction'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('instance')
    parser.add_argument('kind', choices=('spelling', 'visualization'))
    parser.add_argument('backend', choices=('x11', 'wayland'))
    parser.add_argument('output', type=Path)
    parser.add_argument('--expected-engine', required=True, type=Path)
    args = parser.parse_args()
    if re.fullmatch(r'busymark(?:_[a-z0-9]{1,10})?', args.instance) is None:
        parser.error('Expected the ordinary BusyMark snap or a BusyMark instance name')
    output = args.output.absolute()
    output.mkdir(parents=True)
    report_path = output / 'product.json'
    mount = Path('/snap') / args.instance
    revision = (mount / 'current').resolve(strict=True)
    if revision.parent != mount or not re.fullmatch(r'x?[0-9]+', revision.name):
        parser.error('Expected a mounted BusyMark revision')
    runner = (revision / 'busymark').stat()
    engine = (revision / 'lib/libflutter_linux_gtk.so').stat()
    probe = LoadedEngine(args.expected_engine)
    tracker = owned.ChildTracker()
    errors = []
    record = {'instance': args.instance, 'revision': revision.name,
              'kind': args.kind, 'backend': args.backend}
    env = dict(os.environ, BUSYMARK_RELEASE_SMOKE='1', GDK_BACKEND=args.backend,
               LIBGL_ALWAYS_SOFTWARE='1')
    if args.backend == 'wayland':
        env.pop('DISPLAY', None)
    command = ['snap', 'run', args.instance,
               f'--{args.kind}-release-smoke={report_path}']
    with (output / 'application.log').open('x') as log:
        app = subprocess.Popen(command, env=env, stdout=log,
                               stderr=subprocess.STDOUT, start_new_session=True)
        tracker.root = app.pid
        stamp = owned.identity(app.pid)
        if stamp is None:
            errors.append('Application identity unavailable after launch')
        else:
            tracker.seen[app.pid] = stamp
        deadline = time.monotonic() + 300
        while app.poll() is None and time.monotonic() < deadline:
            tracker.scan()
            probe.capture(tracker)
            if probe.fd is not None and 'executableIdentity' not in record:
                try:
                    observe_executable(tracker, record)
                except (OSError, owned.ObservationIncomplete) as error:
                    errors.append(f'Executable observation failed: {error}')
                    break
            time.sleep(0.05)

    record['exitCode'] = app.poll()
    if record['exitCode'] is None:
        errors.append('Shipping smoke command did not exit during observation')
    probe.finish(record, errors)
    survivors = tracker.outstanding()
    grace = time.monotonic() + 5
    while survivors and time.monotonic() < grace:
        time.sleep(0.05)
        survivors = tracker.outstanding()
    if survivors:
        cleanup, unresolved = owned.cleanup_owned(tracker, 2, 3)
        record.update(cleanup=cleanup, unresolved=unresolved)
        errors.append('Application or descendants required cleanup')
    tracker.close()
    errors.extend(tracker.errors)
    verify_installation(record, runner, engine, args.instance, errors)
    try:
        record['productChecks'] = product_passed(args.kind, args.backend, report_path)
    except (OSError, ValueError) as error:
        record['productChecks'] = False
        errors.append(f'Product report could not be read: {error}')
    record['errors'] = errors
    record['accepted'] = record['exitCode'] == 0 and record['productChecks'] and not errors
    (output / 'receipt.json').write_text(json.dumps(record, indent=2) + '\n')
    print(json.dumps(record))
    return 0 if record['accepted'] else 1


if __name__ == '__main__':
    raise SystemExit(main())

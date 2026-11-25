"""Outcome policy for the verified BusyMark Linux shutdown defect."""

import json
import os
from pathlib import Path
import signal
import sys

from owned_processes import ProcessHandle


XFAIL_FLAG = '--xfail-flutter-3.50.1-shutdown'
FLUTTER_VERSION = '3.50.1'
DART_VERSION = '3.14.0'
RELEASE_ENGINE_SHA256 = '8fc5c4ee6a20215f54c332c7b8910c482434247e451f24cfd7d3225f0a28066b'
UPSTREAM_ISSUE = 'https://github.com/flutter/flutter/issues/189379'
DIAGNOSTIC = 'g_mutex_clear() called on uninitialised or locked mutex'
OUTCOMES = ('PASS', 'XFAIL', 'FAIL')


def classify(record, *, checks_passed, enabled=False, host=None, application_log=''):
    """Classify after verification and cleanup, preserving the kernel wait status."""
    code = record.get('exitCode')
    record['naturalExit'] = (
        type(code) is int and code == 0 and record.get('normalShutdownRequested') is True
        and record.get('forcedTermination') is False and record.get('timedOut') is False
    )
    record['outcome'] = 'FAIL'
    record.pop('expectedFailure', None)
    if (checks_passed is not True or record.get('forcedTermination') is not False
            or record.get('timedOut') is not False):
        return record['outcome']
    if record['naturalExit']:
        record['outcome'] = 'PASS'
    elif (enabled and sys.platform == 'linux' and host == 'busymark'
          and type(code) is int and code == -signal.SIGABRT
          and record.get('normalShutdownRequested') is True
          and record.get('functionalChecksPassed') is True
          and record.get('durableCleanShutdown') is True
          and record.get('verifiedApplicationProcess') is True):
        engine = record.get('loadedEngine', {})
        if (engine.get('sha256') == engine.get('expectedSHA256') == RELEASE_ENGINE_SHA256
                and DIAGNOSTIC in application_log.splitlines()):
            record['outcome'] = 'XFAIL'
            record['expectedFailure'] = {
                'flutterVersion': FLUTTER_VERSION, 'dartVersion': DART_VERSION,
                'issue': UPSTREAM_ISSUE, 'signal': 'SIGABRT', 'diagnostic': DIAGNOSTIC,
            }
    return record['outcome']


def require_affected_engine(expected_hash):
    if expected_hash != RELEASE_ENGINE_SHA256:
        raise RuntimeError(f'{XFAIL_FLAG} requires the verified official Linux x64 release engine; '
                           'reassess the exception when upgrading Flutter')


def recovery_state(path):
    """Read one durable snapshot and identify the file that supplied it."""
    try:
        with path.open() as stream:
            snapshot = json.load(stream)
            info = os.fstat(stream.fileno())
    except FileNotFoundError:
        return None, None
    return snapshot['cleanShutdown'], (info.st_dev, info.st_ino, info.st_mtime_ns, info.st_ctime_ns)


def require_executable(tracker, expected):
    """Bind the launched PID to the expected application, including Snap exec."""
    pid = tracker.root
    with ProcessHandle(pid) as process:
        if process.state(tracker.seen[pid])['status'] != 'running':
            raise RuntimeError('Application exited before executable verification')
        if not os.path.samestat(os.stat('exe', dir_fd=process.fd), expected):
            raise RuntimeError('Running executable differs from the expected BusyMark payload')
        if process.state(tracker.seen[pid])['status'] != 'running':
            raise RuntimeError('Application exited during executable verification')


def summarize(output, records, label):
    counts = dict.fromkeys(OUTCOMES, 0)
    for record in records:
        counts[record.get('outcome') if record.get('outcome') in OUTCOMES else 'FAIL'] += 1
    summary = {'runs': len(records), 'failures': counts['FAIL'], 'counts': counts, 'records': records}
    with (output / 'summary.json').open('x') as stream:
        json.dump(summary, stream, indent=2)
    message = f"{label}: " + ', '.join(f"{count} {outcome}" for outcome, count in counts.items())
    print(message, flush=True)
    if step_summary := os.environ.get('GITHUB_STEP_SUMMARY'):
        with Path(step_summary).open('a') as stream:
            stream.write(f'- {message}\n')
    return int(counts['FAIL'] != 0)

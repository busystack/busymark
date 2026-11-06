#!/usr/bin/env python3
"""Require a completed, unchanged, full Flutter corpus before local packaging."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.git_native_build_receipt import sources


def verify(receipt_path, root, flutter):
    root, flutter = Path(root).resolve(), Path(flutter).resolve()
    data = json.loads(Path(receipt_path).read_text())
    if data.get('status') != 'passed' or data.get('allDiscoveredCasesExercised') is not True:
        raise ValueError('Full test corpus has not passed')
    expected_files = data['filesSHA256']
    discovered = {str(p.relative_to(root)) for p in (root/'test').rglob('*_test.dart')}
    if not discovered or discovered != set(expected_files):
        raise ValueError('Test corpus is missing or has changed')
    for relative, digest in expected_files.items():
        if hashlib.sha256((root/relative).read_bytes()).hexdigest() != digest:
            raise ValueError('Test source changed: '+relative)
    current = sources(root.parent)
    if set(current) != set(data['sources']):
        raise ValueError('Production source binding is incomplete')
    for name, old in data['sources'].items():
        if old.get('hashVersion') != 2 or not old.get('productionFileCount') or old['sha256'] != current[name]['sha256']:
            raise ValueError('Production source changed: '+name)
        # Includes imported test helpers, fixtures and native test inputs, not
        # just the discovered entry files. Documentation/tool-only commits may
        # follow the run; its actual test and production inputs may not change.
        component = root.parent/name
        paths = ['test', 'lib', 'bin', 'linux', 'native', 'pubspec.yaml', 'pubspec.lock']
        subprocess.run(['git', 'diff', '--quiet', old['revision'], '--', *paths],
                       cwd=component, check=True)
        added = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--', *paths], cwd=component)
        if added.strip():
            raise ValueError('Unrecorded production/test input: '+name)
    seen, total = [], 0
    batches = data['batches']
    if not batches:
        raise ValueError('No completed test batches')
    for batch in batches:
        if batch.get('status') != 'passed' or batch.get('exitCode') != 0 or batch.get('skipped') != 0:
            raise ValueError('A test batch failed, skipped cases or did not finish')
        files = batch['files']
        command = batch['command']
        if (not files or Path(command[0]).resolve() != flutter or
                command[1:5] != ['test', '--no-pub', '--concurrency=2', '--reporter=expanded'] or
                command[5:] != files):
            raise ValueError('A batch changed the required full-file test command')
        log = Path(batch['log']).read_bytes()
        if hashlib.sha256(log).hexdigest() != batch['logSHA256']:
            raise ValueError('Recorded test output changed')
        matches = re.findall(r'\+(\d+)(?: ~(\d+))?(?: -(\d+))?: All tests passed!', log.decode(errors='replace'))
        if not matches or matches[-1] != (str(batch['passed']), '', ''):
            raise ValueError('Actual test output does not confirm the claimed passing cases')
        seen.extend(files)
        total += batch['passed']
    if len(seen) != len(set(seen)) or set(seen) != discovered or len(seen) != data['discoveredFiles']:
        raise ValueError('Each discovered file must be exercised exactly once')
    if total != data['totalPassed'] or data.get('totalSkipped') != 0:
        raise ValueError('Full-corpus totals differ')
    return {'files': len(discovered), 'passed': total, 'skipped': 0,
            'production': {name: value['sha256'] for name, value in current.items()}}


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Expected the full-corpus receipt and official Flutter executable')
    result = verify(sys.argv[1], Path(__file__).resolve().parents[1], sys.argv[2])
    print('Verified completed full Flutter corpus: '+json.dumps(result))

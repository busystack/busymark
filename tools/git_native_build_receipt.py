#!/usr/bin/env python3
"""Bind native acceptance captures to the source compiled by official Flutter.

Capture before building; seal after building. A seal refuses changed source.
This records evidence outside the shipping bundle, never modifies the toolchain.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sources(workspace=None):
    workspace = workspace or Path(__file__).resolve().parents[2]
    result = {}
    for name in ['busymark', 'busystack_git_flutter', 'busystack_git']:
        root = workspace / name
        digest = hashlib.sha256()
        files = set()
        for folder in ['lib', 'linux', 'native']:
            files.update(p for p in (root / folder).rglob('*') if p.is_file()
                         and not any(x in p.parts for x in ['.git', '.dart_tool', 'build', '.symlinks', 'ephemeral']))
        files.update(p for p in [root / 'pubspec.yaml', root / 'pubspec.lock'] if p.exists())
        for path in sorted(files):
            digest.update(str(path.relative_to(root)).encode() + b'\0' + path.read_bytes())
        revision = subprocess.run(['git', '-C', str(root), 'rev-parse', 'HEAD'], capture_output=True, text=True)
        state = subprocess.run(['git', '-C', str(root), 'status', '--short'], capture_output=True, text=True)
        result[name] = {'sha256': digest.hexdigest(),
                        'revision': revision.stdout.strip() if revision.returncode == 0 else 'materialized source archive',
                        'state': state.stdout if state.returncode == 0 else ''}
    return result


def payloads(binary):
    candidates = [binary, binary.parent / 'data/flutter_assets/kernel_blob.bin', binary.parent / 'lib/libapp.so']
    return {str(p.relative_to(binary.parent)): sha(p) for p in candidates if p.is_file()}


def verify(receipt, binary, workspace=None):
    if not receipt.get('sealed') or receipt['payloads'] != payloads(binary):
        raise RuntimeError('Binary payload differs from the sealed build receipt')
    current = sources(workspace)
    for name, source in receipt['sources'].items():
        if source['sha256'] != current[name]['sha256']:
            raise RuntimeError(f'{name} source changed since the recorded build')


def main():
    command, target = sys.argv[1], Path(sys.argv[2])
    if command == 'capture':
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps({'sources': sources(), 'sealed': False}, indent=2))
    elif command == 'seal':
        receipt = json.loads(target.read_text())
        current = sources()
        if any(source['sha256'] != current[name]['sha256'] for name, source in receipt['sources'].items()):
            raise RuntimeError('Source changed while Flutter was building')
        receipt.update(sealed=True, payloads=payloads(Path(sys.argv[3]).resolve()))
        target.write_text(json.dumps(receipt, indent=2))
    else:
        raise ValueError('Expected capture or seal')


if __name__ == '__main__':
    main()

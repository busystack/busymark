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


def sources(workspace=None, host="busymark"):
    if host not in {'busymark', 'busyfiles'}:
        raise ValueError('Unsupported native acceptance host')
    workspace = Path(workspace) if workspace is not None else Path(__file__).resolve().parents[2]
    result = {}
    for name in [host, 'busystack_git_flutter', 'busystack_git']:
        root = workspace / name
        digest = hashlib.sha256()
        files = set()
        production_files = set()
        components = [root]
        if name == 'busyfiles':
            components.extend(p for folder in ['apps', 'packages']
                              for p in (root / folder).iterdir() if p.is_dir())
        for component in components:
            for folder in ['lib', 'bin', 'linux', 'native']:
                production_files.update(p for p in (component / folder).rglob('*') if p.is_file()
                             and not any(x in p.relative_to(component).parts for x in ['.git', '.dart_tool', 'build', '.symlinks', 'ephemeral', '__pycache__']))
            files.update(p for p in [component / 'pubspec.yaml', component / 'pubspec.lock'] if p.exists())
        if not production_files:
            raise RuntimeError('No production source found for ' + name)
        files.update(production_files)
        for path in sorted(files):
            digest.update(str(path.relative_to(root)).encode() + b'\0' + path.read_bytes())
        identity = {'sha256': digest.hexdigest(), 'hashVersion': 2, 'productionFileCount': len(production_files), 'revision': 'materialized source archive', 'state': ''}
        if (root / '.git').exists():
            revision = subprocess.run(['git', '-C', str(root), 'rev-parse', 'HEAD'], capture_output=True, text=True)
            state = subprocess.run(['git', '-C', str(root), 'status', '--short'], capture_output=True, text=True)
            if revision.returncode != 0 or state.returncode != 0:
                raise RuntimeError('Cannot observe owned repository identity: ' + name)
            identity.update(revision=revision.stdout.strip(), state=state.stdout)
        else:
            for consumer in ['busymark', 'busyfiles', 'busystack_git_flutter']:
                manifest = workspace / consumer / 'tool/shared_dependencies.json'
                if manifest.exists():
                    for dependency in json.loads(manifest.read_text()).get('dependencies', []):
                        if dependency['name'] == name:
                            identity['pinnedRevision'] = dependency['revision']
                            identity['archiveSHA256'] = dependency['sha256']
                            identity['archiveTreeSHA256'] = dependency['tree_sha256']
        result[name] = identity
    return result


def payloads(binary):
    candidates = [binary, binary.parent / 'data/flutter_assets/kernel_blob.bin', binary.parent / 'lib/libapp.so']
    return {str(p.relative_to(binary.parent)): sha(p) for p in candidates if p.is_file()}


def verify(receipt, binary, workspace=None):
    if not receipt.get('sealed') or receipt['payloads'] != payloads(binary):
        raise RuntimeError('Binary payload differs from the sealed build receipt')
    current = sources(workspace or receipt.get('workspace'), receipt.get("host", "busymark"))
    for name, source in receipt['sources'].items():
        if source.get('hashVersion') != 2:
            raise RuntimeError('Obsolete source hash format; capture and build again: ' + name)
        if source['sha256'] != current[name]['sha256']:
            raise RuntimeError(f'{name} source changed since the recorded build')


def main():
    command, target = sys.argv[1], Path(sys.argv[2])
    host = 'busyfiles' if '--host=busyfiles' in sys.argv else 'busymark'
    workspace = next((Path(arg.split('=', 1)[1]).resolve() for arg in sys.argv if arg.startswith('--workspace=')), Path(__file__).resolve().parents[2])
    if command == 'capture':
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps({'host': host, 'workspace': str(workspace), 'sources': sources(workspace, host=host), 'sealed': False}, indent=2))
    elif command == 'seal':
        receipt = json.loads(target.read_text())
        current = sources(receipt.get('workspace'), host=receipt.get('host', 'busymark'))
        if any(source['sha256'] != current[name]['sha256'] for name, source in receipt['sources'].items()):
            raise RuntimeError('Source changed while Flutter was building')
        receipt.update(sealed=True, payloads=payloads(Path(sys.argv[3]).resolve()))
        target.write_text(json.dumps(receipt, indent=2))
    else:
        raise ValueError('Expected capture or seal')


if __name__ == '__main__':
    main()

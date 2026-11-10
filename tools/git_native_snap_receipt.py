#!/usr/bin/env python3
"""Bind a development Snap repack to a pre-build receipt and installed payload.

This is artifact qualification, not a clean Snapcraft release qualification.
The complete packed filesystem is checked as well as the actual Flutter bundle.
"""
import argparse
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile

from git_native_build_receipt import payloads, sha, verify


def tree(root):
    """Hash entries without following package symlinks outside the package."""
    result = {}
    for directory, directories, files in os.walk(root, followlinks=False):
        for name in sorted(directories + files):
            path = Path(directory) / name
            info = path.lstat()
            entry = {'mode': stat.S_IMODE(info.st_mode)}
            if stat.S_ISLNK(info.st_mode):
                entry.update(kind='link', target=os.readlink(path))
            elif stat.S_ISDIR(info.st_mode):
                entry.update(kind='directory')
            elif stat.S_ISREG(info.st_mode):
                entry.update(kind='file', sha256=sha(path))
            else:
                raise RuntimeError('Unexpected package entry: ' + str(path))
            result[str(path.relative_to(root))] = entry
    if not result:
        raise RuntimeError('Empty Snap filesystem')
    return result


def require_bundle(compiled, binary):
    for relative, expected in compiled['payloads'].items():
        path = binary.parent / relative
        if not path.is_file() or sha(path) != expected:
            raise RuntimeError('Snap differs from qualified Flutter bundle: ' + relative)


def bind(compiled, binary, root, package):
    verify(compiled, binary)
    require_bundle(compiled, root / binary.name)
    entries = tree(root)
    with tempfile.TemporaryDirectory(prefix='bsg-snap-verify-', dir='/var/tmp') as temporary:
        extracted = Path(temporary) / 'root'
        subprocess.run(['unsquashfs', '-no-progress', '-processors', '2', '-d',
                        str(extracted), str(package)], check=True, stdout=subprocess.DEVNULL)
        if tree(extracted) != entries:
            raise RuntimeError('Packed Snap filesystem differs from the qualified root')
    return {'kind': 'qualified development repack; not clean Snapcraft release',
            'package': str(package), 'packageSHA256': sha(package),
            'buildReceipt': compiled, 'entries': entries}


def installed(binding, binary):
    binary = binary.resolve()
    if (binary.name != 'busymark' or binary.parent.parent != Path('/snap/busymark')
            or not os.path.ismount(binary.parent)):
        raise RuntimeError('Expected the actual installed BusyMark Snap mount')
    if sha(Path(binding['package'])) != binding['packageSHA256']:
        raise RuntimeError('Qualified Snap artifact changed')
    if tree(binary.parent) != binding['entries']:
        raise RuntimeError('Installed Snap differs from qualified package filesystem')
    compiled = binding['buildReceipt']
    require_bundle(compiled, binary)
    receipt = dict(compiled, payloads=payloads(binary), provenance={
        'kind': binding['kind'], 'package': binding['package'],
        'packageSHA256': binding['packageSHA256'], 'installedMount': str(binary.parent),
        'qualifiedBuildPayloadCount': len(compiled['payloads']),
        'qualifiedPackageEntryCount': len(binding['entries'])})
    verify(receipt, binary)
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    first = sub.add_parser('bind')
    first.add_argument('build_receipt', type=Path)
    first.add_argument('binary', type=Path)
    first.add_argument('root', type=Path)
    first.add_argument('package', type=Path)
    first.add_argument('output', type=Path)
    second = sub.add_parser('installed')
    second.add_argument('binding', type=Path)
    second.add_argument('binary', type=Path)
    second.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.command == 'bind':
        result = bind(json.loads(args.build_receipt.read_text()), args.binary.resolve(),
                      args.root.resolve(), args.package.resolve())
    else:
        result = installed(json.loads(args.binding.read_text()), args.binary)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'output': str(args.output), 'kind': result.get('kind',
                     result.get('provenance', {}).get('kind'))}))


if __name__ == '__main__':
    main()

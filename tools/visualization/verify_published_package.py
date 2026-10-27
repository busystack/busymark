#!/usr/bin/env python3
"""Reject downstream changes to an installed, checksum-verified npm package."""
import argparse
import hashlib
from pathlib import Path, PurePosixPath
import tarfile


def verify(archive: Path, installed: Path) -> None:
    expected = {}
    with tarfile.open(archive, 'r:gz') as source:
        for member in source:
            path = PurePosixPath(member.name)
            if path.is_absolute() or '..' in path.parts or path.parts[:1] != ('package',):
                raise ValueError('Unsafe published package path')
            if member.isdir():
                continue
            if not member.isfile():
                raise ValueError('Published package contains an unsupported link')
            relative = Path(*path.parts[1:])
            if not relative.parts or relative in expected:
                raise ValueError('Invalid or duplicate published package file')
            with source.extractfile(member) as stream:
                expected[relative] = hashlib.file_digest(stream, 'sha256').digest()
    if not expected:
        raise ValueError('Published package has no files')
    actual = set()
    for path in installed.rglob('*'):
        relative = path.relative_to(installed)
        # npm may put separately locked dependencies here. Their integrity is
        # checked by npm ci; they are not files of this published package.
        if relative.parts[:1] == ('node_modules',):
            continue
        if path.is_symlink():
            raise ValueError('Installed package contains a substituted link')
        if not path.is_file():
            continue
        actual.add(relative)
        with path.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').digest()
        if expected.get(relative) != digest:
            raise ValueError(f'Installed package differs from publisher: {relative}')
    if actual != expected.keys():
        raise ValueError('Installed package is missing published files')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('installed', type=Path)
    args = parser.parse_args()
    verify(args.archive, args.installed)

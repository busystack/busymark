#!/usr/bin/env python3
"""Verify the committed delivery archive and optionally rerun Notes regressions."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile


def sha(path):
    return hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--run-tests', action='store_true')
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())
    root = args.manifest.resolve().parent
    for artifact in manifest['artifacts']:
        assert sha(root / artifact['path']) == artifact['sha256'], artifact['path']
    archive = root / manifest['sourceArchive']
    with tempfile.TemporaryDirectory(prefix='busymark-delivery-verify-') as directory:
        extracted = Path(directory)
        with tarfile.open(archive) as source:
            assert source.pax_headers.get('comment') == manifest['sourceCommit']
            source.extractall(extracted, filter='data')
        tree = extracted / manifest['sourcePrefix']
        for name, digest in manifest['sourceFiles'].items():
            assert sha(tree / name) == digest, name
        for evidence in ['linux-source-identity.json', 'snap-source-identity.json']:
            identity = json.loads((tree / 'delivery/nextcloud-explicit-adoption/evidence' / evidence).read_text())
            for name, digest in identity.get('compiledInputs', identity.get('buildSourceFiles', {})).items():
                assert sha(tree / name) == digest, (evidence, name)
        if manifest.get('releaseAcceptanceComplete'):
            evidence_root = tree / 'delivery/nextcloud-explicit-adoption/evidence'
            installed = json.loads((evidence_root / 'snap-acceptance-results.json').read_text())
            assert installed['complete'] and installed['strictInstalled']
            assert installed['enforcedAppArmorVerified'] and installed['installedSha256Verified']
            snap_artifacts = [a for a in manifest['artifacts'] if a['path'].endswith('.snap')]
            assert len(snap_artifacts) == 1
            assert installed['snapSha256'] == snap_artifacts[0]['sha256']
            for name, path in installed['visualization']['reports'].items():
                report = json.loads((evidence_root / path).read_text())
                assert report['ok'] and len(report['checks']) == 23, name
        repository = (tree / 'lib/src/nextcloud_notes/application/notes_repository.dart').read_text()
        discovery = repository.split('Future<void> _applyList(', 1)[1].split('NextcloudNote _fromRemote(', 1)[0]
        assert '_adoptCreation(' not in discovery
        assert repository.count('_adoptCreation(') == 2
        confirmation = repository.split('Future<void> _resolveCreation(', 1)[1].split('Future<void> delete(', 1)[0]
        assert '_adoptCreation(current, fresh)' in confirmation
        regressions = (tree / 'test/src/nextcloud_notes/notes_creation_policy_test.dart').read_text()
        assert "'other actor'" in regressions
        assert 'transaction' in regressions
        assert 'repeated confirmation' in regressions
        if args.run_tests:
            subprocess.run(['flutter', 'pub', 'get', '--enforce-lockfile'], cwd=tree, check=True)
            top_level = sorted(str(p.relative_to(tree)) for p in (tree / 'test/src').glob('nextcloud_*_test.dart'))
            subprocess.run(['flutter', 'test', '--no-pub', '--concurrency=1', '--reporter', 'expanded',
                            'test/src/nextcloud_notes', *top_level], cwd=tree, check=True)
    print('Archive bytes, explicit-adoption policy, regressions and artifact hashes verified.')


if __name__ == '__main__':
    main()

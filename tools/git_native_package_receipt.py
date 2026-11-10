#!/usr/bin/env python3
"""Import an already qualified BusyFiles DEB producer binding for native runs.

This is not a post-hoc pre-build capture. The existing release producer's
before/after source manifest and package payload manifest are the provenance.
All installed files are checked before creating the ordinary native receipt.
No package installation or application mutation is performed here.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess

from git_native_build_receipt import payloads, sha, sources, verify


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact_directory', type=Path)
    parser.add_argument('source_workspace', type=Path)
    parser.add_argument('installed_root', type=Path)
    parser.add_argument('receipt', type=Path)
    args = parser.parse_args()
    artifact, workspace, installed = (
        p.resolve() for p in [args.artifact_directory, args.source_workspace, args.installed_root])
    app = workspace/'busyfiles'
    spec = importlib.util.spec_from_file_location('busyfiles_release_binding', app/'scripts/linux_release.py')
    release = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(release)
    contract = release.read_json(artifact/'engine-contract.json')
    manifest = release.read_json(artifact/'release-manifest.json')
    release.verify_locked_identity(contract)
    release.verify_locked_identity(contract['source'])
    release.verify_locked_identity(manifest)
    release.require_baseline(manifest['producer'])
    release.verify_source(contract['source'], app)
    if (manifest['engine_contract_sha256'] != release.digest_json(contract)
            or manifest['source_manifest_sha256'] != contract['source_manifest_sha256']
            or contract['source_manifest_sha256'] != contract['source']['source_manifest_sha256']):
        raise RuntimeError('Package producer source/engine/payload binding differs')
    subprocess.run(['python3', str(workspace/'busystack_git_flutter/tool/check_consumer_consistency.py'),
                    '--consumer', str(app)], check=True)
    packages = list(artifact.glob('*.deb'))
    if len(packages) != 1:
        raise RuntimeError('Expected exactly one qualified DEB')
    package = packages[0]
    checksums = {}
    for line in (artifact/'SHA256SUMS').read_text().splitlines():
        if line.strip():
            digest, name = line.split(maxsplit=1)
            checksums[str(Path(name.lstrip('*')))] = digest
    if checksums.get(package.name) != sha(package):
        raise RuntimeError('DEB differs from its producer checksum')
    external = {}
    binary = installed/'usr/lib/busyfiles/busyfiles'
    for relative, expected in manifest['files'].items():
        path = installed/'usr/lib/libbusyfiles_gio.so.0' if relative == '@native/libbusyfiles_gio.so.0' else release.safe_path(installed, relative)
        if not path.is_file() or sha(path) != expected:
            raise RuntimeError('Installed file differs from qualified package: ' + relative)
        # Keep daemon, supervisor, native system service and desktop files bound
        # during the native run, including paths outside the UI bundle.
        external[str(path)] = expected
    receipt = {'host': 'busyfiles', 'workspace': str(workspace), 'sealed': True,
               'sources': sources(workspace, host='busyfiles'),
               'payloads': payloads(binary), 'externalPayloads': external,
               'provenance': {
                   'kind': 'verified existing release-producer binding; not a pre-build capture',
                   'package': str(package), 'packageSHA256': sha(package),
                   'engineContractSHA256': release.digest_json(contract),
                   'releaseManifestSHA256': release.digest_json(manifest),
                   'sourceManifestSHA256': manifest['source_manifest_sha256'],
                   'compiledGitRevision': contract['source']['git_sha'],
                   'installedRoot': str(installed)}}
    verify(receipt, binary)
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(json.dumps(receipt, indent=2)+'\n')
    print(json.dumps({'receipt': str(args.receipt), 'checkedPackageFiles': len(external),
                      'UIBundleFiles': len(receipt['payloads']), 'provenance': receipt['provenance']}))


if __name__ == '__main__':
    main()

from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import tarfile

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
out = root/'followup-20261101-cf29cd1'
source = root/'inputs/busymark'
bundle = source/'build/linux/x64/release/bundle'
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source, text=True).strip()
assert revision == 'cf29cd125d650d831284f96439f8662bd69abc52'
assert not subprocess.check_output(['git', 'diff', '--name-only'], cwd=source)
assert shutil.disk_usage(out).free >= 3*1024**3
target = out/'busymark-cf29cd1-linux-release.tar.gz'
assert not target.exists()
with tarfile.open(target, 'w:gz') as archive:
    archive.add(bundle, arcname='busymark')
receipt = dict(source=revision, artifact=target.name,
    artifactSha256=hashlib.sha256(target.read_bytes()).hexdigest(),
    files={str(p.relative_to(bundle)): hashlib.sha256(p.read_bytes()).hexdigest()
           for p in bundle.rglob('*') if p.is_file()},
    sdk=json.loads((root/'flutter/bin/cache/flutter.version.json').read_text()),
    sdkTrackedChanges=subprocess.check_output(['git', 'status', '--porcelain',
        '--untracked-files=no'], cwd=root/'flutter', text=True))
assert receipt['sdkTrackedChanges'] == ''
assert receipt['files']['lib/libflutter_linux_gtk.so'] == 'd57449a5c2ee39e77b9e3488f0703b165c67e0b3c554089f388db96484ae62f1'
(out/'release-runtime-receipt.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(dict(source=revision, artifact=str(target), sha256=receipt['artifactSha256'])))

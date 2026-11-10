from pathlib import Path
import hashlib
import json
import subprocess
import tarfile

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
out = root/'followup-20261101-cf29cd1'
native = root/'final-cf29'
metadata = {
    'source': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root/'inputs/busymark', text=True).strip(),
    'trackedChanges': subprocess.check_output(['git', 'status', '--porcelain'], cwd=root/'inputs/busymark', text=True),
    'backend': 'X11/Xvfb, Openbox', 'width': 1440, 'height': 1000,
    'dpi': 96, 'deviceScale': 1.0, 'textScale': 1.0,
    'locale': 'en_US.UTF-8', 'theme': 'light, GTK_THEME=Yaru-blue',
    'runtimeDirectory': '/tmp/bsgit-cf29-runtime',
    'kernel': subprocess.check_output(['uname', '-a'], text=True).strip(),
    'nativePackages': subprocess.check_output(['dpkg-query', '-W',
        'libgtk-3-0t64', 'libglib2.0-0t64', 'libx11-6', 'libxtst6'], text=True),
    'captures': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in native.glob('*.png')},
}
assert metadata['trackedChanges'] == ''
(out/'native-captures.json').write_text(json.dumps(metadata, indent=2))
target = root/'cf29-followup-evidence.tar.gz'
assert not target.exists()
with tarfile.open(target, 'w:gz') as archive:
    for path in sorted(out.iterdir()):
        if path.is_file() and path.suffix != '.gz':
            archive.add(path, arcname='runtime/'+path.name)
    for path in sorted(native.iterdir()):
        if path.is_file() and path.suffix in ('.png', '.json', '.log'):
            archive.add(path, arcname='captures/'+path.name)
    for relative in [
        'final-ui/mark-fae6697-release.log',
        'final-ui/mark-release-routing-probe.log',
        'final-ui/pure-flutter-release.log',
        'followup-20261101/native/mark-keyboard-probe.log',
        'followup-20261101-final/release-build.log',
    ]:
        path = root/relative
        if path.is_file():
            archive.add(path, arcname='diagnostics/'+relative)
    for name in ['followup_verify.py', 'followup_control.py', 'native_session_followup.py',
                 'followup_export.py', 'followup_debug_receipt.py']:
        archive.add(root/name, arcname='tooling/'+name)
print(json.dumps(dict(path=str(target), sha256=hashlib.sha256(target.read_bytes()).hexdigest())))

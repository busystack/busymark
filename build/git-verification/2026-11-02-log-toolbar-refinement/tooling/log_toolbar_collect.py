from pathlib import Path
import hashlib
import json
import subprocess
import tarfile
import time

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
out = root / 'log-toolbar-refinement-20261102'
native = root / 'log-toolbar-refinement-ui'

def output(*args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()

accepted = sorted(p for p in native.glob('*.png') if
                  p.name.startswith('accepted-') or p.name in (
                      'final-selected-commit-keyboard-focus.png',
                      'final-keyboard-history-selector.png'))
sources = json.loads((out / 'final-sources.json').read_text())
assert sources['mark'] == '23781d8c7a46ddd4a2ba63d1981b3f69888ef6e6'
assert sources['files'] == '309a230f59f1e2bd7cc22ab36bd1d65d9353528e'
changes = {name: output('git', 'status', '--porcelain', cwd=root/'inputs'/name)
           for name in ('busymark', 'busyfiles')}
assert not any(changes.values())
metadata = dict(
    collected=time.time(), sources=sources, trackedChanges=changes,
    backend='X11/Xvfb with Openbox', screen=[1440, 1000], dpi=96,
    deviceScale=1, textScale='Desktop default; rendered tests separately cover 1 and 2',
    processLocale='en_US.UTF-8', appLocales=['en', 'de', 'ja', 'ar (RTL)'],
    themes=['light', 'dark'], accent='Yaru-blue',
    accessibilitySetting=(native/'accessibility-setting.txt').read_text().strip(),
    kernel=output('uname', '-a'), osRelease=Path('/etc/os-release').read_text(),
    packages=output('dpkg-query', '-W', 'libgtk-3-0t64', 'libglib2.0-0t64',
                    'libx11-6', 'libxtst6'),
    captures={p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in accepted},
    captureSources='accepted-* and the two final keyboard proofs only; older images are investigation',
    limitations=[
        'Flutter body AT-SPI exposure remains limited; existing desktop setting unchanged',
        'Native enlarged/fractional desktop, Wayland and Windows not verified',
        'Existing FlutterEngineRemoveView debug-close warning and intermittent shutdown failures retained',
        'Files final source compiled release but approved production gate requires Ubuntu 26.04; this VM is 24.04',
        'No strict Snap, external network/signing or dedicated performance qualification'])
(out/'native-captures.json').write_text(json.dumps(metadata, indent=2))
target = root/'log-toolbar-refinement-evidence.tar.gz'
assert not target.exists()
with tarfile.open(target, 'w:gz') as archive:
    for p in sorted(out.iterdir()):
        if p.is_file() and p.suffix in ('.json', '.jsonl', '.log', '.txt'):
            archive.add(p, arcname='runtime/'+p.name)
    for p in sorted((out/'cache-probe').rglob('*')):
        if p.is_file() and p.suffix in ('.json', '.jsonl', '.log', '.txt'):
            archive.add(p, arcname='runtime/cache-probe/'+str(p.relative_to(out/'cache-probe')))
    for p in sorted(native.iterdir()):
        if not p.is_file():
            continue
        if p in accepted:
            archive.add(p, arcname='captures/'+p.name)
        elif p.suffix == '.png':
            archive.add(p, arcname='investigation-captures/'+p.name)
        elif p.suffix in ('.json', '.log', '.txt'):
            archive.add(p, arcname='native-runtime/'+p.name)
    tooling = [*root.glob('log_toolbar*.py'), *root.glob('log_toolbar*.dart'),
               root/'native_session_sidebar_refinement.py']
    for p in sorted(tooling):
        archive.add(p, arcname='tooling/'+p.name)
print(json.dumps(dict(path=str(target), bytes=target.stat().st_size,
                     sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
                     captures=len(accepted))))

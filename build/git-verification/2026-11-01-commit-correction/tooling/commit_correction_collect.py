from pathlib import Path
import hashlib,json,subprocess,tarfile
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
out=root/'commit-correction-20261101'
native=root/'commit-correction-ui'
selected=set('''untrusted-en-light trust-confirmation trust-cancelled
trusted-en-light trusted-staged-comparison branches-en-light branches-context-menu
header-refresh-hover-final header-refresh-pressed-final flat-options-keyboard-focus
keyboard-activated-options-menu file-unstage-hover approved-files-tree-reference
commit-de-light-restart commit-ja-dark branches-ja-dark commit-ar-light-rtl
branches-ar-rtl ordinary-debug-commit descendant-workspace-root-required
git-log-inspector history-selection-modal historical-comparison
multiple-independent-comparisons git-after-local-history
local-history-keyboard-reactivation local-history-mouse-reactivation
files-correction-browser-descendant files-correction-commit-descendant files-correction-branches'''.split())
metadata=dict(
 source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root/'inputs/busymark',text=True).strip(),
 trackedChanges=subprocess.check_output(['git','status','--porcelain'],cwd=root/'inputs/busymark',text=True),
 backend='X11/Xvfb with Openbox',screen=[1440,1000],dpi=96,deviceScale=1,
 textScale='default (no desktop override); host widget tests separately cover 1.0/1.5/2.0',
 processLocale='en_US.UTF-8',appLocales=['en','de','ja','ar (RTL)'],themes=['light','dark'],
 accent='GTK_THEME=Yaru-blue',runtimeDirectory='/tmp/bmcorr-runtime',
 accessibilitySetting=(native/'accessibility-setting.txt').read_text().strip(),
 kernel=subprocess.check_output(['uname','-a'],text=True).strip(),
 osRelease=Path('/etc/os-release').read_text(),
 nativePackages=subprocess.check_output(['dpkg-query','-W','libgtk-3-0t64','libglib2.0-0t64','libx11-6','libxtst6'],text=True),
 captures={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in native.glob('*.png') if p.stem in selected},
 limitations=['AT-SPI body tree unavailable: application/frame only; setting left unchanged',
 'Fractional Wayland and enlarged desktop text not verified in Xvfb',
 'Descendant-window close reproduced existing g_mutex_clear SIGABRT; other release and normal debug exits succeeded',
 'VM Ubuntu 24.04 cannot qualify BusyFiles production packaging; separate Ubuntu 26.04 host build retained'])
assert not metadata['trackedChanges']
(out/'native-captures.json').write_text(json.dumps(metadata,indent=2))
target=root/'commit-correction-evidence.tar.gz'
assert not target.exists()
with tarfile.open(target,'w:gz') as archive:
 for p in sorted(out.iterdir()):
  if p.is_file() and p.suffix in ('.json','.jsonl','.log'):
   archive.add(p,arcname='runtime/'+p.name)
 for p in sorted(native.iterdir()):
  if p.is_file() and (p.suffix in ('.json','.log','.txt') or (p.suffix=='.png' and p.stem in selected)):
   archive.add(p,arcname='captures/'+p.name)
 for p in sorted(root.glob('*commit_correction*.py')):
  archive.add(p,arcname='tooling/'+p.name)
print(json.dumps(dict(path=str(target),sha256=hashlib.sha256(target.read_bytes()).hexdigest())))

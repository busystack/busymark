from pathlib import Path
import hashlib,json,subprocess,tarfile
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
out=root/'sidebar-refinement-20261101'
native=root/'sidebar-refinement-ui'
selected=set('untrusted-en-light trust-confirmation-en trust-cancelled trusted-commit-en-normal branch-pressed-en branches-modal-en-settled branch-row-menu-en branches-search-remote-en repository-actions-en unstage-pressed-en amend-checked-en comparisons-draft-en unsaved-document-en local-history-comparison-en git-to-local-history-mouse local-history-to-git-keyboard git-to-local-history-keyboard manage-branches-tooltip-en-settled dirty-close-guard-en commit-de-light-narrow-visible commit-ja-dark branches-ja-dark commit-ar-light-rtl branches-ar-rtl repository-actions-ar-rtl trust-revoked-ar ordinary-debug-untrusted debug-trust-confirmation debug-git-log-inspector debug-history-selector amend-keyboard-focus-debug amend-keyboard-toggle-debug descendant-root-required separate-root-untrusted long-root-trust-confirmation long-branch-flat-header workspace-path-tooltip long-branch-full-modal'.split())
metadata=dict(
 source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root/'inputs/busymark',text=True).strip(),
 trackedChanges=subprocess.check_output(['git','status','--porcelain'],cwd=root/'inputs/busymark',text=True),
 backend='X11/Xvfb with Openbox',screen=[1440,1000],dpi=96,deviceScale=1,
 textScale='default (no desktop override); host widget tests separately cover 1.0/1.5/2.0',
 processLocale='en_US.UTF-8',appLocales=['en','de','ja','ar (RTL)'],themes=['light','dark'],
 accent='GTK_THEME=Yaru-blue',runtimeDirectory='/tmp/bmsidebar-runtime',
 accessibilitySetting=(native/'accessibility-setting.txt').read_text().strip(),
 kernel=subprocess.check_output(['uname','-a'],text=True).strip(),
 osRelease=Path('/etc/os-release').read_text(),
 nativePackages=subprocess.check_output(['dpkg-query','-W','libgtk-3-0t64','libglib2.0-0t64','libx11-6','libxtst6'],text=True),
 captures={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in native.glob('*.png') if p.stem in selected},
 limitations=['AT-SPI body tree unavailable: application/frame only; setting left unchanged',
 'Fractional Wayland and enlarged desktop text not verified in Xvfb',
 'Release SIGABRT on shutdown and FlutterEngineRemoveView debug-close warning reproduced; UI operation and builds passed',
 'Initial Dart test hook startup stalled on external port 443; existing resolved-package runner passed the same IPC tests',
 'BusyFiles production packaging was outside this bounded correction; prior qualifications remain separate'])
assert not metadata['trackedChanges']
(out/'native-captures.json').write_text(json.dumps(metadata,indent=2))
target=root/'sidebar-refinement-evidence.tar.gz'
assert not target.exists()
with tarfile.open(target,'w:gz') as archive:
 for p in sorted(out.iterdir()):
  if p.is_file() and p.suffix in ('.json','.jsonl','.log'):
   archive.add(p,arcname='runtime/'+p.name)
 for p in sorted(native.iterdir()):
  if p.is_file() and (p.suffix in ('.json','.log','.txt') or (p.suffix=='.png' and p.stem in selected)):
   archive.add(p,arcname='captures/'+p.name)
 for p in sorted(root.glob('*sidebar_refinement*.py')):
  archive.add(p,arcname='tooling/'+p.name)
print(json.dumps(dict(path=str(target),sha256=hashlib.sha256(target.read_bytes()).hexdigest())))

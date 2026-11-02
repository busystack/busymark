from pathlib import Path
import hashlib,json,subprocess,tarfile,time
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
out=r/'commit-details-remediation-20261102'; native=r/'commit-details-remediation-ui'
def output(*args,cwd=None):return subprocess.check_output(args,cwd=cwd,text=True).strip()
accepted={}
def add(name,locale='en',theme='light',width=1280,height=720,record=None,target=None):
 p=native/(name+'.png');assert p.exists(),p
 accepted[p.name]=dict(target=(target or name)+'.png',locale=locale,theme=theme,window=[width,height],actualTextScale=1.0,record=record,sha256=hashlib.sha256(p.read_bytes()).hexdigest())
for n in ['untrusted-en','trust-dialog-en','commit-native-branch-en','merge-inspector-en','commit-actions-en','copy-hash-highlight-en','merge-details-en','selected-message-en','native-text-copy-menu-en','history-selector-en','ordinary-root-inspector-en','short-details-en','long-inspector-en','long-details-top-en','long-details-bottom-en','file-actions-hover-en','file-actions-pressed-en','historical-file-menu-en','historical-file-secondary-en','historical-comparison-en']:add(n)
add('short-details-narrow-en',width=900,height=740,record='root/short')
for n,target in [('merge-inspector-dark-en','short-inspector-dark-en'),('commit-actions-dark-en','commit-actions-dark-en'),('merge-details-dark-en','short-details-dark-en')]:add(n,theme='dark',record='root/short',target=target)
for n in ['verified-commit-actions-de','verified-long-details-de','verified-details-bottom-de']:add(n,locale='de',record='long')
for locale in ['ja','ar','fr','pt','ru','uk']:
 for base in ['commit-actions','long-details','details-bottom']:
  name=base+'-'+locale
  if locale=='ja' and base=='details-bottom':name='long-details-bottom-ja'
  add(name,locale=locale,theme='dark' if locale=='ar' else 'light',record='long')
for locale in ['ar','en']:
 for base in ['native-dark-commit-actions','native-dark-details' if locale=='ar' else 'native-dark-long-details']:
  add(base+'-'+locale,locale=locale,theme='dark',record='long')
add('debug-main-inspector-en',record='long')
add('debug-main-details-en',record='long')
sources=json.loads((out/'final-sources.json').read_text())
assert sources['mark']=='0b92f501330478e44ffb22db31779c45f10efdf3'
assert sources['files']=='1d414dc44495428bbe21eb664db924d433042821'
changes={n:output('git','status','--porcelain',cwd=r/'inputs'/n) for n in ['busymark','busyfiles']};assert not any(changes.values())
meta=dict(collected=time.time(),sources=sources,trackedChanges=changes,backend='X11/Xvfb with Openbox',screen=[1440,1000],dpi=96,devicePixelRatio=1,textScale='Native accepted images are actual default 1.0. Private GIO keyfile requested 1.5, but the portal-backed application did not enlarge; those probes are investigation, not scale acceptance. Widget tests exercise actual host routes at 1 and 2.',accent='Yaru-blue',processLocale='en_US.UTF-8',accessibilitySetting=(native/'accessibility-setting.txt').read_text().strip(),osRelease=Path('/etc/os-release').read_text(),kernel=output('uname','-a'),packages=output('dpkg-query','-W','libgtk-3-0t64','libglib2.0-0t64','libx11-6','libxtst6'),captures=accepted,limitations=['Native enlarged/fractional desktop, Wayland and Windows remain unqualified','Existing AT-SPI body exposure and native shutdown/mutex failures retained; no runtime/security/accessibility modification','Strict Snap, network/signing and dedicated performance qualification remain separate'])
(out/'native-captures.json').write_text(json.dumps(meta,indent=2))
results={}
for name in ['shared-tests','shared-real-repositories','mark-host-tests','mark-host-tests-attempt2','watcher-isolated','files-git-ipc-tests','files-ui-git-tests']:
 p=out/(name+'.log')
 if not p.exists():continue
 done=[];errors=[];success=None;tests={}
 for l in p.read_text(errors='replace').splitlines():
  try:e=json.loads(l)
  except ValueError:continue
  if not isinstance(e,dict):continue
  if e.get('type')=='testStart':tests[e['test']['id']]=e['test']
  if e.get('type')=='testDone' and not e.get('hidden',False):done.append(e)
  if e.get('type')=='error':errors.append(e)
  if e.get('type')=='done':success=e.get('success')
 results[name]=dict(passed=sum(e['result']=='success' and not e.get('skipped') for e in done),failed=sum(e['result'] in ['failure','error'] for e in done),skipped=sum(bool(e.get('skipped')) for e in done),success=success,errors=[dict(e,test=tests.get(e['testID'])) for e in errors])
(out/'test-results.json').write_text(json.dumps(results,indent=2))
target=r/'commit-details-remediation-evidence.tar.gz';assert not target.exists()
with tarfile.open(target,'w:gz') as a:
 for p in sorted(out.iterdir()):
  if p.is_file() and p.suffix in ['.json','.jsonl','.log','.txt']:a.add(p,arcname='runtime/'+p.name)
 for p in sorted(native.iterdir()):
  if not p.is_file():continue
  if p.name in accepted:a.add(p,arcname='captures/'+accepted[p.name]['target'])
  elif p.suffix=='.png':a.add(p,arcname='investigation-captures/'+p.name)
  elif p.suffix in ['.json','.jsonl','.log','.txt']:a.add(p,arcname='native-runtime/'+p.name)
 for p in sorted([*r.glob('commit_details*.py'),*r.glob('commit_details*.dart')]):a.add(p,arcname='tooling/'+p.name)
print(json.dumps(dict(path=str(target),bytes=target.stat().st_size,sha256=hashlib.sha256(target.read_bytes()).hexdigest(),captures=len(accepted))))

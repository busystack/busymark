from pathlib import Path
import json,hashlib,os,subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031'); out=r/'log-toolbar-refinement-20261102'; f=out/'fixture'
g=str(r/'official-assets/git-runtime/bin/git');env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def git(*args,**kw):return subprocess.check_output([g,'-C',str(f),*args],env=env,**kw)
before=json.loads((out/'fixture-before.json').read_text());after=json.loads((out/'fixture-after.json').read_text())
changed={k:dict(before=before.get(k),after=after.get(k)) for k in before.keys()|after.keys() if before.get(k)!=after.get(k)}
assert set(changed)<={'.git/index'},changed
head=git('rev-parse','HEAD').decode().strip();assert head==json.loads((out/'fixture-manifest.json').read_text())['head']
expected={p.split(b'\t',1)[1]:p.split(b'\t',1)[0].split()[:2] for p in git('ls-tree','-rz',head).split(b'\0') if p}
# ls-tree returns mode, type, oid; compare every actual mode and immutable blob.
expected={p.split(b'\t',1)[1]:(p.split()[0],p.split()[2]) for p in git('ls-tree','-rz',head).split(b'\0') if p}
original=''.join(f'Line {i:02d}: original review content\n' for i in range(1,61));staged=original.replace('Line 03: original','Line 03: staged').encode()
expected[b'docs/review.md']=(b'100644',git('hash-object','--stdin',input=staged).strip())
actual={p.split(b'\t',1)[1]:(p.split()[0],p.split()[1]) for p in git('ls-files','-sz').split(b'\0') if p}
assert expected==actual,(expected,actual)
assert git('show',':docs/review.md')==staged
record=dict(workingFilesHeadConfigRefsUnchanged=True,allIndexModesAndBlobsMatchOriginalFixture=True,originalPartialStagingRetained=True,rawIndexFileChanges=changed,initialSnapshotTiming='fixture-before.json was recorded before the final normal git status inspection; raw cache metadata is distinct from staged blob/mode semantics',index=git('ls-files','--stage').decode(),status=git('status','--porcelain=v1').decode(),cachedPatch=git('diff','--cached','--binary','--no-ext-diff').decode())
(out/'fixture-semantic-verification.json').write_text(json.dumps(record,indent=2))
# Preserve the original raw receipts. Freeze an additional baseline after the
# explicit checks above for the following locale-only native runs.
(out/'localization-before.json').write_text(json.dumps(after,indent=2))
print(json.dumps(record))

from pathlib import Path
import hashlib,json,os,shutil,subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031'); out=r/'commit-details-remediation-20261102'; f=out/'fixture'
assert not f.exists();f.mkdir()
e=dict(os.environ,GIT_CONFIG_NOSYSTEM='1',GIT_CONFIG_GLOBAL='/dev/null',GIT_AUTHOR_NAME='Zoë 宮崎 العلي',GIT_AUTHOR_EMAIL='long.identity.for.native.details.author@example.invalid',GIT_COMMITTER_NAME='Élodie Committer',GIT_COMMITTER_EMAIL='committer@example.invalid',GIT_AUTHOR_DATE='2026-10-29T09:31:00-07:00',GIT_COMMITTER_DATE='2026-10-30T11:42:00-07:00')
g=str(r/'official-assets/git-runtime/bin/git')
def git(*args,**kw): return subprocess.check_output([g,'-C',str(f),*args],env=e,text=True,**kw).strip()
def write(path,content):
 p=f/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
git('init','--initial-branch=main');git('config','user.name','Casey Committer');git('config','user.email','casey@example.invalid')
original=''.join(f'Line {i:02d}: original review content\n' for i in range(1,61))
write('docs/review.md',original);write('docs/deleted.md','Index content survives a saved working-tree deletion.\n');write('docs/empty.md','');write('README.md','# Native verification fixture\n')
git('add','.');git('commit','-m','Initial documents and comparison endpoints');root=git('rev-parse','HEAD')
git('checkout','-b','feature/grouped-files')
for name in ['.gitignore','dev-notes.iml','misc.xml','modules.xml','vcs.xml']:write('.idea/'+name, '<native>Grouped historical review</native>\n')
write('docs/nested/review.md','# Distinct same basename\n');write('src/nested/review.md','# Another directory\n')
subject='Preserve grouped historical review and independent comparisons with a long subject that remains available in full'
message=subject+'\n\n'+'\n\n'.join(f'Body paragraph {i}: complete metadata remains available through Details while Changed Files keeps its own usable space.' for i in range(1,9))
git('add','.');git('commit','-m',message);ordinary=git('rev-parse','HEAD')
git('checkout','main');write('docs/main-only.md','# Independent main change\n');git('add','.');git('commit','-m','Independent main history');git('merge','--no-ff','feature/grouped-files','-m','Merge grouped historical files for parent-aware review\n\nThe two actual parents remain individually selectable without retargeting open comparisons.');merge=git('rev-parse','HEAD')
git('tag','native-review',ordinary)
# Preserve partially staged and unstaged changes with two distant hunks.
staged=original.replace('Line 03: original','Line 03: staged');working=staged.replace('Line 40: original','Line 40: unstaged')
write('docs/review.md',staged);git('add','docs/review.md');write('docs/review.md',working)
(f/'docs/deleted.md').unlink();write('docs/untracked.md','# Untracked inspection\n')
git('config','remote.origin.url',str(out/'unused-remote.git'));git('config','remote.origin.fetch','+refs/heads/*:refs/remotes/origin/*');git('config','branch.main.remote','origin');git('config','branch.main.merge','refs/heads/main');git('update-ref','refs/remotes/origin/main',root)
git('status','--porcelain=v1')
files={str(p.relative_to(f)):hashlib.sha256(p.read_bytes()).hexdigest() for p in f.rglob('*') if p.is_file() and ('.git' not in p.relative_to(f).parts or p.name in ('HEAD','index','config','packed-refs') or 'refs' in p.relative_to(f).parts)}
(out/'fixture-before.json').write_text(json.dumps(files,indent=2))
(out/'fixture-manifest.json').write_text(json.dumps(dict(head=merge,ordinary=ordinary,root=root,message=message,status=git('status','--porcelain=v1'),parents=git('show','-s','--format=%P',merge)),indent=2))
print(json.dumps(dict(head=merge,ordinary=ordinary,status=git('status','--porcelain=v1'))))

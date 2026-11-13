from pathlib import Path
import hashlib,json,os,shutil,subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
out=r/'sidebar-refinement-20261101'; destination=out/'long-branch-fixture'
assert not destination.exists()
shutil.copytree(out/'fixture',destination)
branch='feature/native-control-consistency-long-branch-name-with-retained-upstream-and-independent-comparison-tabs'
git=str(r/'official-assets/git-runtime/bin/git')
subprocess.run([git,'-C',str(destination),'branch','-m',branch],check=True)
(out/'long-branch-fixture.json').write_text(json.dumps(dict(root=str(destination),branch=branch,
 head=subprocess.check_output([git,'-C',str(destination),'rev-parse','HEAD'],text=True).strip(),
 purpose='Separate task-owned clone for native branch truncation; original fixture unchanged',
 files={str(p.relative_to(destination)):hashlib.sha256(p.read_bytes()).hexdigest() for p in destination.rglob('*') if p.is_file() and '.git' not in p.relative_to(destination).parts}),indent=2))

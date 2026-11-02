from pathlib import Path
import subprocess, json, os, hashlib
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
inputs=root/'inputs'; out=root/'sidebar-refinement-20261101'
env=dict(os.environ, PATH=str(root/'flutter/bin')+':'+os.environ['PATH'],PUB_CACHE=str(root/'pub-cache'))
files={}
for name,base in [('busymark','efa518ce9d07c00cd833fc008efd26d40b1c0b71'),('busyfiles','fc462114014efb478bde0c2cc1eaf3848b108eee')]:
    files[name]=subprocess.check_output(['git','diff','--name-only',base,'HEAD','--','*.dart'],cwd=inputs/name,text=True).splitlines()
files['busystack_git_flutter']=['lib/src/commit_view.dart','lib/src/presentation.dart','lib/src/workflow_ui.dart','test/desktop_interaction_test.dart','test/support/native_presentation_fixture.dart']
results={}
for name,paths in files.items():
 args=['dart','format','--output=none','--set-exit-if-changed',*paths]
 p=subprocess.run(args,cwd=inputs/name,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 results[name]=dict(argv=args,exit=p.returncode,output=p.stdout)
(out/'format-checks.json').write_text(json.dumps(results,indent=2))
print(json.dumps({n:r['exit'] for n,r in results.items()}))
assert all(r['exit']==0 for r in results.values())

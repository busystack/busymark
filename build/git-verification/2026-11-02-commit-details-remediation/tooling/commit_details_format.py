from pathlib import Path
import json
import os
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
inputs=r/'inputs';out=r/'commit-details-remediation-20261102'
env=dict(os.environ,PATH=str(r/'flutter/bin')+':'+os.environ['PATH'],PUB_CACHE=str(r/'pub-cache'))
paths={name:subprocess.check_output(['git','diff','--name-only',base,'HEAD','--','lib/**/*.dart','test/**/*.dart','tools/**/*.dart'],cwd=inputs/name,text=True).splitlines()
       for name,base in [('busymark','8060b052b39c94d5fdb1cf62dcdd49e05e81c74c'),('busyfiles','309a230f59f1e2bd7cc22ab36bd1d65d9353528e')]}
paths['busyfiles']=subprocess.check_output(['git','diff','--name-only','309a230','HEAD','--','*.dart'],cwd=inputs/'busyfiles',text=True).splitlines()
paths['busystack_git_flutter']=['lib/src/commit_details.dart','lib/src/historical_change_tree.dart','lib/src/log_view.dart','lib/src/messages.dart','lib/src/presentation.dart','test/support/native_presentation_fixture.dart','tool/check_native_presentation.dart','tool/test_native_presentation_audit.dart']
results={}
for name,files in paths.items():
    assert files
    argv=['dart','format','--output=none','--set-exit-if-changed',*files]
    p=subprocess.run(argv,cwd=inputs/name,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    results[name]=dict(argv=argv,exit=p.returncode,output=p.stdout)
(out/'format-checks.json').write_text(json.dumps(results,indent=2))
print(json.dumps({n:r['exit'] for n,r in results.items()}))
assert all(r['exit']==0 for r in results.values())

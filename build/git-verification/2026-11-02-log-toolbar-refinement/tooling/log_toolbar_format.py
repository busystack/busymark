from pathlib import Path
import subprocess, json, os, hashlib
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
inputs=root/'inputs'; out=root/'log-toolbar-refinement-20261102'
env=dict(os.environ, PATH=str(root/'flutter/bin')+':'+os.environ['PATH'],PUB_CACHE=str(root/'pub-cache'))
files={}
for name,base in [('busymark','fefb7406e0c85c5a79d6eace4bd2b015cf0c5e98'),('busyfiles','827a44b')]:
    files[name]=subprocess.check_output(['git','diff','--name-only',base,'HEAD','--','*.dart'],cwd=inputs/name,text=True).splitlines()
files['busystack_git_flutter']=['lib/src/branch_views.dart', 'lib/src/diff_view.dart', 'lib/src/historical_change_tree.dart', 'lib/src/host.dart', 'lib/src/log_view.dart', 'lib/src/messages.dart', 'lib/src/presentation.dart', 'lib/src/workflow_ui.dart', 'test/action_destinations_test.dart', 'test/comparison_toolbar_test.dart', 'test/diff_host_localization_test.dart', 'test/diff_search_selection_test.dart', 'test/log_inspector_test.dart', 'test/scaled_workspace_test.dart', 'test/session_and_editor_test.dart', 'test/support/native_presentation_fixture.dart', 'tool/check_native_presentation.dart', 'tool/test_native_presentation_audit.dart']
results={}
for name,paths in files.items():
 args=['dart','format','--output=none','--set-exit-if-changed',*paths]
 p=subprocess.run(args,cwd=inputs/name,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 results[name]=dict(argv=args,exit=p.returncode,output=p.stdout)
(out/'format-checks.json').write_text(json.dumps(results,indent=2))
print(json.dumps({n:r['exit'] for n,r in results.items()}))
assert all(r['exit']==0 for r in results.values())

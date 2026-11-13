from pathlib import Path
import subprocess, json, os, hashlib
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
inputs=root/'inputs'; out=root/'commit-correction-20261101'
env=dict(os.environ, PATH=str(root/'flutter/bin')+':'+os.environ['PATH'],PUB_CACHE=str(root/'pub-cache'))
files={
 'busymark':['lib/src/app/busymark_design.dart','lib/src/app/linux/linux_page_frame.dart','lib/src/git','lib/src/workspace/presentation/workspace_screen.dart','test/src/app_smoke_test.dart','test/src/git','tools/git_ui_audit/bin/check.dart'],
 'busystack_git':['lib/src/models.dart','lib/src/parsers.dart','lib/src/repository_queries.dart','test/tracking_counts_test.dart'],
 'busystack_git_flutter':['lib/src/commit_view.dart','lib/src/presentation.dart','test/commit_amend_draft_test.dart','test/support/native_presentation_fixture.dart','tool/check_native_presentation.dart','tool/test_native_presentation_audit.dart'],
 'busyfiles':['apps/busyfiles_ui/lib/src/app/busyfiles_design.dart','apps/busyfiles_ui/test/git_location_entry_test.dart']}
results={}
for name,paths in files.items():
 args=['dart','format','--output=none','--set-exit-if-changed',*paths]
 p=subprocess.run(args,cwd=inputs/name,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 results[name]=dict(argv=args,exit=p.returncode,output=p.stdout)
(out/'format-checks.json').write_text(json.dumps(results,indent=2))
print(json.dumps({n:r['exit'] for n,r in results.items()}))
assert all(r['exit']==0 for r in results.values())

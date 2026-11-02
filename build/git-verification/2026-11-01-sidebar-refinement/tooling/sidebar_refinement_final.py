import subprocess,time,json
from pathlib import Path
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
out=r/'sidebar-refinement-20261101'
records=[json.loads(x) for x in (out/'commands.jsonl').read_text().splitlines()]
for name in ['shared-tests','shared-real-repositories','mark-host-tests','native-audit-all','mark-audit','mark-l10n-ci','files-l10n-ci']:
 assert any(x['name']==name and x['exit']==0 for x in records), name
subprocess.run(['python3',str(r/'sidebar_refinement_verify.py'),'files-tests'],check=True)
subprocess.run(['python3',str(r/'sidebar_refinement_verify.py'),'refinement-final'],check=True)
subprocess.run(['python3',str(r/'sidebar_refinement_release.py')],check=True)

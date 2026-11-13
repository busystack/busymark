import subprocess
from pathlib import Path
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['setup','audit','mark-final-checks','shared-tests','mark-tests','files-tests']:
 subprocess.run(['python3',str(r/'sidebar_refinement_verify.py'),phase],check=True)

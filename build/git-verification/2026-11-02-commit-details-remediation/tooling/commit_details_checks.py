from pathlib import Path
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['setup','audit','shared-tests','mark-tests','files-tests','format','debug']:
 subprocess.run(['python3',str(r/'commit_details_verify.py'),phase],check=True)

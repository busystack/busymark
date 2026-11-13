from pathlib import Path
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['files-inline-preflight','files-tests','format','files-debug']:
 subprocess.run(['python3',str(r/'log_toolbar_verify.py'),phase],check=True)

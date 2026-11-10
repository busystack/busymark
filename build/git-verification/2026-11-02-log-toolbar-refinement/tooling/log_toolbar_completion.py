from pathlib import Path
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['localized-final','mark-tests','files-tests','format','release']:
 subprocess.run(['python3',str(r/'log_toolbar_verify.py'),phase],check=True)

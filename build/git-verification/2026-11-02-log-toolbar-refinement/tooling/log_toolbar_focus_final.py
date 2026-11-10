from pathlib import Path
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['focus-final','mark-tests','format']:
 subprocess.run(['python3',str(r/'log_toolbar_verify.py'),phase],check=True)

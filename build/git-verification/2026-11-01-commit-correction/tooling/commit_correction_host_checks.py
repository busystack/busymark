from pathlib import Path
import subprocess, sys
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['mark-final-checks','mark-tests','native-tests']:
    subprocess.run([sys.executable,str(root/'commit_correction_verify.py'),phase],check=True)

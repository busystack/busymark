from pathlib import Path
import subprocess, sys
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for phase in ['tool-final-checks','mark-release']:
    subprocess.run([sys.executable,str(root/'commit_correction_verify.py'),phase],check=True)
subprocess.run([sys.executable,str(root/'commit_correction_export.py')],check=True)
subprocess.run([sys.executable,str(root/'commit_correction_verify.py'),'files-release'],check=True)

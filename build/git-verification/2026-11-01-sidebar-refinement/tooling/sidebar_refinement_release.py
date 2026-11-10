from pathlib import Path
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
subprocess.run(['python3',str(r/'sidebar_refinement_verify.py'),'mark-release'],check=True)
subprocess.run(['python3',str(r/'sidebar_refinement_export.py')],check=True)

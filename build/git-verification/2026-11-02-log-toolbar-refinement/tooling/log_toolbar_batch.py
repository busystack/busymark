import subprocess,sys,json
from pathlib import Path
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
for args in json.loads(sys.argv[1]):
 p=subprocess.run(['python3',str(r/'log_toolbar_control.py'),*map(str,args)],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 print(json.dumps(dict(action=args,exit=p.returncode,result=p.stdout)),flush=True)
 if p.returncode:raise SystemExit(p.returncode)

from pathlib import Path
import hashlib,json,os,shutil,subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031'); out=r/'sidebar-refinement-20261101'
def command(*args):
 p=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 return dict(argv=args,exit=p.returncode,output=p.stdout)
state=command('python3',str(r/'sidebar_refinement_control.py'),'status')
processes=json.loads(state['output'])
assert all(v['exit'] is not None for k,v in processes.items() if k.startswith('mark-refinement'))
long=json.loads((out/'long-branch-fixture.json').read_text()); p=Path(long['root'])
actual={str(f.relative_to(p)):hashlib.sha256(f.read_bytes()).hexdigest() for f in p.rglob('*') if f.is_file() and '.git' not in f.relative_to(p).parts}
assert actual==long['files']
assert subprocess.check_output([str(r/'official-assets/git-runtime/bin/git'),'-C',str(p),'rev-parse','HEAD'],text=True).strip()==long['head']
record=dict(processes=processes,longFixtureWorkingFilesUnchanged=True,
 sdkStatus=command('git','-C',str(r/'flutter'),'status','--porcelain','--untracked-files=no'),
 markStatus=command('git','-C',str(r/'inputs/busymark'),'status','--porcelain'),
 filesStatus=command('git','-C',str(r/'inputs/busyfiles'),'status','--porcelain'),
 dpkgAudit=command('dpkg','--audit'),disk=shutil.disk_usage(r)._asdict(),
 systemdBeforeCleanup=command('systemctl','--failed','--no-pager'),
 taskUnitsBeforeCleanup=command('systemctl','show','busystack-git-sidebar-refinement-checks','busystack-git-sidebar-refinement-final','busystack-git-sidebar-refinement-completion','--property=Id,Result,ActiveState'))
assert not record['sdkStatus']['output'] and not record['markStatus']['output'] and not record['filesStatus']['output']
(out/'final-native-state.json').write_text(json.dumps(record,indent=2))
print(json.dumps({k:v for k,v in record.items() if k!='processes'},indent=2))

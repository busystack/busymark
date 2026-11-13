from pathlib import Path
import importlib.util
import json
import shutil
import subprocess

r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
out=r/'commit-details-remediation-20261102';out.mkdir(exist_ok=True)
assert shutil.disk_usage(r).free > 5*1024**3
source=r/'inputs/busymark'
spec=importlib.util.spec_from_file_location('archives',source/'tools/shared_source_archives.py')
archives=importlib.util.module_from_spec(spec);spec.loader.exec_module(archives)
old=json.loads((source/'tool/shared_dependencies.json').read_text())
for dep in old['dependencies']:
    assert archives.tree_digest(r/'inputs'/dep['name'])==dep['tree_sha256']
for name in ['busymark','busyfiles']:
    path=r/'inputs'/name
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=path)
    bundle=r/('commit-details-'+('mark' if name=='busymark' else 'files')+'.bundle')
    subprocess.run(['git','pull','--ff-only',str(bundle),'HEAD'],cwd=path,check=True)
new=json.loads((source/'tool/shared_dependencies.json').read_text())
for dep in new['dependencies']:
    path=r/'inputs'/dep['name']
    if archives.tree_digest(path)==dep['tree_sha256']: continue
    oldRevision=next(x['revision'] for x in old['dependencies'] if x['name']==dep['name'])
    previous=path.with_name(path.name+'-before-commit-details-'+oldRevision[:7])
    assert not previous.exists()
    path.rename(previous)
    archives.materialize(source,dep,path)
    for leaf in ['.dart_tool','build']:
        if (previous/leaf).exists(): (previous/leaf).rename(path/leaf)
receipt=dict(mark=subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip(),
 files=subprocess.check_output(['git','rev-parse','HEAD'],cwd=r/'inputs/busyfiles',text=True).strip(),
 dependencies=new['dependencies'],diskFree=shutil.disk_usage(r).free)
if (out/'source-materialization.json').exists():
    shutil.copyfile(out/'source-materialization.json',out/'source-materialization-initial.json')
(out/'source-materialization.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))

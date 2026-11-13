from pathlib import Path
import importlib.util, json, subprocess, shutil
root=Path('/home/ubuntu/busystack-native-git-verification-20261031')
source=root/'inputs/busymark'
out=root/'sidebar-refinement-20261101'
out.mkdir(exist_ok=True)
assert shutil.disk_usage(root).free >= 3*1024**3
old=json.loads((source/'tool/shared_dependencies.json').read_text())
spec=importlib.util.spec_from_file_location('archives',source/'tools/shared_source_archives.py')
archives=importlib.util.module_from_spec(spec);spec.loader.exec_module(archives)
for dep in old['dependencies']:
    path=root/'inputs'/dep['name']
    assert archives.tree_digest(path)==dep['tree_sha256'], dep['name']
for name in ['busymark','busyfiles']:
    path=root/'inputs'/name
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=path)
    subprocess.run(['git','pull','--ff-only',str(root/('sidebar-refinement-'+('mark' if name=='busymark' else 'files')+'.bundle')),'HEAD'],cwd=path,check=True)
new=json.loads((source/'tool/shared_dependencies.json').read_text())
for dep in new['dependencies']:
    path=root/'inputs'/dep['name']
    if archives.tree_digest(path)!=dep['tree_sha256']:
        oldpath=path.with_name(path.name+'-before-sidebar-refinement')
        assert not oldpath.exists()
        path.rename(oldpath)
        archives.materialize(source,dep,path)
# Reuse only official package/build caches; sources come exclusively from the
# verified new archives. Preserve the previous source tree for incident review.
for dep in new['dependencies']:
    path=root/'inputs'/dep['name']
    oldpath=path.with_name(path.name+'-before-sidebar-refinement')
    for leaf in ['.dart_tool','build']:
        cache=oldpath/leaf
        if cache.exists() and not (path/leaf).exists():
            cache.rename(path/leaf)
receipt=dict(mark=subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip(),
 files=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root/'inputs/busyfiles',text=True).strip(),
 dependencies=new['dependencies'], diskFree=shutil.disk_usage(root).free)
(out/'source-materialization.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))

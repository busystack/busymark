from pathlib import Path
import json,os,shutil,subprocess,time
base=Path('/home/albert/busystack/.native-git-verification')
out=base/'commit-correction-files-production'
out.mkdir(exist_ok=True)
assert shutil.disk_usage(base).free>12*1024**3
sdk=Path('/tmp/busystack-git-flutter-3.47.5').resolve()
env=dict(os.environ,PATH=str(sdk/'bin')+':/usr/bin:/bin',PUB_CACHE=str(base/'audit-pub-cache'),BUSYFILES_FLUTTER_SDK=str(sdk),BUSYFILES_SHARED_DEPENDENCY_CACHE=str(base/'final-inputs'))
start=time.time()
argv=['bash','scripts/build-release-artifacts.sh',str(out/'artifacts')]
log_name='package.log'
if (out/log_name).exists():
    log_name='package-attempt2.log'
with (out/log_name).open('w') as log:
    result=subprocess.run(argv,cwd='/home/albert/busystack/busyfiles',env=env,stdout=log,stderr=subprocess.STDOUT)
(out/('command.json' if log_name=='package.log' else 'command-attempt2.json')).write_text(json.dumps(dict(argv=argv,start=start,end=time.time(),exit=result.returncode,sdk=str(sdk)),indent=2))
raise SystemExit(result.returncode)

from pathlib import Path
import subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031')
namespace={}
exec((r/'commit_details_verify.py').read_text().split("phase=sys.argv[1]")[0],namespace)
namespace['run']('watcher-isolated','busymark','flutter','test','--no-pub','--concurrency=1','test/src/workspace_controller_test.dart','--plain-name','external file moves remap the open document buffer','--machine')
for phase in ['mark-tests','files-tests','format','debug']:
 subprocess.run(['python3',str(r/'commit_details_verify.py'),phase],check=True)

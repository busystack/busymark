from pathlib import Path
import json,subprocess
r=Path('/home/ubuntu/busystack-native-git-verification-20261031');o=r/'log-toolbar-refinement-20261102';native=r/'log-toolbar-refinement-ui'
records=[]
for i in range(12):
 subprocess.run(['python3',str(r/'log_toolbar_control.py'),'native-key','shift+Tab'],check=True,stdout=subprocess.DEVNULL)
 target=o/('native-focus-sidebar-tab-'+str(i)+'.json')
 p=subprocess.run([str(r/'flutter/bin/cache/dart-sdk/bin/dart'),'--packages='+str(r/'inputs/busymark/.dart_tool/package_config.json'),str(r/'log_toolbar_focus.dart'),str(native/'mark-log-toolbar-debug-main.log'),str(target),'creator'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 if p.returncode:raise RuntimeError(p.stdout)
 data=json.loads(target.read_text())['data'];prefix=data
 records.append(dict(index=i,primary=prefix))
 if 'git-selected-commit' in prefix:
  (o/'native-keyboard-focus.json').write_text(json.dumps(dict(selectedCommitReached=True,states=records),indent=2));print(prefix);break
else:
 (o/'native-keyboard-focus.json').write_text(json.dumps(dict(selectedCommitReached=False,states=records),indent=2));raise RuntimeError('Selected commit button not found in native focus traversal; inspect actual focus receipts')
subprocess.run(['python3',str(r/'log_toolbar_batch.py'),json.dumps([['move',600,650],['shot','final-selected-commit-keyboard-focus'],['native-key','Return'],['shot','final-keyboard-history-selector'],['native-key','Escape']])],check=True)

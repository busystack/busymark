from pathlib import Path
import json
import os
import shutil
import socket
import subprocess
import sys
import time

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
out = root/'log-toolbar-refinement-20261102'
native = root/'log-toolbar-refinement-ui'

def run(*argv, cwd=None):
    # Inspect source as its existing owner, just as the build/test runner does.
    # Do not change Git ownership checks or global configuration for a receipt.
    actual = ('runuser', '-u', 'ubuntu', '--', *argv) if os.geteuid() == 0 and argv[0] == 'git' else argv
    p = subprocess.run(actual, cwd=cwd, text=True, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    return dict(argv=argv, exit=p.returncode, output=p.stdout)

phase = sys.argv[1]
units = [
    'busystack-git-log-toolbar-refinement-checks',
    'busystack-git-log-toolbar-watcher-recheck',
    'busystack-git-log-toolbar-refinement-completion',
    'busystack-git-log-toolbar-files-debug',
    'busystack-git-log-toolbar-files-final',
    'busystack-git-log-toolbar-files-release-final',
    'busystack-git-log-toolbar-focus-final',
    'busystack-git-log-toolbar-native',
]
failed = [units[0], units[2], units[5]]
if phase == 'before':
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(str(native/'control.sock'))
        s.sendall(b'{"command":"status"}\n')
        data = b''
        while not data.endswith(b'\n'):
            data += s.recv(1048576)
    processes = json.loads(data)['result']
    active = {k:v for k,v in processes.items() if v['exit'] is None}
    assert not active, active
    receipt = dict(time=time.time(), processes=processes,
                   diskFree=shutil.disk_usage(root).free,
                   dpkgAudit=run('dpkg', '--audit'),
                   failedUnits=run('systemctl', '--failed', '--no-pager'),
                   sdkStatus=run('git', 'status', '--porcelain', cwd=root/'flutter'),
                   sources={name:dict(head=run('git','rev-parse','HEAD',cwd=root/'inputs'/name),
                                      status=run('git','status','--porcelain',cwd=root/'inputs'/name))
                            for name in ('busymark','busyfiles')},
                   units={name:run('systemctl', 'show', name+'.service',
                                   '-p','ActiveState','-p','SubState','-p','Result',
                                   '-p','ExecMainStatus') for name in units})
    for name in units:
        (out/(name+'-journal.log')).write_text(run('journalctl','-u',name+'.service',
                                                 '--no-pager','-o','short-iso')['output'])
    assert not receipt['sdkStatus']['output']
    assert not receipt['dpkgAudit']['output']
    assert not any(s['status']['output'] for s in receipt['sources'].values())
    (out/'environment-before-closure.json').write_text(json.dumps(receipt,indent=2))
elif phase == 'close':
    assert (out/'environment-before-closure.json').exists()
    receipt = dict(time=time.time(),
                   stop=run('systemctl','stop',units[-1]+'.service'),
                   resetOwnRecordedFailures=run('systemctl','reset-failed',
                                                *[u+'.service' for u in failed]),
                   failedUnits=run('systemctl','--failed','--no-pager'),
                   system=run('systemctl','is-system-running'),
                   dpkgAudit=run('dpkg','--audit'),
                   diskFree=shutil.disk_usage(root).free)
    (out/'environment-closure.json').write_text(json.dumps(receipt,indent=2))
    assert receipt['stop']['exit'] == 0
    assert receipt['resetOwnRecordedFailures']['exit'] == 0
    assert receipt['system']['output'].strip() == 'running'
    assert not receipt['dpkgAudit']['output']
else:
    raise SystemExit('Unknown phase')
print(json.dumps(dict(phase=phase,success=True)))

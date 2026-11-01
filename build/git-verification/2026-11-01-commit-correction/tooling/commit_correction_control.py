from pathlib import Path
import hashlib
import json
import os
import shutil
import socket
import subprocess
import sys
import time

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
out = root/'commit-correction-20261101'
native = root/'commit-correction-ui'

def send(command, **kwargs):
    request = dict(command=command, **kwargs)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(30)
        connection.connect(str(native/'control.sock'))
        connection.sendall(json.dumps(request).encode()+b'\n')
        data = b''
        while not data.endswith(b'\n'):
            block = connection.recv(1048576)
            if not block:
                raise RuntimeError('Recorder closed without response')
            data += block
    response = json.loads(data)
    if 'error' in response:
        raise RuntimeError(response)
    return response['result']

def snapshot():
    fixture = out/'fixture'
    return {str(p.relative_to(fixture)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in fixture.rglob('*') if p.is_file() and
            ('.git' not in p.relative_to(fixture).parts or p.name in ('HEAD', 'index', 'config', 'packed-refs') or ('.git' in p.relative_to(fixture).parts and 'refs' in p.relative_to(fixture).parts))}

mode = sys.argv[1]
if mode in ('launch', 'prepare'):
    fixture = out/'fixture'
    if not fixture.exists():
        shutil.copytree(root/'fixtures/review', fixture)
        runtime = str(root/'official-assets/git-runtime/bin/git')
        git_env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL='/dev/null',
            GIT_AUTHOR_NAME='Fixture', GIT_AUTHOR_EMAIL='fixture@example.invalid',
            GIT_COMMITTER_NAME='Fixture', GIT_COMMITTER_EMAIL='fixture@example.invalid')
        def git(*args, input=None):
            return subprocess.check_output([runtime,'-C',str(fixture),*args],env=git_env,input=input,text=True).strip()
        branch = git('branch','--show-current')
        base = git('rev-parse','HEAD^1')
        tree = git('rev-parse',base+'^{tree}')
        remote = git('commit-tree',tree,'-p',base,input='Local remote-tracking fixture commit\n')
        git('config','remote.origin.url',str(out/'unused-remote.git'))
        git('config','remote.origin.fetch','+refs/heads/*:refs/remotes/origin/*')
        git('config','branch.'+branch+'.remote','origin')
        git('config','branch.'+branch+'.merge','refs/heads/main')
        git('update-ref','refs/remotes/origin/main',remote)
        (out/'tracking-fixture.json').write_text(json.dumps(dict(branch=branch,remote=remote,
            locallyKnownCounts=git('rev-list','--left-right','--count','HEAD...refs/remotes/origin/main')),indent=2))
        (out/'fixture-before.json').write_text(json.dumps(snapshot(), indent=2))
    profile = native/'mark-profile'
    settings = profile/'data/io.busystack.busymark/settings.json'
    settings.parent.mkdir(parents=True, exist_ok=True)
    if not settings.exists():
        settings.write_text(json.dumps(dict(autoSave=False, validateOnEdit=False,
            documentViewMode='source', localHistoryCheckpointSeconds=10,
            themeModePreference='light', localeTag='en')))
    if mode == 'launch':
        result = send('launch', name='mark-correction-release', profile=str(profile),
            argv=[str(root/'inputs/busymark/build/linux/x64/release/bundle/busymark'),
                  str(fixture)], environment=dict(GTK_THEME='Yaru-blue', LANG='en_US.UTF-8'))
    else:
        result = dict(profile=str(profile), fixture=str(fixture))
elif mode == 'configure':
    status = send('status')
    if any(name.startswith('mark-correction') and p['exit'] is None for name,p in status.items()):
        raise RuntimeError('Close the task app before changing its own profile')
    settings = native/'mark-profile/data/io.busystack.busymark/settings.json'
    data = json.loads(settings.read_text())
    data.update(localeTag=sys.argv[2], themeModePreference=sys.argv[3])
    settings.write_text(json.dumps(data, ensure_ascii=False))
    with (out/'profile-configurations.jsonl').open('a') as log:
        log.write(json.dumps(dict(time=time.time(), locale=sys.argv[2], theme=sys.argv[3], profile=str(settings)))+'\n')
    result = data
elif mode == 'launch-folder':
    result = send('launch', name='mark-correction-folder', profile=str(native/'mark-profile'),
        argv=[str(root/'inputs/busymark/build/linux/x64/release/bundle/busymark'),sys.argv[2]],
        environment=dict(GTK_THEME='Yaru-blue',LANG='en_US.UTF-8'))
elif mode in ('move','pointerDown','pointerUp'):
    result=send(mode,x=int(sys.argv[2]),y=int(sys.argv[3]))
elif mode == 'tree':
    result = send('tree', name='state-'+str(time.time_ns()))
elif mode == 'debug-main':
    result = send('launch', name='mark-correction-debug-main',
        profile=str(native/'mark-profile'), cwd=str(root/'inputs/busymark'),
        argv=[str(root/'flutter/bin/flutter'), 'run', '-d', 'linux', '--debug',
              '--no-pub', '--dart-entrypoint-args='+str(out/'fixture')],
        environment=dict(GTK_THEME='Yaru-blue', LANG='en_US.UTF-8',
            PUB_CACHE=str(root/'pub-cache'),
            PATH=str(root/'flutter/bin')+':'+str(root/'node/bin')+':'+os.environ['PATH']))
elif mode == 'files-daemon':
    result=send('launch',name='files-correction-daemon',profile='files-profile',
        argv=[str(out/'files-developer-daemon/bundle/bin/busyfilesd'),
              '--socket-path','/tmp/bmcorr-runtime/busyfiles/daemon.sock'],
        environment=dict(BUSYFILES_GIO_LIBRARY=str(root/'inputs/busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so'),
            BUSYSTACK_GIT_EXECUTABLE=str(root/'official-assets/git-runtime/bin/git'),
            BUSYSTACK_GIT_HELPER_PATH=str(root/'official-assets/busystack-git-helper')))
elif mode == 'files-launch':
    result=send('launch',name='files-correction-ui',profile='files-profile',
        argv=[str(root/'inputs/busyfiles/apps/busyfiles_ui/build/linux/x64/release/bundle/busyfiles'),str(out/'fixture/docs')],
        environment=dict(GTK_THEME='Yaru-blue',LANG='en_US.UTF-8',
            BUSYFILES_DAEMON_SOCKET='/tmp/bmcorr-runtime/busyfiles/daemon.sock',
            BUSYFILES_GIO_LIBRARY=str(root/'inputs/busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so')))
elif mode == 'files-engine':
    result=send('mappedEngine',name='files-correction-ui')
elif mode == 'files-receipt':
    status=send('status')
    paths=[root/'inputs/busyfiles/apps/busyfiles_ui/build/linux/x64/release/bundle/busyfiles',
           out/'files-developer-daemon/bundle/bin/busyfilesd',
           root/'inputs/busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so']
    result=dict(source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root/'inputs/busyfiles',text=True).strip(),
        status={n:v for n,v in status.items() if n.startswith('files-correction')},
        files={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
        kind='Final source developer build on Ubuntu 24.04, official release engine; not a production-qualified package',
        ipc='Separate same-user authenticated typed daemon, explicit private runtime socket; no direct UI Git execution')
    (out/'files-native-runtime.json').write_text(json.dumps(result,indent=2))
elif mode == 'files-stop':
    status=send('status')
    daemon=status['files-correction-daemon']
    assert daemon['exit'] is None
    result=send('launch',name='stop-files-daemon',profile='tools',argv=['kill','-TERM',str(daemon['pid'])])
elif mode == 'shot':
    time.sleep(.4) # Let the real application paint after the native input event.
    result = send('screenshot', name=sys.argv[2])
elif mode == 'key':
    result = send('key', keys=sys.argv[2:])
elif mode == 'click':
    name = 'click-'+str(time.time_ns())
    result = send('launch', name=name, profile='tools',
        argv=['xdotool', 'mousemove', '--sync', sys.argv[2], sys.argv[3],
              'mousedown', '1', 'sleep', '.12', 'mouseup', '1'])
    deadline = time.monotonic()+10
    while send('status')[name]['exit'] is None:
        if time.monotonic() >= deadline:
            raise TimeoutError(name)
        time.sleep(.05)
elif mode == 'type':
    name = 'input-'+str(time.time_ns())
    result = send('launch', name=name, profile='tools',
        argv=['xdotool', 'type', '--clearmodifiers', '--delay', '30', sys.argv[2]])
    deadline = time.monotonic()+10
    while send('status')[name]['exit'] is None:
        if time.monotonic() >= deadline:
            raise TimeoutError(name)
        time.sleep(.05)
    time.sleep(1)
elif mode == 'native-key':
    name = 'keys-'+str(time.time_ns())
    result = send('launch', name=name, profile='tools',
        argv=['xdotool', 'key', '--clearmodifiers', '--delay', '150', *sys.argv[2:]])
    deadline = time.monotonic()+10
    while send('status')[name]['exit'] is None:
        if time.monotonic() >= deadline:
            raise TimeoutError(name)
        time.sleep(.05)
    time.sleep(1)
elif mode == 'focus-window':
    result = send('launch', name='focus-'+str(time.time_ns()), profile='tools',
        argv=['xdotool', 'search', '--name', 'BusyMark', 'windowactivate', '--sync'])
    time.sleep(1)
elif mode == 'focus-files':
    result = send('launch', name='focus-files-'+str(time.time_ns()), profile='tools',
        argv=['xdotool','search','--name','BusyFiles','windowactivate','--sync'])
    time.sleep(1)
elif mode == 'status':
    result = send('status')
elif mode == 'engine':
    result = send('mappedEngine', name='mark-correction-release')
elif mode == 'verify-fixture':
    before = json.loads((out/'fixture-before.json').read_text())
    after = snapshot()
    (out/'fixture-after.json').write_text(json.dumps(after, indent=2))
    if before != after:
        raise RuntimeError('Fixture repository bytes changed')
    head = subprocess.check_output([str(root/'official-assets/git-runtime/bin/git'),
        '-C', str(out/'fixture'), 'rev-parse', 'HEAD'], text=True).strip()
    expected = json.loads((root/'fixtures/fixture-manifest.json').read_text())['reviewHead']
    if head != expected:
        raise RuntimeError('Fixture HEAD changed')
    result = dict(unchanged=True, files=len(after), head=head,
        indexSha256=after['.git/index'])
    (out/'fixture-verification.json').write_text(json.dumps(result, indent=2))
else:
    raise SystemExit('Unknown action')
if mode in ('key', 'click', 'launch'):
    time.sleep(1)
print(json.dumps(result, ensure_ascii=False), flush=True)

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
out = root/'commit-details-remediation-20261102'
native = root/'commit-details-remediation-ui'

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

profile_settings=native/'mark-final-profile/data/io.busystack.busymark/settings.json'
profile_theme=json.loads(profile_settings.read_text()).get('themeModePreference') if profile_settings.exists() else 'light'
native_theme='Yaru-blue-dark' if profile_theme=='dark' else 'Yaru-blue'
mode = sys.argv[1]
if mode == 'configure':
    status=send('status')
    if any(n.startswith('mark-commit-details') and p['exit'] is None for n,p in status.items()):
        raise RuntimeError('Close the task application before configuring its profile')
    profile=native/'mark-final-profile'
    settings=profile/'data/io.busystack.busymark/settings.json'
    settings.parent.mkdir(parents=True,exist_ok=True)
    data=json.loads(settings.read_text()) if settings.exists() else dict(autoSave=False,validateOnEdit=False,documentViewMode='source')
    data.update(localeTag=sys.argv[2],themeModePreference=sys.argv[3])
    settings.write_text(json.dumps(data,ensure_ascii=False))
    config=profile/'config';config.mkdir(exist_ok=True)
    scale=sys.argv[4] if len(sys.argv)>4 else '1.0'
    environment=dict(os.environ,GSETTINGS_BACKEND='keyfile',XDG_CONFIG_HOME=str(config))
    subprocess.run(['gsettings','set','org.gnome.desktop.interface','text-scaling-factor',scale],env=environment,check=True)
    actual=subprocess.check_output(['gsettings','get','org.gnome.desktop.interface','text-scaling-factor'],env=environment,text=True).strip()
    result=dict(locale=data['localeTag'],theme=data['themeModePreference'],scale=actual,settings=str(settings),backend='GIO keyfile, private task profile only')
    with (out/'profile-configurations.jsonl').open('a') as f: f.write(json.dumps(result)+'\n')
elif mode == 'launch':
    receipt=json.loads((out/'release-runtime-receipt.json').read_text())
    current=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root/'inputs/busymark',text=True).strip()
    assert receipt['source']==current
    assert hashlib.sha256((root/'inputs/busymark/build/linux/x64/release/bundle/busymark').read_bytes()).hexdigest()==receipt['files']['busymark']
    result=send('launch',name='mark-commit-details-release',profile=str(native/'mark-final-profile'),
        argv=[str(root/'inputs/busymark/build/linux/x64/release/bundle/busymark'),str(out/'fixture')],
        environment=dict(GTK_THEME=native_theme,LANG='en_US.UTF-8',GSETTINGS_BACKEND='keyfile'))
elif mode == 'launch-private-session':
    receipt=json.loads((out/'release-runtime-receipt.json').read_text())
    executable=root/'inputs/busymark/build/linux/x64/release/bundle/busymark'
    assert hashlib.sha256(executable.read_bytes()).hexdigest()==receipt['files']['busymark']
    result=send('launch',name='mark-commit-details-private-release',profile=str(native/'mark-final-profile'),
        argv=['dbus-run-session','--',str(executable),str(out/'fixture')],
        environment=dict(GTK_THEME=native_theme,LANG='en_US.UTF-8',GSETTINGS_BACKEND='keyfile'))
elif mode == 'clipboard':
    result=send('clipboard')
    with (out/'clipboard-observations.jsonl').open('a') as f: f.write(json.dumps(dict(time=time.time(),**result))+'\n')
elif mode == 'secondary':
    result=send('click',x=int(sys.argv[2]),y=int(sys.argv[3]),button=3)
elif mode == 'launch-folder':
    result = send('launch', name='mark-commit-details-folder', profile=str(native/'mark-final-profile'),
        argv=[str(root/'inputs/busymark/build/linux/x64/release/bundle/busymark'),sys.argv[2]],
        environment=dict(GTK_THEME=native_theme,LANG='en_US.UTF-8'))
elif mode in ('move','pointerDown','pointerUp'):
    result=send(mode,x=int(sys.argv[2]),y=int(sys.argv[3]))
elif mode == 'cancel-click':
    name = sys.argv[2]
    process = send('status')[name]
    assert name.startswith('click-') and process['exit'] is None
    result = send('launch', name='cancel-'+name, profile='tools', argv=['kill','-TERM',str(process['pid'])])
elif mode == 'tree':
    result = send('tree', name='state-'+str(time.time_ns()))
elif mode == 'debug-main':
    result = send('launch', name='mark-commit-details-debug-main',
        profile=str(native/'mark-final-profile'), cwd=str(root/'inputs/busymark'),
        argv=[str(root/'flutter/bin/flutter'), 'run', '-d', 'linux', '--debug',
              '--no-pub', '--dart-entrypoint-args='+str(out/'fixture')],
        environment=dict(GTK_THEME=native_theme, LANG='en_US.UTF-8',
            PUB_CACHE=str(root/'pub-cache'),GSETTINGS_BACKEND='keyfile',
            PATH=str(root/'flutter/bin')+':'+str(root/'node/bin')+':'+os.environ['PATH']))
elif mode == 'files-daemon':
    result=send('launch',name='files-log-toolbar-daemon',profile='files-profile',
        argv=[str(out/'files-developer-daemon-final/bundle/bin/busyfilesd'),
              '--socket-path','/tmp/bmlog-runtime/busyfiles/daemon.sock'],
        environment=dict(BUSYFILES_GIO_LIBRARY=str(root/'inputs/busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so'),
            BUSYSTACK_GIT_EXECUTABLE=str(root/'official-assets/git-runtime/bin/git'),
            BUSYSTACK_GIT_HELPER_PATH=str(root/'official-assets/busystack-git-helper')))
elif mode == 'files-launch':
    result=send('launch',name='files-log-toolbar-ui',profile='files-profile',
        argv=[str(root/'inputs/busyfiles/apps/busyfiles_ui/build/linux/x64/debug/bundle/busyfiles'),str(out/'fixture/docs')],
        environment=dict(GTK_THEME=native_theme,LANG='en_US.UTF-8',
            BUSYFILES_DAEMON_SOCKET='/tmp/bmlog-runtime/busyfiles/daemon.sock',
            BUSYFILES_GIO_LIBRARY=str(root/'inputs/busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so')))
elif mode == 'files-engine':
    result=send('mappedEngine',name='files-log-toolbar-ui')
elif mode == 'files-receipt':
    status=send('status')
    paths=[root/'inputs/busyfiles/apps/busyfiles_ui/build/linux/x64/debug/bundle/busyfiles',
           out/'files-developer-daemon-final/bundle/bin/busyfilesd',
           root/'inputs/busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so']
    result=dict(source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root/'inputs/busyfiles',text=True).strip(),
        status={n:v for n,v in status.items() if n.startswith('files-log-toolbar')},
        files={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
        kind='Final source debug build on Ubuntu 24.04, official debug engine; production release gate remains blocked on Ubuntu 26.04 baseline',
        ipc='Separate same-user authenticated typed daemon, explicit private runtime socket; no direct UI Git execution')
    (out/'files-native-runtime.json').write_text(json.dumps(result,indent=2))
elif mode == 'files-stop':
    status=send('status')
    daemon=status['files-log-toolbar-daemon']
    assert daemon['exit'] is None
    result=send('launch',name='stop-files-daemon',profile='tools',argv=['kill','-TERM',str(daemon['pid'])])
elif mode == 'shot':
    time.sleep(2) # Allow modal/native compositor paint before a verification capture.
    result = send('screenshot', name=sys.argv[2])
elif mode == 'resize':
    result=send('launch',name='resize-'+str(time.time_ns()),profile='tools',
        argv=['xdotool','search','--onlyvisible','--name','BusyMark','windowsize','--sync',sys.argv[2],sys.argv[3]])
    time.sleep(1)
elif mode == 'scroll':
    name='scroll-'+str(time.time_ns())
    result=send('launch',name=name,profile='tools',argv=['xdotool','mousemove',sys.argv[2],sys.argv[3],'click','--repeat',sys.argv[4],'--delay','120',sys.argv[5]])
elif mode == 'key':
    result = send('key', keys=sys.argv[2:])
elif mode == 'click':
    name = 'click-'+str(time.time_ns())
    result = send('launch', name=name, profile='tools',
        argv=['xdotool', 'mousemove', sys.argv[2], sys.argv[3],
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
        argv=['xdotool', 'search', '--onlyvisible', '--name', 'BusyMark', 'windowactivate', '--sync'])
    time.sleep(1)
elif mode == 'focus-files':
    result = send('launch', name='focus-files-'+str(time.time_ns()), profile='tools',
        argv=['xdotool','search','--onlyvisible','--name','BusyFiles','windowactivate','--sync'])
    time.sleep(1)
elif mode == 'position':
    result=send('launch',name='position-'+str(time.time_ns()),profile='tools',argv=['xdotool','search','--onlyvisible','--name','BusyMark','windowmove',sys.argv[2],sys.argv[3]])
elif mode == 'window-info':
    result=send('launch',name='window-info-'+str(time.time_ns()),profile='tools',argv=['xdotool','search','--onlyvisible','--name','BusyMark','getwindowgeometry','--shell'])
elif mode == 'status':
    result = send('status')
elif mode == 'engine':
    result = send('mappedEngine', name='mark-commit-details-release')
elif mode == 'verify-localization-fixture':
    before = json.loads((out/'localization-before.json').read_text())
    after = snapshot()
    result = dict(unchanged=before == after, entries=len(after))
    (out/'localization-fixture-verification.json').write_text(json.dumps(result,indent=2))
    assert before == after
elif mode == 'verify-fixture':
    before = json.loads((out/'fixture-before.json').read_text())
    after = snapshot()
    (out/'fixture-after.json').write_text(json.dumps(after, indent=2))
    if before != after:
        raise RuntimeError('Fixture repository bytes changed')
    head = subprocess.check_output([str(root/'official-assets/git-runtime/bin/git'),
        '-C', str(out/'fixture'), 'rev-parse', 'HEAD'], text=True).strip()
    expected = json.loads((out/'fixture-manifest.json').read_text())['head']
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

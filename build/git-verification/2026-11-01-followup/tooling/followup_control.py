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
out = root/'followup-20261101-cf29cd1'
native = root/'final-cf29'

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
            ('.git' not in p.relative_to(fixture).parts or p.name in ('HEAD', 'index'))}

mode = sys.argv[1]
if mode in ('launch', 'prepare'):
    fixture = out/'fixture'
    if not fixture.exists():
        shutil.copytree(root/'fixtures/review', fixture)
        (out/'fixture-before.json').write_text(json.dumps(snapshot(), indent=2))
    profile = native/'mark-profile'
    settings = profile/'data/io.busystack.busymark/settings.json'
    settings.parent.mkdir(parents=True, exist_ok=True)
    if not settings.exists():
        settings.write_text(json.dumps(dict(autoSave=False, validateOnEdit=False,
            documentViewMode='source', localHistoryCheckpointSeconds=10,
            themeModePreference='light', localeTag='en')))
    if mode == 'launch':
        result = send('launch', name='mark-cf29cd1-release', profile=str(profile),
            argv=[str(root/'inputs/busymark/build/linux/x64/release/bundle/busymark'),
                  str(fixture)], environment=dict(GTK_THEME='Yaru-blue', LANG='en_US.UTF-8'))
    else:
        result = dict(profile=str(profile), fixture=str(fixture))
elif mode == 'tree':
    result = send('tree', name='state-'+str(time.time_ns()))
elif mode == 'debug-probe':
    result = send('launch', name='mark-keyboard-probe',
        profile=str(native/'mark-profile'), cwd=str(root/'inputs/busymark'),
        argv=[str(root/'flutter/bin/flutter'), 'run', '-d', 'linux', '--debug',
              '--no-pub', '-t', 'tools/followup_keyboard_probe.dart',
              '--dart-entrypoint-args='+str(out/'fixture')],
        environment=dict(GTK_THEME='Yaru-blue', LANG='en_US.UTF-8',
            PUB_CACHE=str(root/'pub-cache'),
            PATH=str(root/'flutter/bin')+':'+str(root/'node/bin')+':'+os.environ['PATH']))
elif mode == 'debug-main':
    result = send('launch', name='mark-cf29cd1-debug-main',
        profile=str(native/'mark-profile'), cwd=str(root/'inputs/busymark'),
        argv=[str(root/'flutter/bin/flutter'), 'run', '-d', 'linux', '--debug',
              '--no-pub', '--dart-entrypoint-args='+str(out/'fixture')],
        environment=dict(GTK_THEME='Yaru-blue', LANG='en_US.UTF-8',
            PUB_CACHE=str(root/'pub-cache'),
            PATH=str(root/'flutter/bin')+':'+str(root/'node/bin')+':'+os.environ['PATH']))
elif mode == 'pure':
    result = send('launch', name='pure-flutter-release', profile='pure-profile',
        argv=[str(root/'shortcut-probe/build/linux/x64/release/bundle/shortcut_probe')])
elif mode == 'release-probe':
    result = send('launch', name='mark-release-routing-probe', profile=str(native/'mark-profile'),
        argv=[str(root/'inputs/busymark/build/linux/x64/release/bundle/busymark'), str(out/'fixture')])
elif mode == 'shot':
    result = send('screenshot', name=sys.argv[2])
elif mode == 'key':
    result = send('key', keys=sys.argv[2:])
elif mode == 'click':
    result = send('click', x=int(sys.argv[2]), y=int(sys.argv[3]))
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
elif mode == 'status':
    result = send('status')
elif mode == 'engine':
    result = send('mappedEngine', name='mark-cf29cd1-release')
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

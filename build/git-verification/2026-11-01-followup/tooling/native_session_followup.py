#!/usr/bin/env python3
"""Task-owned X11 interaction recorder for the actual unmodified app bundles."""
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import time

import gi
gi.require_version('Gdk', '3.0')
gi.require_version('Atspi', '2.0')
from gi.repository import Gdk, Atspi

ROOT = Path(os.environ.get('BUSYSTACK_NATIVE_SESSION_ROOT', '/home/ubuntu/busystack-git-verification/native-session'))
ROOT.mkdir(exist_ok=True)
RUNTIME = Path(os.environ['BUSYSTACK_NATIVE_RUNTIME_ROOT'])
RUNTIME.mkdir(mode=0o700, exist_ok=True)
SOCKET = ROOT / 'control.sock'
if SOCKET.exists():
    raise SystemExit('Existing recorder socket preserved')
x = C.CDLL('libX11.so.6')
xt = C.CDLL('libXtst.so.6')
x.XOpenDisplay.restype = C.c_void_p
x.XFlush.argtypes = [C.c_void_p]
x.XStringToKeysym.argtypes = [C.c_char_p]
x.XStringToKeysym.restype = C.c_ulong
x.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
x.XKeysymToKeycode.restype = C.c_uint
xt.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
xt.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
xt.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
display = x.XOpenDisplay(None)
if not display:
    raise SystemExit('X11 display unavailable')
subprocess.run(['dbus-update-activation-environment', 'DISPLAY', 'XAUTHORITY',
                'GDK_BACKEND', 'GTK_THEME', 'NO_AT_BRIDGE', 'GTK_MODULES'], check=True)
subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface',
                'toolkit-accessibility', 'true'], check=True)
Gdk.init([])
processes = {}
events = []
event_log = ROOT / ('interactions-' + str(time.time_ns()) + '.json')

def key(name, down):
    code = x.XKeysymToKeycode(display, x.XStringToKeysym(name.encode()))
    if not code:
        raise ValueError('No keycode for ' + name)
    xt.XTestFakeKeyEvent(display, code, int(down), 0)
    x.XFlush(display)

def walk(node, depth=0):
    if depth > 18:
        return []
    try:
        label, role = node.get_name(), node.get_role_name()
        row = {'name': label, 'role': role, 'depth': depth}
        try:
            rect = node.get_component_iface().get_extents(Atspi.CoordType.SCREEN)
            row['rect'] = [rect.x, rect.y, rect.width, rect.height]
        except Exception as error:
            row['geometryError'] = type(error).__name__
        rows = [row] if label else []
        for i in range(min(node.get_child_count(), 500)):
            rows.extend(walk(node.get_child_at_index(i), depth + 1))
        return rows
    except Exception:
        return []

def action(request):
    command = request['command']
    if command == 'launch':
        name = request['name']
        if name in processes and processes[name].poll() is None:
            raise ValueError('Owned process already running')
        profile = ROOT / request['profile']
        for leaf in ('home', 'config', 'data', 'cache', 'state', 'runtime'):
            (profile / leaf).mkdir(parents=True, exist_ok=True, mode=0o700)
        env = dict(os.environ,
                   XDG_CONFIG_HOME=str(profile/'config'), XDG_DATA_HOME=str(profile/'data'),
                   XDG_CACHE_HOME=str(profile/'cache'), XDG_STATE_HOME=str(profile/'state'),
                   XDG_RUNTIME_DIR=str(RUNTIME), GDK_BACKEND='x11',
                   NO_AT_BRIDGE='0', GTK_MODULES='gail:atk-bridge')
        env.update(request.get('environment', {}))
        with (ROOT / (name + '.log')).open('a') as log:
            process = subprocess.Popen(request['argv'], env=env, cwd=request.get('cwd'),
                                       stdout=log, stderr=log)
        processes[name] = process
        return {'pid': process.pid, 'profile': str(profile)}
    if command == 'key':
        names = request['keys']
        for name in names:
            key(name, True)
        for name in reversed(names):
            key(name, False)
    elif command in ('click', 'move', 'scroll'):
        xt.XTestFakeMotionEvent(display, -1, request['x'], request['y'], 0)
        if command != 'move':
            button = request.get('button', 1)
            for _ in range(request.get('count', 1)):
                xt.XTestFakeButtonEvent(display, button, 1, 0)
                xt.XTestFakeButtonEvent(display, button, 0, 0)
        x.XFlush(display)
    elif command == 'screenshot':
        window = Gdk.get_default_root_window()
        pixbuf = Gdk.pixbuf_get_from_window(window, 0, 0, window.get_width(), window.get_height())
        target = ROOT / (request['name'] + '.png')
        pixbuf.savev(str(target), 'png', [], [])
        return {'path': str(target), 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                'width': pixbuf.get_width(), 'height': pixbuf.get_height()}
    elif command == 'tree':
        rows = walk(Atspi.get_desktop(0))
        (ROOT / (request['name'] + '.json')).write_text(json.dumps(rows, indent=2))
        return rows
    elif command == 'status':
        return {name: {'pid': process.pid, 'exit': process.poll()} for name, process in processes.items()}
    elif command == 'mappedEngine':
        process = processes[request['name']]
        rows = [row.split(None, 5) for row in Path(f'/proc/{process.pid}/maps').read_text().splitlines()]
        paths = sorted({row[5] for row in rows if len(row) == 6 and row[5].endswith('/libflutter_linux_gtk.so')})
        if len(paths) != 1:
            raise ValueError('Expected exactly one mapped official engine')
        return {'path': paths[0], 'sha256': hashlib.sha256(Path(paths[0]).read_bytes()).hexdigest()}
    else:
        raise ValueError('Unknown command')
    return {'ok': True}

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(str(SOCKET))
os.chmod(SOCKET, 0o600)
server.listen(1)
subprocess.Popen(['openbox'], stdout=(ROOT/'openbox.log').open('a'), stderr=subprocess.STDOUT)
print(json.dumps({'socket': str(SOCKET), 'display': os.environ['DISPLAY'],
                  'backend': 'X11/Xvfb', 'accessibility': 'enabled', 'time': time.time(),
                  'interactions': str(event_log)}), flush=True)
while True:
    connection, _ = server.accept()
    with connection:
        data = b''
        while not data.endswith(b'\n'):
            block = connection.recv(65536)
            if not block:
                break
            data += block
        try:
            request = json.loads(data)
            result = action(request)
            response = {'result': result}
        except Exception as error:
            response = {'error': repr(error)}
        events.append({'time': time.time(), 'request': request, 'response': response})
        event_log.write_text(json.dumps(events, indent=2))
        connection.sendall(json.dumps(response).encode() + b'\n')

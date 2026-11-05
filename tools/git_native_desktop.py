#!/usr/bin/env python3
"""Private X11 desktop for inspecting the shipping BusyMark executable.

JSON commands on stdin: capture/name, click/x/y/button, key/names, resize/w/h,
move/x/y, close. Images include GTK menus on this owned display.
"""
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from PIL import Image

from application_close_smoke import Desktop, WindowAttributes
from git_native_build_receipt import verify


class XImage(C.Structure):
    _fields_ = [(name, kind) for name, kind in [
        ('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
        ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
        ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
        ('bitmap_pad', C.c_int), ('depth', C.c_int), ('bytes_per_line', C.c_int),
        ('bits_per_pixel', C.c_int), ('red_mask', C.c_ulong),
        ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]]


def geometry(desktop, window):
    attributes = WindowAttributes()
    if not desktop.x.XGetWindowAttributes(desktop.display, window.get_xid(), C.byref(attributes)):
        raise RuntimeError('Cannot read owned native window geometry')
    return attributes.width, attributes.height


def capture(desktop, path, window):
    # Capture the server's actual framebuffer, including native popup windows.
    # GDK's visible-region copying can omit obscured root regions during grabs.
    x = desktop.x
    x.XGetImage.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_ulong, C.c_int]
    x.XGetImage.restype = C.POINTER(XImage)
    x.XDestroyImage.argtypes = [C.POINTER(XImage)]
    native = x.XGetImage(desktop.display, desktop.root, 0, 0, 1600, 1100, C.c_ulong(-1).value, 2)
    if not native:
        raise RuntimeError('X11 framebuffer capture failed')
    try:
        frame = native.contents
        if frame.bits_per_pixel != 32 or frame.byte_order != 0 or (frame.red_mask, frame.green_mask, frame.blue_mask) != (0xff0000, 0xff00, 0xff):
            raise RuntimeError('Unexpected Xvfb pixel format')
        picture = Image.frombytes('RGB', (frame.width, frame.height),
                                 C.string_at(frame.data, frame.bytes_per_line * frame.height),
                                 'raw', 'BGRX', frame.bytes_per_line)
        if len(picture.getcolors(picture.width * picture.height)) < 8:
            raise RuntimeError('Rejected blank native framebuffer capture')
        _, ox, oy = window.get_origin()
        width, height = geometry(desktop, window)
        owned = picture.crop((ox, oy, ox+width, oy+height))
        black = sum(count for count, color in owned.getcolors(owned.width * owned.height) if color == (0, 0, 0))
        if picture.getpixel((ox+10, oy+40)) == (0, 0, 0) or black > owned.width * owned.height / 5:
            raise RuntimeError('Rejected incomplete native framebuffer capture')
        picture.save(path)
    finally:
        x.XDestroyImage(native)


def main():
    binary, output, repository = map(Path, sys.argv[1:4])
    build_receipt = binary.resolve().parent.parent / 'git-native-source.json'
    compiled = json.loads(build_receipt.read_text())
    verify(compiled, binary.resolve())
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    for key in ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR']:
        directory = output / key.lower()
        directory.mkdir(exist_ok=True, mode=0o700)
        env[key] = str(directory.resolve())
    xvfb = subprocess.Popen(['Xvfb', '-displayfd', '1', '-screen', '0', '1600x1100x24', '-nolisten', 'tcp'], stdout=subprocess.PIPE, stderr=(output / 'xvfb.log').open('w'))
    env['DISPLAY'] = ':' + xvfb.stdout.readline().decode().strip()
    env['GDK_BACKEND'] = 'x11'
    env['GSETTINGS_BACKEND'] = 'keyfile'
    env.pop('WAYLAND_DISPLAY', None)
    if not env.get('DBUS_SESSION_BUS_ADDRESS', '').startswith('unix:path=/tmp/'):
        raise RuntimeError('Run inside a dedicated dbus-run-session')
    os.environ.update(env)
    # Supported desktop configuration, scoped to this disposable profile and bus.
    # The official Flutter settings portal reads this same GNOME preference.
    text_scale = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'text-scaling-factor', str(text_scale)], env=env, check=True)
    subprocess.run(['dbus-update-activation-environment', 'DISPLAY', 'GDK_BACKEND', 'GSETTINGS_BACKEND',
                    'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'], env=env, check=True)
    desktop = Desktop()
    desktop.Gdk.init([])
    process = subprocess.Popen([str(binary.resolve()), str(repository.resolve())], env=env, stdout=(output / 'application.log').open('w'), stderr=subprocess.STDOUT)
    def git(*arguments):
        return subprocess.check_output(['git', '-C', str(repository), *arguments], text=True)
    initial_repository = {'status': git('status', '--porcelain=v1'), 'references': git('show-ref')}
    receipt = {'backend': 'X11/Xvfb', 'display': env['DISPLAY'], 'displaySize': [1600, 1100], 'textScale': text_scale,
               'repository': str(repository.resolve()),
               'binarySHA256': hashlib.sha256(binary.read_bytes()).hexdigest(), 'captures': [],
               'compiledSources': compiled, 'sources': {}}
    payloads = [binary.parent / 'data/flutter_assets/kernel_blob.bin', binary.parent / 'lib/libapp.so']
    receipt['applicationPayloads'] = {str(p.relative_to(binary.parent)): hashlib.sha256(p.read_bytes()).hexdigest() for p in payloads if p.exists()}
    for name in ['busymark', 'busystack_git_flutter', 'busystack_git']:
        source = Path(__file__).resolve().parents[2] / name
        source_hash = hashlib.sha256()
        for path in sorted((source / 'lib').rglob('*.dart')):
            source_hash.update(str(path.relative_to(source)).encode() + b'\0' + path.read_bytes())
        receipt['sources'][name] = {
            'dartSourceSHA256': source_hash.hexdigest(),
            'revision': subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip(),
            'state': subprocess.check_output(['git', '-C', str(source), 'status', '--short'], text=True),
        }
    settings = output / 'xdg_data_home/io.busystack.busymark/settings.json'
    if settings.exists():
        config = json.loads(settings.read_text())
        receipt['locale'] = config.get('localeTag')
        receipt['theme'] = config.get('themeModePreference')
    x = desktop.x
    x.XSetInputFocus.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_ulong]
    x.XResizeWindow.argtypes = [C.c_void_p, C.c_ulong, C.c_uint, C.c_uint]
    x.XStringToKeysym.argtypes = [C.c_char_p]
    x.XStringToKeysym.restype = C.c_ulong
    x.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
    x.XKeysymToKeycode.restype = C.c_uint
    xtest = C.CDLL('libXtst.so.6')
    xtest.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
    xtest.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
    xtest.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
    try:
        for _ in range(200):
            window = desktop.window(process.pid, require_normal=True)
            if window:
                break
            if process.poll() is not None:
                raise RuntimeError('Application exited before mapping')
            time.sleep(.1)
        if not window:
            raise RuntimeError('Application did not map')
        x.XSetInputFocus(desktop.display, window.get_xid(), 1, 0)
        x.XFlush(desktop.display)
        time.sleep(2)
        mapped = {line.split()[-1] for line in Path(f'/proc/{process.pid}/maps').read_text().splitlines()
                  if line.endswith('/libflutter_linux_gtk.so')}
        if len(mapped) != 1:
            raise RuntimeError('Expected exactly one mapped official Flutter engine')
        engine = Path(mapped.pop())
        mode = 'linux-x64-release' if 'release' in binary.parts else 'linux-x64'
        sdk = Path(subprocess.check_output(['which', 'flutter'], text=True).strip()).resolve().parent.parent
        expected_engine = sdk / 'bin/cache/artifacts/engine' / mode / 'libflutter_linux_gtk.so'
        actual_hash = hashlib.sha256(engine.read_bytes()).hexdigest()
        expected_hash = hashlib.sha256(expected_engine.read_bytes()).hexdigest()
        receipt['engine'] = {'mapped': str(engine), 'sha256': actual_hash, 'officialSDKArtifact': str(expected_engine), 'matches': actual_hash == expected_hash}
        if actual_hash != expected_hash:
            raise RuntimeError('Mapped engine does not match the official SDK artifact')
        setting = subprocess.run(['gdbus', 'call', '--session', '--dest', 'org.freedesktop.portal.Desktop',
            '--object-path', '/org/freedesktop/portal/desktop', '--method', 'org.freedesktop.portal.Settings.Read',
            'org.gnome.desktop.interface', 'text-scaling-factor'], env=env, capture_output=True, text=True, timeout=10)
        receipt['portalTextScale'] = setting.stdout.strip() if setting.returncode == 0 else setting.stderr.strip()
        print(json.dumps({'pid': process.pid, 'backend': 'X11/Xvfb', 'display': env['DISPLAY'], 'size': geometry(desktop, window), 'scale': 1}), flush=True)
        for line in sys.stdin:
            command = json.loads(line)
            with (output / 'commands.jsonl').open('a') as record:
                record.write(json.dumps(command) + '\n')
            window = desktop.window(process.pid, require_normal=True)
            if not window:
                raise RuntimeError('Owned application window unavailable')
            kind = command['command']
            width, height = geometry(desktop, window)
            if kind in ['move', 'click', 'press', 'release', 'scroll']:
                _, ox, oy = window.get_origin()
                px, py = command['x'], command['y']
                if not 0 <= px < width or not 0 <= py < height:
                    raise ValueError('Input outside owned window')
                xtest.XTestFakeMotionEvent(desktop.display, 0, ox + px, oy + py, 0)
                x.XFlush(desktop.display)
                time.sleep(.15)
                if kind == 'scroll':
                    steps = min(max(int(command.get('steps', 1)), 1), 200)
                    button = 5 if command.get('direction') == 'down' else 4
                    for _ in range(steps):
                        for state in [1, 0]:
                            xtest.XTestFakeButtonEvent(desktop.display, button, state, 2)
                elif kind != 'move':
                    for state in ([1, 0] if kind == 'click' else [1] if kind == 'press' else [0]):
                        xtest.XTestFakeButtonEvent(desktop.display, command.get('button', 1), state, 0)
            elif kind == 'key':
                codes = [x.XKeysymToKeycode(desktop.display, x.XStringToKeysym(s.encode())) for s in command['names']]
                if not all(codes):
                    raise ValueError('Unknown key')
                for code, state in [(c, 1) for c in codes] + [(c, 0) for c in reversed(codes)]:
                    xtest.XTestFakeKeyEvent(desktop.display, code, state, 0)
            elif kind == 'resize':
                x.XResizeWindow(desktop.display, window.get_xid(), command['width'], command['height'])
            elif kind == 'capture':
                time.sleep(1)
                # Request an ordinary native exposure before reading the frame.
                # This private Xvfb desktop has no compositing window manager.
                x.XClearArea.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_int]
                x.XClearArea(desktop.display, window.get_xid(), 0, 0, 0, 0, 1)
                x.XFlush(desktop.display)
                time.sleep(.5)
                # A resize can reach X11 before GTK has supplied the new GL
                # frame. Wait for a complete real framebuffer; never save the
                # cleared intermediate surface as acceptance evidence.
                for attempt in range(10):
                    try:
                        capture(desktop, output / (command['name'] + '.png'), window)
                        break
                    except RuntimeError as error:
                        if str(error) != 'Rejected incomplete native framebuffer capture' or attempt == 9:
                            raise
                        time.sleep(1)
                receipt['captures'].append({'name': command['name'], 'windowSize': geometry(desktop, window), 'scale': window.get_scale_factor()})
                (output / 'receipt.json').write_text(json.dumps(receipt, indent=2))
            elif kind == 'text':
                for char in command['value']:
                    symbol = {'.': 'period', '/': 'slash'}.get(char, char)
                    code = x.XKeysymToKeycode(desktop.display, x.XStringToKeysym(symbol.encode()))
                    if not code or not char.isascii() or not (char.islower() or char.isdigit() or char in './'):
                        raise ValueError('Text command only accepts ASCII search queries and numeric dates')
                    for state in [1, 0]:
                        xtest.XTestFakeKeyEvent(desktop.display, code, state, 10)
            elif kind == 'wait':
                time.sleep(min(command.get('seconds', 1), 10))
            elif kind == 'close':
                desktop.close(window)
                print(json.dumps({'done': command}), flush=True)
                break
            else:
                raise ValueError('Unknown command')
            x.XFlush(desktop.display)
            time.sleep(.35)
            print(json.dumps({'done': command}), flush=True)
        try:
            process.wait(timeout=15)
            receipt['naturalExit'] = process.returncode == 0
        except subprocess.TimeoutExpired:
            print(json.dumps({'naturalExit': False}), flush=True)
            process.terminate()
            process.wait(timeout=10)
            receipt['naturalExit'] = False
        receipt['repositoryUnchanged'] = initial_repository == {'status': git('status', '--porcelain=v1'), 'references': git('show-ref')}
        (output / 'receipt.json').write_text(json.dumps(receipt, indent=2))
    finally:
        if process.poll() is None:
            try:
                owned_window = desktop.window(process.pid, require_normal=True)
                if owned_window:
                    desktop.close(owned_window)
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=10)
        desktop.dispose()
        xvfb.terminate()
        xvfb.wait(timeout=10)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Private X11 desktop for inspecting either shipping BusyStack Git host.

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


def require_installed_busyfiles(binary, compiled, env):
    """An installed acceptance request must use the actual system package paths."""
    if Path(binary).resolve() != Path('/usr/lib/busyfiles/busyfiles'):
        raise RuntimeError('Installed acceptance requires /usr/lib/busyfiles/busyfiles')
    if compiled.get('provenance', {}).get('installedRoot') != '/':
        raise RuntimeError('Installed acceptance requires a system-root package receipt')
    if env.get('LD_LIBRARY_PATH') or env.get('BUSYSTACK_NATIVE_DAEMON'):
        raise RuntimeError('Installed acceptance cannot override native library or daemon paths')


def configure_native_text_dpi(env, text_scale):
    # GSettings feeds Flutter's settings portal. GTK's X11 menus additionally
    # consume Xft DPI; an isolated Xvfb has no desktop XSettings publisher.
    # Publish the supported X11 resource so both native and Flutter text scale.
    subprocess.run(['xrdb', '-merge'], input=f'Xft.dpi: {96 * text_scale:g}\n',
                   text=True, env=env, check=True)


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
    build_receipt = Path(os.environ.get('BUSYSTACK_NATIVE_RECEIPT',
                         str(binary.resolve().parent.parent / 'git-native-source.json')))
    compiled = json.loads(build_receipt.read_text())
    native_host = compiled.get('host', 'busymark')
    if native_host not in {'busymark', 'busyfiles'}:
        raise RuntimeError('Unsupported native acceptance host')
    verify(compiled, binary.resolve())
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    for key in ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR']:
        directory = output / key.lower()
        directory.mkdir(exist_ok=True, mode=0o700)
        env[key] = str(directory.resolve())
    import tempfile
    private_runtime = tempfile.TemporaryDirectory(prefix='bsg-native-')
    def cleanup_runtime():
        # Only these mounts can have been created beneath this invocation's
        # private runtime. Activated portal/GVfs services may outlive the UI.
        # Unmount them through the supported owner interface before removing
        # the directory; never touch the user's desktop mounts.
        for name in ['doc', 'gvfs']:
            mount = Path(private_runtime.name) / name
            if os.path.ismount(mount):
                subprocess.run(['fusermount3', '--unmount', str(mount)], check=True)
        private_runtime.cleanup()
    env['XDG_RUNTIME_DIR'] = private_runtime.name
    env.pop('GNOME_KEYRING_CONTROL', None)
    env.pop('SSH_AUTH_SOCK', None)
    if native_host == 'busyfiles':
        for suffix in ['CONFIG_HOME', 'DATA_HOME', 'CACHE_HOME', 'STATE_HOME', 'RUNTIME_DIR']:
            env['BUSYFILES_XDG_' + suffix] = env['XDG_' + suffix]
        env['BUSYFILES_DAEMON_SOCKET'] = private_runtime.name + '/daemon.sock'
    xvfb = subprocess.Popen(['Xvfb', '-displayfd', '1', '-noreset', '-screen', '0', '1600x1100x24', '-nolisten', 'tcp'], stdout=subprocess.PIPE, stderr=(output / 'xvfb.log').open('w'))
    env['DISPLAY'] = ':' + xvfb.stdout.readline().decode().strip()
    env['GDK_BACKEND'] = 'x11'
    env['GSETTINGS_BACKEND'] = 'keyfile'
    env.pop('WAYLAND_DISPLAY', None)
    if not env.get('DBUS_SESSION_BUS_ADDRESS', '').startswith('unix:path=/tmp/'):
        raise RuntimeError('Run inside a dedicated dbus-run-session')
    control = Path(private_runtime.name) / 'keyring'
    control.mkdir(mode=0o700)
    env['GNOME_KEYRING_CONTROL'] = str(control)
    os.environ.pop('SSH_AUTH_SOCK', None)
    os.environ.pop('GNOME_KEYRING_CONTROL', None)
    os.environ.update(env)
    # Activated services must receive the private paths before the first GTK or
    # GSettings call can start them. Use a disposable Secret Service in both
    # hosts so the desktop portal cannot attach to a personal keyring.
    subprocess.run(['dbus-update-activation-environment', 'DISPLAY', 'GDK_BACKEND', 'GSETTINGS_BACKEND',
                    'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR',
                    'GNOME_KEYRING_CONTROL'], env=env, check=True)
    keyring_env = dict(env)
    keyring_env.pop('HOME', None)
    keyring_env.pop('GNOME_KEYRING_CONTROL', None)
    subprocess.run(['gnome-keyring-daemon', '--unlock', '--components=secrets',
                    '--control-directory='+str(control)], input='\n', text=True,
                   env=keyring_env, stdout=(output/'keyring.log').open('w'), check=True)
    # Supported desktop configuration, scoped to this disposable profile and bus.
    # The official Flutter settings portal reads this same GNOME preference.
    text_scale = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'text-scaling-factor', str(text_scale)], env=env, check=True)
    configure_native_text_dpi(env, text_scale)
    requested_theme = os.environ.get('BUSYSTACK_NATIVE_THEME')
    if requested_theme is not None:
        if requested_theme not in {'light', 'dark'}: raise ValueError('Expected light or dark native theme')
        subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'color-scheme',
                        'prefer-dark' if requested_theme == 'dark' else 'default'], env=env, check=True)
        subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'gtk-theme',
                        'Yaru-dark' if requested_theme == 'dark' else 'Yaru'], env=env, check=True)
        env['GTK_THEME'] = 'Yaru-dark' if requested_theme == 'dark' else 'Yaru'

    subprocess.run(['dbus-update-activation-environment', 'DISPLAY', 'GDK_BACKEND', 'GSETTINGS_BACKEND',
                    'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'], env=env, check=True)
    desktop = Desktop()
    desktop.Gdk.init([])
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk
    gtk_settings = Gtk.Settings.get_default()
    gtk_metrics = {key: gtk_settings.get_property(key) for key in
                   ['gtk-font-name', 'gtk-xft-dpi', 'gtk-theme-name']}
    if abs(gtk_metrics['gtk-xft-dpi'] / 1024 - 96 * text_scale) > .1:
        desktop.dispose(); xvfb.terminate(); xvfb.wait(timeout=10)
        cleanup_runtime()
        raise RuntimeError('Native GTK text DPI differs from the requested acceptance scale')
    daemon = None
    daemon_launch = None
    daemon_log = None
    def start_daemon():
        launched = subprocess.Popen(*daemon_launch[0], **daemon_launch[1])
        for _ in range(600):
            if Path(env['BUSYFILES_DAEMON_SOCKET']).exists(): return launched
            if launched.poll() is not None:
                raise RuntimeError('Owned daemon exited before readiness; inspect daemon.log')
            time.sleep(.1)
        launched.terminate()
        launched.wait(timeout=15)
        raise RuntimeError('Owned daemon readiness timed out; inspect daemon.log')
    try:
        if native_host == 'busyfiles':
            if os.environ.get('BUSYSTACK_NATIVE_REQUIRE_INSTALLED') == '1':
                require_installed_busyfiles(binary, compiled, env)
            # Official development bundles and the installed DEB have explicit
            # different system-service paths. Never substitute a system Git or
            # a development daemon for a requested installed acceptance run.
            installed = binary.resolve().parent.name == 'busyfiles' and binary.resolve().parent.parent.name == 'lib'
            prefix = binary.resolve().parent.parent.parent
            helper_dir = prefix / 'libexec/busyfiles' if installed else binary.parent / 'libexec/busyfiles'
            gio_library = prefix / 'lib/libbusyfiles_gio.so.0' if installed else binary.parent / 'lib/libbusyfiles_gio.so.0'
            for artifact in [gio_library, helper_dir / 'busystack-git-helper', binary.parent / 'libexec/git-runtime/bin/git']:
                if not artifact.is_file():
                    raise RuntimeError('Required product runtime artifact is missing: ' + str(artifact))
            if installed:
                # Exercise the daemon's actual installed discovery paths.
                # Explicit development paths would conceal a packaging defect.
                env.pop('BUSYFILES_GIO_LIBRARY', None)
                env.pop('BUSYSTACK_GIT_EXECUTABLE', None)
                env.pop('BUSYSTACK_GIT_HELPER_PATH', None)
                env.pop('SNAP', None)
            else:
                env['BUSYFILES_GIO_LIBRARY'] = str(gio_library.resolve())
                env['BUSYSTACK_GIT_EXECUTABLE'] = str(binary.parent / 'libexec/git-runtime/bin/git')
                env['BUSYSTACK_GIT_HELPER_PATH'] = str(helper_dir / 'busystack-git-helper')
            workspace = Path(compiled.get('workspace', Path(__file__).resolve().parents[2]))
            daemon_binary = Path(os.environ.get('BUSYSTACK_NATIVE_DAEMON', str(helper_dir/'busyfilesd' if installed else binary.parent/'busyfilesd')))
            daemon_log = (output/'daemon.log').open('w')
            if daemon_binary.is_file():
                arguments = [str(daemon_binary.resolve()), '--socket-path', env['BUSYFILES_DAEMON_SOCKET']]
                daemon_identity = {'mode': 'packaged executable', 'path': str(daemon_binary.resolve()),
                                   'sha256': hashlib.sha256(daemon_binary.read_bytes()).hexdigest()}
            else:
                if installed or os.environ.get('BUSYSTACK_NATIVE_REQUIRE_INSTALLED') == '1':
                    raise RuntimeError('Installed acceptance requires the actual packaged daemon')
                sdk = Path(subprocess.check_output(['which', 'flutter'], text=True).strip()).resolve().parent.parent
                arguments = [str(sdk/'bin/cache/dart-sdk/bin/dart'), 'run', 'apps/busyfilesd/bin/busyfilesd.dart',
                             '--socket-path', env['BUSYFILES_DAEMON_SOCKET']]
                daemon_identity = {'mode': 'development source through official Dart', 'source': str(workspace/'busyfiles')}
            daemon_launch = ([arguments], {'cwd': str(workspace/'busyfiles'), 'env': env,
                              'stdout': daemon_log, 'stderr': subprocess.STDOUT})
            daemon = start_daemon()
            daemon_identity['pid'] = daemon.pid
        process = subprocess.Popen([str(binary.resolve()), str(repository.resolve())], env=env,
                                   stdout=(output / 'application.log').open('w'), stderr=subprocess.STDOUT)
    except BaseException:
        if daemon is not None and daemon.poll() is None:
            daemon.terminate(); daemon.wait(timeout=15)
        desktop.dispose(); xvfb.terminate(); xvfb.wait(timeout=10)
        cleanup_runtime()
        raise
    def git(*arguments):
        return subprocess.check_output([str(binary.parent / 'libexec/git-runtime/bin/git'), '-C', str(repository), *arguments], text=True)
    plain_directory = env.get('BUSYSTACK_NATIVE_PLAIN_DIRECTORY') == '1'
    def fixture_state():
        if not plain_directory:
            return {'status': git('status', '--porcelain=v1'), 'references': git('show-ref')}
        probe = subprocess.run([str(binary.parent/'libexec/git-runtime/bin/git'), '-C', str(repository),
                                'rev-parse', '--git-dir'], capture_output=True, text=True,
                               env=dict(env, LC_ALL='C'))
        if probe.returncode != 128 or 'not a git repository' not in probe.stderr:
            raise RuntimeError('Plain-directory acceptance requires a real non-repository fixture')
        return {'kind': 'plain directory', 'files': {
            str(p.relative_to(repository)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(repository.rglob('*')) if p.is_file()}}
    initial_repository = fixture_state()
    receipt = {'backend': 'X11/Xvfb', 'display': env['DISPLAY'], 'displaySize': [1600, 1100], 'textScale': text_scale,
               'repository': str(repository.resolve()),
               'binarySHA256': hashlib.sha256(binary.read_bytes()).hexdigest(), 'captures': [],
               'compiledSources': compiled, 'sources': {}}
    receipt['nativeLibrarySearchPath'] = env.get('LD_LIBRARY_PATH', '')
    if native_host == 'busyfiles':
        receipt['runtimeLayout'] = (
            'system-installed DEB' if binary.resolve() == Path('/usr/lib/busyfiles/busyfiles')
            and compiled.get('provenance', {}).get('installedRoot') == '/'
            else 'relocated DEB payload' if installed else 'development bundle'
        )
    receipt['gtkTextMetrics'] = gtk_metrics
    receipt['fixtureKind'] = 'plain directory' if plain_directory else 'Git repository'
    payloads = [binary.parent / 'data/flutter_assets/kernel_blob.bin', binary.parent / 'lib/libapp.so']
    receipt['applicationPayloads'] = {str(p.relative_to(binary.parent)): hashlib.sha256(p.read_bytes()).hexdigest() for p in payloads if p.exists()}
    receipt['sources'] = compiled['sources']
    receipt['host'] = native_host
    if requested_theme is not None: receipt['theme'] = requested_theme
    if daemon is not None: receipt['daemon'] = daemon_identity
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
        mode = 'linux-x64' if (binary.parent/'data/flutter_assets/kernel_blob.bin').exists() else 'linux-x64-release'
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
                        if kind == 'click' and state == 1:
                            # Give GTK distinct native press/release events.
                            x.XFlush(desktop.display)
                            time.sleep(.08)
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
                # Read-only observation: do not clear or repaint the target.
                # Keep strict incomplete/blank frame rejection below.
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
            elif kind in {'daemonStop', 'daemonRestart'}:
                if daemon is None or daemon.poll() is not None:
                    raise ValueError('This host has no running owned daemon')
                previous = daemon.pid
                daemon.terminate(); daemon.wait(timeout=15)
                if Path(env['BUSYFILES_DAEMON_SOCKET']).exists():
                    raise RuntimeError('Owned daemon left a stale socket after normal shutdown')
                receipt.setdefault('daemonStops', []).append(previous)
                if kind == 'daemonRestart':
                    daemon = start_daemon()
                    receipt.setdefault('daemonRestarts', []).append({'previousPID': previous, 'newPID': daemon.pid})
            elif kind == 'daemonStart':
                if daemon is None or daemon.poll() is None:
                    raise ValueError('An owned stopped daemon is required')
                previous = daemon.pid
                daemon = start_daemon()
                receipt.setdefault('daemonRestarts', []).append({'previousPID': previous, 'newPID': daemon.pid})
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
        verify(compiled, binary.resolve())
        receipt['repositoryUnchanged'] = initial_repository == fixture_state()
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
        if daemon is not None:
            if daemon.poll() is None: daemon.terminate()
            receipt['daemonExitCode'] = daemon.wait(timeout=15)
            (output/'receipt.json').write_text(json.dumps(receipt, indent=2))
        if daemon_log is not None: daemon_log.close()
        desktop.dispose()
        xvfb.terminate()
        xvfb.wait(timeout=10)
        try:
            cleanup_runtime()
        except BaseException:
            receipt['runtimeCleanup'] = False
            (output/'receipt.json').write_text(json.dumps(receipt, indent=2))
            raise
        receipt['runtimeCleanup'] = True
        (output/'receipt.json').write_text(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()

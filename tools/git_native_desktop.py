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


def owned_accessible_nodes(desktop, pid):
    """Inspect only accessibility peers belonging to the launched application."""
    roots = [desktop.get_child_at_index(i) for i in range(desktop.get_child_count())]
    pending = [(node, 0) for node in roots if node.get_process_id() == pid]
    result = []
    while pending:
        node, depth = pending.pop()
        if len(result) >= 5000:
            raise RuntimeError('Owned accessibility tree exceeded the inspection bound')
        node.clear_cache()
        result.append(node)
        if depth < 30:
            pending.extend((node.get_child_at_index(i), depth + 1)
                           for i in range(min(node.get_child_count(), 500)))
    if not result:
        raise RuntimeError('Owned application has no AT-SPI accessibility peer')
    return result


def seed_private_preferences(env, values):
    """Use normal product preferences in this invocation's disposable profile."""
    if (not isinstance(values, dict) or set(values) - {'autoSave', 'localeTag', 'themeModePreference'}
            or ('autoSave' in values and not isinstance(values['autoSave'], bool))
            or ('localeTag' in values and not isinstance(values['localeTag'], str))
            or ('themeModePreference' in values and values['themeModePreference'] not in {'system', 'light', 'dark'})):
        raise ValueError('Only ordinary locale, theme and autosave preferences may be seeded')
    target = Path(env['XDG_DATA_HOME']) / 'io.busystack.busymark/settings.json'
    if target.exists():
        raise RuntimeError('Refusing to overwrite existing application preferences')
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open('x') as output:
        json.dump(values, output)
    return target


def native_launch_arguments(binary, repository, env, snap_app=None):
    binary, repository = Path(binary).resolve(), Path(repository).resolve()
    if snap_app is None:
        return [str(binary), str(repository)]
    if snap_app != 'busymark' or not binary.is_relative_to('/snap/busymark') or binary.name != 'busymark':
        raise RuntimeError('Snap acceptance requires the installed BusyMark payload')
    if not env.get('DBUS_SESSION_BUS_ADDRESS', '').startswith('unix:abstract=/tmp/dbus-bsg-native-'):
        raise RuntimeError('Snap acceptance requires the owned private abstract session bus')
    # snap run --shell retains confinement and executes the normal command-chain.
    # Set only the isolated profile/display after its metadata XDG overrides.
    # Values are argv entries, never interpolated into shell source.
    keys = ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME',
            'XDG_RUNTIME_DIR', 'DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'GDK_BACKEND',
            'GSETTINGS_BACKEND', 'GTK_THEME', 'NO_AT_BRIDGE', 'GTK_MODULES',
            'GNOME_KEYRING_CONTROL']
    values = [key+'='+env[key] for key in keys if key in env]
    values.append('BUSYMARK_SPELLING_INSTALL_ROOT='+str(Path(env['XDG_DATA_HOME'])/'spelling'))
    return ['snap', 'run', '--shell', 'busymark', '-c',
            'exec env -u WAYLAND_DISPLAY -u SSH_AUTH_SOCK -u BUSYSTACK_GIT_EXECUTABLE -u BUSYSTACK_GIT_HELPER_PATH -- "$@"', 'busystack-native-acceptance',
            *values, str(binary), str(repository)]


def git_fixture_state(executable, repository):
    """Read exact Git-visible bytes without refreshing or changing the index."""
    env = dict(os.environ, GIT_OPTIONAL_LOCKS='0')
    for key in ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE']:
        env.pop(key, None)
    prefix = [str(executable), '--no-optional-locks', '-C', str(repository)]
    def read(*args):
        return subprocess.check_output(prefix+list(args), env=env)
    refs = subprocess.run(prefix+['show-ref'], env=env, capture_output=True)
    if refs.returncode not in [0, 1]:
        refs.check_returncode()
    index = Path(os.fsdecode(read('rev-parse', '--path-format=absolute', '--git-path', 'index')).strip())
    files = {}
    paths = read('ls-files', '--cached', '--others', '--exclude-standard', '-z')
    for raw in sorted(set(p for p in paths.split(b'\0') if p)):
        name = os.fsdecode(raw)
        path = Path(repository)/name
        if path.is_symlink():
            data, kind = os.fsencode(os.readlink(path)), 'symlink'
        elif path.is_file():
            data, kind = path.read_bytes(), 'file'
        else:
            files[name] = {'kind': 'directory/gitlink' if path.is_dir() else 'absent'}
            continue
        files[name] = {'kind': kind, 'sha256': hashlib.sha256(data).hexdigest(),
                       'mode': oct(path.lstat().st_mode & 0o7777)}
    return {'status': read('status', '--porcelain=v1').decode(),
            'references': refs.stdout.decode(),
            'indexSHA256': hashlib.sha256(index.read_bytes()).hexdigest() if index.is_file() else None,
            'gitVisibleWorkingFiles': files}


def plain_directory_state(executable, repository):
    env = dict(os.environ, LC_ALL='C', GIT_OPTIONAL_LOCKS='0')
    for key in ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE']:
        env.pop(key, None)
    probe = subprocess.run([str(executable), '--no-optional-locks', '-C', str(repository),
                            'rev-parse', '--git-dir'], capture_output=True, text=True, env=env)
    if probe.returncode != 128 or 'not a git repository' not in probe.stderr:
        raise RuntimeError('Plain-directory acceptance requires a real non-repository fixture')
    files = {}
    for path in sorted(Path(repository).rglob('*')):
        if path.is_symlink():
            data = os.fsencode(os.readlink(path))
        elif path.is_file():
            data = path.read_bytes()
        else:
            continue
        files[str(path.relative_to(repository))] = hashlib.sha256(data).hexdigest()
    return {'kind': 'plain directory', 'files': files}


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
    binary, output, repository = (Path(value).resolve() for value in sys.argv[1:4])
    build_receipt = Path(os.environ.get('BUSYSTACK_NATIVE_RECEIPT',
                         str(binary.resolve().parent.parent / 'git-native-source.json')))
    compiled = json.loads(build_receipt.read_text())
    native_host = compiled.get('host', 'busymark')
    if native_host not in {'busymark', 'busyfiles'}:
        raise RuntimeError('Unsupported native acceptance host')
    verify(compiled, binary.resolve())
    # Establish the read-only baseline before starting any native resources or
    # the application. A failed fixture check therefore cannot leak processes.
    plain_directory = os.environ.get('BUSYSTACK_NATIVE_PLAIN_DIRECTORY') == '1'
    state_reader = plain_directory_state if plain_directory else git_fixture_state
    def fixture_state():
        return state_reader(binary.parent/'libexec/git-runtime/bin/git', repository)
    initial_repository = fixture_state()
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    snap_app = env.get('BUSYSTACK_NATIVE_SNAP_APP')
    import tempfile
    if snap_app is not None:
        if snap_app != 'busymark' or native_host != 'busymark':
            raise RuntimeError('Unsupported installed Snap host')
        parent = Path.home() / 'snap/busymark/common'
        parent.mkdir(parents=True, exist_ok=True)
        private_runtime = tempfile.TemporaryDirectory(prefix='bsg-native-', dir=parent)
        profile = Path(private_runtime.name)
        for key in ['BASH_ENV', 'ENV', 'BUSYSTACK_GIT_EXECUTABLE', 'BUSYSTACK_GIT_HELPER_PATH']:
            env.pop(key, None)
    else:
        private_runtime = tempfile.TemporaryDirectory(prefix='bsg-native-')
        profile = output
    for key in ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR']:
        directory = profile / key.lower()
        directory.mkdir(exist_ok=True, mode=0o700)
        env[key] = str(directory.resolve())
    def cleanup_runtime():
        # Unmount only this invocation's own portal/GVfs mounts, then discard
        # its private profile. Never remove another Snap profile or user mount.
        for name in ['doc', 'gvfs']:
            mount = Path(private_runtime.name) / name
            if os.path.ismount(mount):
                subprocess.run(['fusermount3', '--unmount', str(mount)], check=True)
        private_runtime.cleanup()
    env['XDG_RUNTIME_DIR'] = private_runtime.name
    seeded_preferences = None
    if env.get('BUSYSTACK_NATIVE_APP_SETTINGS'):
        if native_host != 'busymark':
            cleanup_runtime()
            raise ValueError('BusyMark preferences cannot be applied to another host')
        seeded_preferences = json.loads(Path(env['BUSYSTACK_NATIVE_APP_SETTINGS']).read_text())
        seed_private_preferences(env, seeded_preferences)
    env.pop('GNOME_KEYRING_CONTROL', None)
    env.pop('SSH_AUTH_SOCK', None)
    if native_host == 'busyfiles':
        for suffix in ['CONFIG_HOME', 'DATA_HOME', 'CACHE_HOME', 'STATE_HOME', 'RUNTIME_DIR']:
            env['BUSYFILES_XDG_' + suffix] = env['XDG_' + suffix]
        env['BUSYFILES_DAEMON_SOCKET'] = private_runtime.name + '/daemon.sock'
    xvfb = subprocess.Popen(['Xvfb', '-displayfd', '1', '-noreset', '-screen', '0', '1600x1100x24', '-nolisten', 'tcp'], stdout=subprocess.PIPE, stderr=(output / 'xvfb.log').open('w'))
    env['DISPLAY'] = ':' + xvfb.stdout.readline().decode().strip()
    env['GDK_BACKEND'] = 'x11'
    # Actual Git accessibility acceptance uses the supported GTK bridge on this
    # private bus. Never disable accessibility to obtain a screenshot pass.
    env['NO_AT_BRIDGE'] = '0'
    env['GTK_MODULES'] = 'gail:atk-bridge'
    env['GSETTINGS_BACKEND'] = 'keyfile'
    env.pop('WAYLAND_DISPLAY', None)
    if not env.get('DBUS_SESSION_BUS_ADDRESS', '').startswith(('unix:path=/tmp/', 'unix:abstract=/tmp/dbus-bsg-native-')):
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
        launch_arguments = native_launch_arguments(binary, repository, env, snap_app)
        launch_environment = env
        if snap_app is not None:
            desktop_bus = env.get('BUSYSTACK_NATIVE_SNAP_LAUNCH_BUS', '')
            desktop_runtime = env.get('BUSYSTACK_NATIVE_SNAP_LAUNCH_RUNTIME', '')
            if not desktop_bus.startswith('unix:path=/run/user/') or not desktop_runtime.startswith('/run/user/'):
                raise RuntimeError('Snap launcher requires the actual desktop session for its systemd scope')
            launch_environment = dict(env, DBUS_SESSION_BUS_ADDRESS=desktop_bus,
                                      XDG_RUNTIME_DIR=desktop_runtime)
        process = subprocess.Popen(launch_arguments, env=launch_environment,
                                   stdout=(output / 'application.log').open('w'), stderr=subprocess.STDOUT)
    except BaseException:
        if daemon is not None and daemon.poll() is None:
            daemon.terminate(); daemon.wait(timeout=15)
        desktop.dispose(); xvfb.terminate(); xvfb.wait(timeout=10)
        cleanup_runtime()
        raise
    receipt = {'backend': 'X11/Xvfb', 'display': env['DISPLAY'], 'displaySize': [1600, 1100], 'textScale': text_scale,
               'repository': str(repository.resolve()),
               'binarySHA256': hashlib.sha256(binary.read_bytes()).hexdigest(), 'captures': [],
               'compiledSources': compiled, 'sources': {}}
    receipt['nativeLibrarySearchPath'] = env.get('LD_LIBRARY_PATH', '')
    receipt['accessibilityEnvironment'] = {key: env[key] for key in ['NO_AT_BRIDGE', 'GTK_MODULES']}
    receipt['launchArguments'] = launch_arguments
    receipt['isolatedProfile'] = str(profile)
    if seeded_preferences is not None:
        receipt['seededOrdinaryPreferences'] = seeded_preferences
    receipt['snapApp'] = snap_app
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
    settings = Path(env['XDG_DATA_HOME']) / 'io.busystack.busymark/settings.json'
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
        if snap_app is not None:
            actual_executable = Path('/proc') / str(process.pid) / 'exe'
            if actual_executable.resolve() != binary.resolve():
                raise RuntimeError('Installed Snap launcher executed a different payload')
            label = (Path('/proc') / str(process.pid) / 'attr/current').read_text().strip()
            receipt['confinementLabel'] = label
            if label != 'snap.busymark.busymark (enforce)':
                raise RuntimeError('Installed Snap acceptance requires its enforced confinement')
            fields = {}
            for entry in (Path('/proc') / str(process.pid) / 'environ').read_bytes().split(b'\0'):
                key, _, value = entry.partition(b'=')
                if key.decode(errors='replace') in ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'DISPLAY', 'DBUS_SESSION_BUS_ADDRESS']:
                    fields[key.decode()] = value.decode()
            for key, value in fields.items():
                if value != env[key]:
                    raise RuntimeError('Installed Snap did not retain the isolated profile/display: '+key)
            if len(fields) != 7:
                raise RuntimeError('Cannot verify the installed Snap profile/display')
            receipt['verifiedApplicationProfile'] = fields
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
            elif kind in {'accessibility', 'activateAccessible'}:
                gi.require_version('Atspi', '2.0')
                from gi.repository import Atspi
                Atspi.set_timeout(5000, 10000)
                nodes = owned_accessible_nodes(Atspi.get_desktop(0), process.pid)
                rows = []
                matches = []
                for node in nodes:
                    states = node.get_state_set()
                    visible = states.contains(Atspi.StateType.SHOWING) and states.contains(Atspi.StateType.VISIBLE)
                    name = node.get_name()
                    role = Atspi.role_get_name(node.get_role())
                    enabled = states.contains(Atspi.StateType.ENABLED)
                    row = {'name': name, 'description': node.get_description(),
                           'role': role, 'showing': visible, 'enabled': enabled,
                           'focused': states.contains(Atspi.StateType.FOCUSED),
                           'selected': states.contains(Atspi.StateType.SELECTED),
                           'checked': states.contains(Atspi.StateType.CHECKED)}
                    if visible and name:
                        rows.append(row)
                    if visible and enabled and name == command.get('name') and (
                            command.get('role') is None or role == command['role']):
                        matches.append(node)
                if kind == 'accessibility':
                    target = output / (command['name'] + '-accessibility.json')
                    target.write_text(json.dumps({'pid': process.pid, 'nodes': rows}, indent=2)+'\n')
                    print(json.dumps({'accessibility': str(target), 'visibleNamedNodes': len(rows)}), flush=True)
                else:
                    if len(matches) != 1:
                        raise RuntimeError('Accessible action must resolve exactly one owned visible enabled node')
                    actions = matches[0].get_action_iface()
                    count = actions.get_n_actions() if actions is not None else 0
                    print(json.dumps({'accessibleAction': command['name'],
                                      'availableActions': [actions.get_action_name(i)
                                                           for i in range(count)]}), flush=True)
                    if actions is None or actions.get_n_actions() < 1 or not actions.do_action(0):
                        raise RuntimeError('Owned accessible action was not accepted')
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

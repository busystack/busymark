import ctypes as C
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from application_close_smoke import Desktop
from git_native_desktop import configure_native_text_dpi, geometry, require_installed_busyfiles, owned_accessible_nodes, native_launch_arguments, git_fixture_state


class NativeGeometryTest(unittest.TestCase):
    def test_native_evidence_detects_changed_bytes_even_when_status_is_unchanged(self):
        executable = Path(os.environ.get('BUSYSTACK_TEST_GIT_256', str(
            Path(__file__).resolve().parents[1]/'build/linux/x64/debug/bundle/libexec/git-runtime/bin/git')))
        self.assertTrue(executable.is_file(), 'Build the approved controlled Git runtime first')
        with tempfile.TemporaryDirectory(prefix='bsg-native-bytes-') as temporary:
            repo = Path(temporary)
            env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL='/dev/null')
            def run(*args):
                subprocess.run([str(executable), '-C', str(repo), *args], env=env,
                               check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            run('init', '-b', 'main')
            (repo/'tracked.md').write_text('base')
            run('add', '.')
            run('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                '-c', 'commit.gpgSign=false', 'commit', '-m', 'Fixture')
            (repo/'tracked.md').write_text('first dirty bytes')
            first = git_fixture_state(executable, repo)
            (repo/'tracked.md').write_text('different dirty bytes')
            second = git_fixture_state(executable, repo)
            self.assertEqual(first['status'], second['status'])
            self.assertEqual(first['indexSHA256'], second['indexSHA256'])
            self.assertNotEqual(first['gitVisibleWorkingFiles'], second['gitVisibleWorkingFiles'])
            run('add', '.')
            third = git_fixture_state(executable, repo)
            self.assertNotEqual(second['indexSHA256'], third['indexSHA256'])

    def test_snap_launch_preserves_confinement_and_passes_profile_values_as_argv(self):
        binary = Path('/snap/busymark/99999/busymark')
        env = {'DBUS_SESSION_BUS_ADDRESS': 'unix:abstract=/tmp/dbus-bsg-native-owned',
               'XDG_DATA_HOME': '/tmp/owned data',
               'XDG_CONFIG_HOME': '/tmp/owned config/$(must-remain-literal)',
               'XDG_RUNTIME_DIR': '/tmp/owned runtime'}
        command = native_launch_arguments(binary, Path('/tmp/fixture'), env, 'busymark')
        self.assertEqual(command[:4], ['snap', 'run', '--shell', 'busymark'])
        self.assertIn('XDG_CONFIG_HOME='+env['XDG_CONFIG_HOME'], command)
        self.assertNotIn(env['XDG_CONFIG_HOME'], command[5])
        self.assertEqual(command[-2:], [str(binary), '/tmp/fixture'])
        for candidate, app, address in [
            (Path('/tmp/extracted/busymark'), 'busymark', env['DBUS_SESSION_BUS_ADDRESS']),
            (binary, 'other-app', env['DBUS_SESSION_BUS_ADDRESS']),
            (binary, 'busymark', 'unix:path=/run/user/1000/bus'),
        ]:
            with self.assertRaises(RuntimeError):
                native_launch_arguments(candidate, Path('/tmp/fixture'),
                                        dict(env, DBUS_SESSION_BUS_ADDRESS=address), app)

    def test_accessibility_inspection_never_reads_another_applications_tree(self):
        class Peer:
            def __init__(self, pid, children=()):
                self.pid, self.children = pid, children
            def get_process_id(self): return self.pid
            def get_child_count(self):
                if self.pid == 2: raise AssertionError('Inspected unrelated application')
                return len(self.children)
            def get_child_at_index(self, index): return self.children[index]
            def clear_cache(self):
                if self.pid == 2: raise AssertionError('Inspected unrelated application')
        owned = Peer(1, [Peer(1)])
        root = Peer(0, [Peer(2), owned])
        self.assertEqual(owned_accessible_nodes(root, 1), [owned, owned.children[0]])
        with self.assertRaisesRegex(RuntimeError, 'no AT-SPI'):
            owned_accessible_nodes(root, 3)

    def test_installed_acceptance_rejects_relocated_payload_or_runtime_overrides(self):
        binary = Path('/usr/lib/busyfiles/busyfiles')
        receipt = {'provenance': {'installedRoot': '/'}}
        require_installed_busyfiles(binary, receipt, {})
        for candidate, binding, env in [
            (Path('/tmp/extracted/usr/lib/busyfiles/busyfiles'), receipt, {}),
            (binary, {'provenance': {'installedRoot': '/tmp/extracted'}}, {}),
            (binary, receipt, {'LD_LIBRARY_PATH': '/tmp/native'}),
            (binary, receipt, {'BUSYSTACK_NATIVE_DAEMON': '/tmp/daemon'}),
        ]:
            with self.assertRaises(RuntimeError):
                require_installed_busyfiles(candidate, binding, env)

    def test_enlarged_desktop_scales_real_gtk_text_as_well_as_flutter(self):
        with tempfile.TemporaryDirectory(prefix='bsg-native-dpi-') as temporary:
            env = dict(os.environ, GDK_BACKEND='x11', GSETTINGS_BACKEND='memory')
            env.pop('WAYLAND_DISPLAY', None)
            for suffix in ['CONFIG_HOME', 'DATA_HOME', 'CACHE_HOME', 'STATE_HOME', 'RUNTIME_DIR']:
                directory = Path(temporary)/suffix
                directory.mkdir(mode=0o700)
                env['XDG_'+suffix] = str(directory)
            server = subprocess.Popen(['Xvfb', '-displayfd', '1', '-noreset', '-screen', '0',
                                       '800x730x24', '-nolisten', 'tcp'],
                                      stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            env['DISPLAY'] = ':'+server.stdout.readline().decode().strip()
            try:
                configure_native_text_dpi(env, 1.5)
                query = ('import subprocess;subprocess.run(["dbus-update-activation-environment",'
                         '"DISPLAY","GDK_BACKEND","XDG_CONFIG_HOME","XDG_DATA_HOME",'
                         '"XDG_CACHE_HOME","XDG_STATE_HOME","XDG_RUNTIME_DIR"],check=True);'
                         'import gi,json;gi.require_version("Gtk","3.0");'
                         'from gi.repository import Gtk,Gdk,GObject;Gtk.init([]);'
                         'print(json.dumps({"backend":GObject.type_name(Gdk.Display.get_default()),'
                         '"dpi":Gtk.Settings.get_default().get_property("gtk-xft-dpi")}))')
                result = json.loads(subprocess.check_output(
                    ['dbus-run-session', '--', '/usr/bin/python3', '-c', query], env=env, text=True))
                self.assertEqual(result, {'backend': 'GdkX11Display', 'dpi': 144*1024})
            finally:
                server.terminate(); server.wait(timeout=10)
                server.stdout.close()
                for name in ['doc', 'gvfs']:
                    mount = Path(env['XDG_RUNTIME_DIR'])/name
                    if os.path.ismount(mount):
                        subprocess.run(['fusermount3', '--unmount', str(mount)], check=True)

    def test_server_geometry_tracks_resize_without_a_gdk_event_loop(self):
        with tempfile.TemporaryDirectory(prefix='busymark-native-geometry-') as temporary:
            with (Path(temporary) / 'xvfb.log').open('w') as log:
                server = subprocess.Popen(['Xvfb', '-displayfd', '1', '-screen', '0',
                                           '1600x1100x24', '-nolisten', 'tcp'],
                                          stdout=subprocess.PIPE, stderr=log)
                previous = os.environ.get('DISPLAY')
                previous_backend = os.environ.get('GDK_BACKEND')
                os.environ['DISPLAY'] = ':' + server.stdout.readline().decode().strip()
                os.environ['GDK_BACKEND'] = 'x11'
                desktop = None
                try:
                    desktop = Desktop()
                    desktop.Gdk.init([])
                    x = desktop.x
                    x.XCreateSimpleWindow.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_int,
                                                      C.c_uint, C.c_uint, C.c_uint, C.c_ulong, C.c_ulong]
                    x.XCreateSimpleWindow.restype = C.c_ulong
                    x.XResizeWindow.argtypes = [C.c_void_p, C.c_ulong, C.c_uint, C.c_uint]
                    x.XSync.argtypes = [C.c_void_p, C.c_int]
                    xid = x.XCreateSimpleWindow(desktop.display, desktop.root, 0, 0, 1290, 730, 0, 0, 0)
                    x.XSync(desktop.display, 0)
                    window = desktop.GdkX11.X11Window.foreign_new_for_display(desktop.Gdk.Display.get_default(), xid)
                    self.assertEqual(geometry(desktop, window), (1290, 730))
                    x.XResizeWindow(desktop.display, xid, 600, 730)
                    self.assertEqual(geometry(desktop, window), (600, 730))
                    x.XResizeWindow(desktop.display, xid, 1290, 730)
                    self.assertEqual(geometry(desktop, window), (1290, 730))
                finally:
                    if desktop:
                        desktop.dispose()  # Own connection owns the disposable window.
                    if previous is None:
                        os.environ.pop('DISPLAY', None)
                    else:
                        os.environ['DISPLAY'] = previous
                    if previous_backend is None:
                        os.environ.pop('GDK_BACKEND', None)
                    else:
                        os.environ['GDK_BACKEND'] = previous_backend
                    server.terminate()
                    server.wait(timeout=10)
                    server.stdout.close()


if __name__ == '__main__':
    unittest.main()

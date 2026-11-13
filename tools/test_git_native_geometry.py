import ctypes as C
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
from application_close_smoke import Desktop
from git_native_desktop import configure_native_portals, configure_native_text_dpi, geometry, require_installed_busyfiles, owned_accessible_nodes, native_launch_arguments, git_fixture_state, seed_private_preferences, start_private_secret_service, require_portal_text_scale


class NativeGeometryTest(unittest.TestCase):
    def test_null_child_restarts_the_complete_owned_snapshot(self):
        from git_native_desktop import retry_accessible_snapshot
        root, owned, replacement = mock.Mock(), mock.Mock(), mock.Mock()
        root.get_child_count.return_value = 1
        root.get_child_at_index.return_value = owned
        owned.get_process_id.return_value = 42
        owned.get_child_count.return_value = 1
        owned.get_child_at_index.side_effect = [None, replacement]
        replacement.get_child_count.return_value = 0
        with mock.patch('git_native_desktop.time.sleep'):
            self.assertEqual(retry_accessible_snapshot(lambda: owned_accessible_nodes(root, 42)),
                             [owned, replacement])
        self.assertEqual(owned.clear_cache.call_count, 2)

    def test_persistently_null_accessible_child_fails_closed(self):
        from git_native_desktop import ReplacedAccessibleChild, retry_accessible_snapshot
        root = mock.Mock()
        root.get_child_count.return_value = 1
        root.get_child_at_index.return_value = None
        with mock.patch('git_native_desktop.time.sleep'), self.assertRaises(ReplacedAccessibleChild):
            retry_accessible_snapshot(lambda: owned_accessible_nodes(root, 42))
        self.assertEqual(root.get_child_at_index.call_count, 10)
        collect = mock.Mock(side_effect=AttributeError('Unrelated programming error'))
        with self.assertRaises(AttributeError):
            retry_accessible_snapshot(collect)
        collect.assert_called_once()

    def test_flutter_portal_rejects_missing_interface_or_wrong_scale(self):
        with mock.patch('git_native_desktop.subprocess.run', side_effect=subprocess.CalledProcessError(1, 'gdbus')):
            with self.assertRaises(subprocess.CalledProcessError):
                require_portal_text_scale({}, 1.5)
        for response, requested in [('(<<1.0>>,)', 1.5), ('(<<true>>,)', 1.0),
                                    ("(<<'1.5'>>,)", 1.5)]:
            with self.subTest(response=response), mock.patch('git_native_desktop.subprocess.run',
                    return_value=subprocess.CompletedProcess('gdbus', 0, response, '')):
                with self.assertRaisesRegex(RuntimeError, 'differs from'):
                    require_portal_text_scale({}, requested)

    def test_native_graph_bounds_clip_rtl_raster_rounding_and_reject_wrong_columns(self):
        from git_native_smoke import native_history_graph_bounds
        # Actual Ubuntu 24.04 Arabic capture: GTK viewport is 45..957, while
        # independently rounded/ceiled first-column extents end at 958.
        table, subject = (45, 193, 957, 609), (385, 193, 958, 227)
        self.assertEqual(native_history_graph_bounds(table, subject, True), (917, 227, 957, 609))
        self.assertEqual(native_history_graph_bounds((333, 193, 1245, 609),
                         (333, 193, 922, 227), False), (333, 227, 373, 609))
        for invalid in [(385, 193, 959, 227), (385, 193, 940, 227),
                        (0, 193, 958, 227), (930, 193, 958, 227),
                        (385, 193, 958, 600)]:
            with self.subTest(subject=invalid), self.assertRaisesRegex(RuntimeError, 'geometry is invalid'):
                native_history_graph_bounds(table, invalid, True)

    def test_replaced_accessible_row_requires_a_new_complete_snapshot(self):
        from gi.repository import GLib
        from git_native_desktop import retry_accessible_snapshot
        stale = GLib.Error('object /org/a11y/atspi/accessible/319 does not exist',
                          'atspi_error', 1)
        complete = {'ownedRows': ['replacement'], 'partial': False}
        collect = mock.Mock(side_effect=[stale, complete])
        with mock.patch('git_native_desktop.time.sleep'):
            self.assertIs(retry_accessible_snapshot(collect), complete)
        self.assertEqual(collect.call_count, 2)

    def test_perpetually_replaced_accessibility_tree_fails_closed(self):
        from gi.repository import GLib
        from git_native_desktop import retry_accessible_snapshot
        collect = mock.Mock(side_effect=GLib.Error(
            'object /org/a11y/atspi/accessible/319 does not exist', 'atspi_error', 1))
        with mock.patch('git_native_desktop.time.sleep'), self.assertRaises(GLib.Error):
            retry_accessible_snapshot(collect)
        self.assertEqual(collect.call_count, 10)

    def test_accessibility_transport_and_unrelated_errors_are_never_retried(self):
        from gi.repository import GLib
        from git_native_desktop import retry_accessible_snapshot
        for message, domain in [
            ('timeout from dbind', 'atspi_error'),
            ('Permission denied', 'atspi_error'),
            ('object /unrelated/319 does not exist', 'atspi_error'),
            ('object /org/a11y/atspi/accessible/319 does not exist', 'other_error'),
        ]:
            with self.subTest(message=message, domain=domain):
                collect = mock.Mock(side_effect=GLib.Error(message, domain, 1))
                with self.assertRaises(GLib.Error):
                    retry_accessible_snapshot(collect)
                self.assertEqual(collect.call_count, 1)

    def test_history_graph_requires_a_rendered_column_across_native_accent_colors(self):
        from PIL import Image, ImageDraw
        from git_native_smoke import graph_rendered
        for color in [(53, 132, 228), (233, 84, 32)]:
            image = Image.new('RGB', (40, 400), (240, 240, 240))
            self.assertFalse(graph_rendered(image))
            draw = ImageDraw.Draw(image)
            draw.rectangle((2, 5, 37, 30), fill=color)
            self.assertFalse(graph_rendered(image), 'A button or one selected row is not a graph')
            draw.line((10, 40, 10, 350), fill=color, width=2)
            self.assertTrue(graph_rendered(image))
            draw.rectangle((0, 0, 39, 399), fill=color)
            self.assertFalse(graph_rendered(image), 'A cleared or solid surface is not a graph')

    def test_secret_service_cannot_use_the_desktop_session_bus(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            env = {'DBUS_SESSION_BUS_ADDRESS': 'unix:path=/run/user/1000/bus'}
            with mock.patch('git_native_desktop.subprocess.run') as run:
                with self.assertRaisesRegex(RuntimeError, 'private session bus'):
                    start_private_secret_service(env, root/'keyring', root/'keyring.log')
                run.assert_not_called()

    def test_private_secret_service_is_ready_and_its_login_collection_is_unlocked(self):
        with tempfile.TemporaryDirectory(prefix='bsg-keyring-test-') as temporary:
            script = '''
import json, os, sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()/'tools'))
from git_native_desktop import start_private_secret_service
from gi.repository import Gio, GLib
root = Path(sys.argv[1])
env = dict(os.environ)
for suffix in ['CONFIG_HOME', 'DATA_HOME', 'CACHE_HOME', 'STATE_HOME', 'RUNTIME_DIR']:
    directory = root/suffix
    directory.mkdir(mode=0o700)
    env['XDG_'+suffix] = str(directory)
control = root/'RUNTIME_DIR/keyring'
control.mkdir(mode=0o700)
service = start_private_secret_service(env, control, root/'keyring.log')
connection = Gio.DBusConnection.new_for_address_sync(
    env['DBUS_SESSION_BUS_ADDRESS'],
    Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
    None, None)
flags = Gio.DBusCallFlags.NO_AUTO_START
owned = connection.call_sync('org.freedesktop.DBus', '/org/freedesktop/DBus',
    'org.freedesktop.DBus', 'NameHasOwner',
    GLib.Variant('(s)', ('org.freedesktop.secrets',)),
    GLib.VariantType('(b)'), flags, 5000, None).unpack()[0]
if not owned:
    raise RuntimeError('Private service was not initialized before inspection')
collection = connection.call_sync('org.freedesktop.secrets', '/org/freedesktop/secrets',
    'org.freedesktop.Secret.Service', 'ReadAlias', GLib.Variant('(s)', ('default',)),
    GLib.VariantType('(o)'), flags, 5000, None).unpack()[0]
if collection == '/':
    raise RuntimeError('Private login collection was not created')
locked = connection.call_sync('org.freedesktop.secrets', collection,
    'org.freedesktop.DBus.Properties', 'Get',
    GLib.Variant('(ss)', ('org.freedesktop.Secret.Collection', 'Locked')),
    GLib.VariantType('(v)'), flags, 5000, None).unpack()[0]
connection.close_sync(None)
print(json.dumps({'ready': service['ready'], 'collectionUnlocked': not locked}))
'''
            result = subprocess.run(
                ['dbus-run-session', '--', '/usr/bin/python3', '-c', script, temporary],
                cwd=Path(__file__).resolve().parents[1], text=True,
                capture_output=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(json.loads(result.stdout), {'ready': True, 'collectionUnlocked': True})

    def test_private_preferences_cannot_seed_trust_or_overwrite_existing_profile(self):
        with tempfile.TemporaryDirectory() as temporary:
            env = {'XDG_DATA_HOME': temporary}
            values = {'autoSave': False, 'localeTag': 'ar', 'themeModePreference': 'dark'}
            target = seed_private_preferences(env, values)
            self.assertEqual(json.loads(target.read_text()), values)
            with self.assertRaisesRegex(RuntimeError, 'overwrite existing'):
                seed_private_preferences(env, values)
            for invalid in [{'trustedGitWorkspaceRoots': ['/tmp/repo']}, {'autoSave': 'false'},
                            {'localeTag': []}, {'themeModePreference': 'invalid'}]:
                with self.assertRaisesRegex(ValueError, 'ordinary locale'):
                    seed_private_preferences(env, invalid)

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
            env = dict(os.environ, GDK_BACKEND='x11', GSETTINGS_BACKEND='keyfile')
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
                configure_native_portals(env)
                configure_native_text_dpi(env, 1.5)
                query = ('import subprocess;subprocess.run(["dbus-update-activation-environment",'
                         '"DISPLAY","GDK_BACKEND","GSETTINGS_BACKEND","XDG_CONFIG_HOME","XDG_DATA_HOME",'
                         '"XDG_CACHE_HOME","XDG_STATE_HOME","XDG_RUNTIME_DIR"],check=True);'
                         'subprocess.run(["gsettings","set","org.gnome.desktop.interface",'
                         '"text-scaling-factor","1.5"],check=True);'
                         'import os,sys;sys.path.insert(0,"tools");'
                         'from git_native_desktop import require_portal_text_scale;'
                         'portal=require_portal_text_scale(os.environ,1.5);'
                         'import gi,json;gi.require_version("Gtk","3.0");'
                         'from gi.repository import Gtk,Gdk,GObject;Gtk.init([]);'
                         'print("NATIVE_SCALE_RESULT="+json.dumps({"backend":GObject.type_name(Gdk.Display.get_default()),'
                         '"dpi":Gtk.Settings.get_default().get_property("gtk-xft-dpi"),'
                         '"portal":portal}))')
                output = subprocess.check_output(
                    ['dbus-run-session', '--', '/usr/bin/python3', '-c', query], env=env, text=True)
                # Activated accessibility services can log to inherited stdout.
                records = [line.removeprefix('NATIVE_SCALE_RESULT=') for line in output.splitlines()
                           if line.startswith('NATIVE_SCALE_RESULT=')]
                self.assertEqual(len(records), 1, output)
                result = json.loads(records[0])
                self.assertEqual(result, {'backend': 'GdkX11Display', 'dpi': 144*1024,
                                          'portal': '(<<1.5>>,)'})
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

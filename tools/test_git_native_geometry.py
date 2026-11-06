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
from git_native_desktop import configure_native_text_dpi, geometry, require_installed_busyfiles


class NativeGeometryTest(unittest.TestCase):
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

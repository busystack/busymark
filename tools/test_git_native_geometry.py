import ctypes as C
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from application_close_smoke import Desktop
from git_native_desktop import geometry


class NativeGeometryTest(unittest.TestCase):
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

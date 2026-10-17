#!/usr/bin/env python3
"""Live GTK/XI2 regression. Run only on an explicitly disposable X11 display.

xvfb-run -a dbus-run-session -- /usr/bin/python3 \
  tools/test_application_input_observer.py --disposable-display

This deliberately injects two known keys into its own two GTK windows. It never
selects raw/root input, records key payloads, or sends input to other windows.
"""
import argparse
import ctypes as C
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disposable-display', action='store_true')
    parser.add_argument('--observer', type=Path, default=Path(__file__).with_name('application_close_smoke.py'))
    args = parser.parse_args()
    if not args.disposable_display:
        parser.error('Input injection requires an explicitly disposable display')
    with tempfile.TemporaryDirectory(prefix='bm-input-regression-') as temporary:
        for key, child in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                           ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache')]:
            directory = Path(temporary) / child
            directory.mkdir()
            os.environ[key] = str(directory)
        import gi
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gtk
        spec = importlib.util.spec_from_file_location('close_observer', args.observer)
        observer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(observer)
        desktop = observer.Desktop()
        windows = []
        try:
            entries = []
            for title in ['Observed GTK input regression', 'Unobserved owned control']:
                window = Gtk.Window(title=title)
                window.set_default_size(400, 120)
                entry = Gtk.Entry()
                window.add(entry)
                window.show_all()
                windows.append(window)
                entries.append(entry)
            watch = observer.OwnedInputAudit(desktop, windows[0].get_window())

            def until(predicate):
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    while Gtk.events_pending():
                        Gtk.main_iteration_do(False)
                    watch.poll()
                    if predicate():
                        return
                    time.sleep(.005)
                raise AssertionError('GTK input did not complete on the disposable display')

            x = desktop.x
            x.XSetInputFocus.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_ulong]
            x.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
            x.XKeysymToKeycode.restype = C.c_uint
            xtest = C.CDLL('libXtst.so.6')
            xtest.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
            for index, text in [(0, 'a'), (1, 'b')]:
                windows[index].present()
                entries[index].grab_focus()
                x.XSetInputFocus(desktop.display, windows[index].get_window().get_xid(), 2, 0)
                x.XSync(desktop.display, 0)
                key = x.XKeysymToKeycode(desktop.display, ord(text))
                assert key
                assert xtest.XTestFakeKeyEvent(desktop.display, key, 1, 0)
                assert xtest.XTestFakeKeyEvent(desktop.display, key, 0, 0)
                x.XSync(desktop.display, 0)
                until(lambda: entries[index].get_text() == text)
            result = watch.result()
            assert not result['errors'], result
            assert (result['keyPresses'], result['keyReleases']) == (1, 1), result
            print(json.dumps({'ok': True, 'deliveredToBothOwnedEntries': True,
                              'observer': result}, indent=2))
        finally:
            for window in windows:
                window.destroy()
            while Gtk.events_pending():
                Gtk.main_iteration_do(False)
            desktop.dispose()


if __name__ == '__main__':
    main()

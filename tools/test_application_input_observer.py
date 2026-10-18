#!/usr/bin/env python3
"""Live GTK/XI2 regression. Run only on an explicitly disposable X11 display.

xvfb-run -a dbus-run-session -- /usr/bin/python3 \
  tools/test_application_input_observer.py --disposable-display

This deliberately injects known keys into its own GTK windows. It never
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
                           ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                           ('XDG_STATE_HOME', 'state')]:
            directory = Path(temporary) / child
            directory.mkdir()
            os.environ[key] = str(directory)
        os.environ['GSETTINGS_BACKEND'] = 'memory'
        import gi
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gtk
        spec = importlib.util.spec_from_file_location('close_observer', args.observer)
        observer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(observer)
        desktop = observer.Desktop()
        windows = []
        try:
            assert desktop.audit_input(os.getpid()) is None, 'Audit selected a helper before a content window exists'
            # The hidden GTK group leader has the same _NET_WM_PID. Pre-map
            # discovery must select the future content window, not that leader.
            pending = Gtk.Window(title='Owned pre-map input regression')
            pending.realize()
            premap = desktop.audit_input(os.getpid())
            assert premap is not None
            assert pending.get_window().get_xid() in premap.windows, 'Audit selected the GTK leader instead of the content window'
            pending.destroy()
            while Gtk.events_pending():
                Gtk.main_iteration_do(False)
            premap.result()
            assert not premap.errors
            entries = []
            boxes = []
            for title in ['Observed GTK input regression', 'Unobserved owned control']:
                window = Gtk.Window(title=title)
                window.set_default_size(400, 120)
                entry = Gtk.Entry()
                box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
                box.pack_start(entry, False, False, 0)
                window.add(box)
                window.show_all()
                windows.append(window)
                entries.append(entry)
                boxes.append(box)
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
            # FlView's GdkWindow can be realized after the pre-map audit starts.
            # Deliver another actual key to such a child; the unmodified audit
            # misses both this key and its focus, despite GTK receiving them.
            from gi.repository import Gdk
            late = Gtk.DrawingArea()
            late.set_can_focus(True)
            late.add_events(Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK)
            delivered = []
            late.connect('key-press-event', lambda *_: delivered.append('press') or True)
            late.connect('key-release-event', lambda *_: delivered.append('release') or True)
            boxes[0].pack_start(late, True, True, 0)
            windows[0].show_all()
            Gdk.Display.get_default().flush()
            until(lambda: late.get_window() is not None and late.get_window().get_xid() in watch.windows)
            late_xid = late.get_window().get_xid()
            assert late_xid in watch.windows, 'New owned child was not subscribed'
            windows[0].present()
            late.grab_focus()
            x.XSetInputFocus(desktop.display, late_xid, 2, 0)
            x.XSync(desktop.display, 0)
            key = x.XKeysymToKeycode(desktop.display, ord('c'))
            assert xtest.XTestFakeKeyEvent(desktop.display, key, 1, 0)
            assert xtest.XTestFakeKeyEvent(desktop.display, key, 0, 0)
            x.XSync(desktop.display, 0)
            until(lambda: delivered == ['press', 'release'])
            result = watch.result()
            assert not result['errors'], result
            assert (result['keyPresses'], result['keyReleases']) == (2, 2), result
            late.destroy()
            until(lambda: late_xid not in watch.windows)
            # Deterministically destroy the root after the observer drains
            # events but before its next QueryTree reaches the X server.
            # The real server returns BadWindow plus our subscribed
            # DestroyNotify; a missing or unrelated notification is not enough.
            class DestroyBeforeQuery:
                def __init__(self):
                    self.destroyed = False

                def __getattr__(self, name):
                    return getattr(x, name)

                def XQueryTree(self, *arguments):
                    if arguments[1] == watch.root_window and not self.destroyed:
                        self.destroyed = True
                        windows[0].destroy()
                        Gdk.Display.get_default().sync()
                    return x.XQueryTree(*arguments)

            watch.x = DestroyBeforeQuery()
            watch._refresh_windows()
            assert watch.retired
            assert watch.retirement_races, 'Actual BadWindow race was not exercised'
            assert not watch.result()['errors']
            print(json.dumps({'ok': True, 'deliveredToBothOwnedEntries': True,
                              'lateChildDeliveryAndRetirement': True,
                              'destroyDuringQueryRetirement': True,
                              'observer': result}, indent=2))
        finally:
            for window in windows:
                window.destroy()
            while Gtk.events_pending():
                Gtk.main_iteration_do(False)
            desktop.dispose()


if __name__ == '__main__':
    main()

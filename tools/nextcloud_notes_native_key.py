"""Send an acceptance key on the caller's isolated X11 display using XTest.

The desktop harness focuses its own test window first. No additional package or
production dependency is required; X11/XTest are supplied by the Linux fixture.
"""
import ctypes
import ctypes.util
import os
import sys

if os.environ.get('BUSYMARK_NATIVE_ACCEPTANCE') != '1':
    raise SystemExit('Only the isolated Notes desktop acceptance harness may invoke this helper.')
bindings = {
    'ctrl+f': [b'Control_L', b'f'],
    'ctrl+p': [b'Control_L', b'p'],
    'ctrl+shift+p': [b'Control_L', b'Shift_L', b'p'],
    'escape': [b'Escape'],
    'enter': [b'Return'],
}
if len(sys.argv) != 2 or sys.argv[1] not in bindings:
    raise SystemExit('Expected an acceptance search, Quick Open or dismissal key.')
x11 = ctypes.CDLL(ctypes.util.find_library('X11'))
xtest = ctypes.CDLL(ctypes.util.find_library('Xtst'))
x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
x11.XStringToKeysym.restype = ctypes.c_ulong
x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x11.XKeysymToKeycode.restype = ctypes.c_uint
x11.XFlush.argtypes = [ctypes.c_void_p]
x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
xtest.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
display = x11.XOpenDisplay(os.environ['DISPLAY'].encode())
if not display:
    raise SystemExit('Cannot open the isolated test display.')
try:
    codes = [x11.XKeysymToKeycode(display, x11.XStringToKeysym(key))
             for key in bindings[sys.argv[1]]]
    for code, pressed in ([(code, 1) for code in codes] +
                          [(code, 0) for code in reversed(codes)]):
        if not xtest.XTestFakeKeyEvent(display, code, pressed, 0):
            raise RuntimeError('Native key injection failed.')
    x11.XFlush(display)
finally:
    x11.XCloseDisplay(display)

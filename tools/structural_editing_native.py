#!/usr/bin/env python3
"""Structural-edit acceptance on an owned Xvfb desktop and private profile.

Usage: /usr/bin/python3 tools/structural_editing_native.py BINARY NEW_OUTPUT
The --key/--click modes are called only by that binary for its own native window.
"""
import ctypes as C
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def input_event(kind, target, arguments):
    if os.environ.get("BUSYMARK_STRUCTURAL_ACCEPTANCE") != "1" or int(target) != os.getppid():
        raise RuntimeError("Only the owning disposable application may inject input")
    from application_close_smoke import Desktop
    desktop = Desktop()
    try:
        desktop.Gdk.init([])
        window = desktop.window(int(target), require_normal=True)
        if window is None:
            raise RuntimeError("No mapped window belonging to the caller")
        xid = window.get_xid()
        x = desktop.x
        x.XSetInputFocus.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_ulong]
        x.XSetInputFocus(desktop.display, xid, 1, 0)
        xtest = C.CDLL("libXtst.so.6")
        if kind == "--key":
            x.XStringToKeysym.argtypes = [C.c_char_p]
            x.XStringToKeysym.restype = C.c_ulong
            x.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
            x.XKeysymToKeycode.restype = C.c_uint
            xtest.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
            codes = [x.XKeysymToKeycode(desktop.display, x.XStringToKeysym(s.encode())) for s in arguments]
            if not codes or not all(codes):
                raise RuntimeError("Invalid native key chord")
            for code, pressed in [(c, 1) for c in codes] + [(c, 0) for c in reversed(codes)]:
                if desktop.window(int(target), require_normal=True).get_xid() != xid:
                    raise RuntimeError("Owned window changed during input")
                if not xtest.XTestFakeKeyEvent(desktop.display, code, pressed, 0):
                    raise RuntimeError("XTest rejected keyboard input")
        else:
            px, py = map(float, arguments)
            if not 0 < px < window.get_width() or not 0 < py < window.get_height():
                raise RuntimeError("Pointer target is outside the owned window")
            _, ox, oy = window.get_origin()
            xtest.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
            xtest.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
            if not xtest.XTestFakeMotionEvent(desktop.display, 0, round(ox + px), round(oy + py), 0):
                raise RuntimeError("XTest rejected pointer motion")
            for pressed in [1, 0]:
                if not xtest.XTestFakeButtonEvent(desktop.display, 1, pressed, 0):
                    raise RuntimeError("XTest rejected pointer input")
        x.XFlush(desktop.display)
    finally:
        desktop.dispose()


def run(binary, output):
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ)
    for key, name in [("XDG_RUNTIME_DIR", "runtime"), ("XDG_CONFIG_HOME", "config"),
                      ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                      ("XDG_STATE_HOME", "state")]:
        directory = output / name
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    for key in ["DISPLAY", "XAUTHORITY", "WAYLAND_DISPLAY", "GNOME_KEYRING_PID",
                "GNOME_KEYRING_CONTROL", "SSH_AUTH_SOCK", "GPG_AGENT_INFO", "SESSION_MANAGER"]:
        env.pop(key, None)
    env.update(GDK_BACKEND="x11", BUSYMARK_STRUCTURAL_ACCEPTANCE="1")
    fixtures = output / "fixtures"
    shutil.copytree("test/fixtures/structural_editing", fixtures / "markdown")
    for name in ["first.png", "second.png", "third.png"]:
        shutil.copyfile("test/fixtures/writerside/basic_project/images/logo.png", fixtures / "markdown" / name)
    shutil.copytree("test/fixtures/writerside/basic_project", fixtures / "writerside")
    shutil.copyfile(fixtures / "markdown/heading-properties.md", fixtures / "writerside/topics/structure.md")
    probe = output / "probe"
    probe.mkdir()
    # Isolation is established before creating the broker, so activated helpers
    # receive the private profile too. Neither the host display nor bus is used.
    command = ["/usr/bin/dbus-run-session", "--", "/usr/bin/xvfb-run", "-a", "-s",
               "-screen 0 1440x1000x24", str(Path(binary).resolve()), str(fixtures), str(probe)]
    with (output / "application.log").open("w") as log:
        supervisor = subprocess.Popen(
            ["/usr/bin/python3", "tools/run_owned_fixture.py", "--report", str(output / "ownership.json"),
             "--duration", "240", "--", *command], env=env, stdin=subprocess.PIPE,
            stdout=log, stderr=subprocess.STDOUT)
        try:
            exit_code = supervisor.wait(timeout=260)
        finally:
            if supervisor.poll() is None:
                supervisor.stdin.write(b"stop\n")
                supervisor.stdin.flush()
                supervisor.wait(timeout=15)
            supervisor.stdin.close()
    result = json.loads((probe / "result.json").read_text())
    print(json.dumps({"backend": "X11/Xvfb", "exitCode": exit_code, **result}))
    if exit_code or not result["passed"]:
        raise RuntimeError("Native structural acceptance failed; inspect retained output")


if __name__ == "__main__":
    if sys.argv[1:2] in [["--key"], ["--click"]]:
        input_event(sys.argv[1], sys.argv[2], sys.argv[3:])
    else:
        run(*sys.argv[1:])

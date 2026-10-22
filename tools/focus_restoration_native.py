#!/usr/bin/env python3
"""Run the focus probe on an owned GNOME headless desktop, never the user's.

Usage: dbus-run-session -- /usr/bin/python3 tools/focus_restoration_native.py
       BUNDLE_EXECUTABLE NEW_OUTPUT_DIRECTORY x11|wayland editor|source|split|table
       [full|alt-tab|minimize] [markdown|writerside]
Requires GNOME Mutter RemoteDesktop input support and system PyGObject.
"""
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib


def wait_for(predicate, timeout=45):
    end = time.monotonic() + timeout
    while not predicate():
        if time.monotonic() >= end:
            raise RuntimeError("Native prerequisite timed out")
        time.sleep(0.05)


def companion():
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk
    window = Gtk.Window(title="Focus acceptance companion")
    window.set_default_size(400, 200)
    window.add(Gtk.Label(label="Disposable focus acceptance application"))
    window.connect("destroy", Gtk.main_quit)
    window.show_all()
    Gtk.main()


def run(binary, output, backend, mode, transitions="full", document_format="markdown"):
    parent = os.getppid()
    if Path(f"/proc/{parent}/exe").resolve().name != "dbus-run-session":
        raise RuntimeError("Run under a dedicated dbus-run-session, never the host session bus")
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ)
    for key, child in [("XDG_RUNTIME_DIR", "runtime"), ("XDG_CONFIG_HOME", "config"),
                       ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                       ("XDG_STATE_HOME", "state")]:
        directory = output / child
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    env["GDK_BACKEND"] = backend
    env["WAYLAND_DISPLAY"] = "focus-acceptance"
    env["XDG_SESSION_TYPE"] = "wayland"
    keyring = output / "runtime/keyring"
    keyring.mkdir(mode=0o700)
    env["GNOME_KEYRING_CONTROL"] = str(keyring)
    for key in ("GNOME_KEYRING_PID", "SSH_AUTH_SOCK", "GPG_AGENT_INFO", "SESSION_MANAGER"):
        env.pop(key, None)
    env.pop("DISPLAY", None)
    env.pop("XAUTHORITY", None)
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    broker = bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                          "GetConnectionUnixProcessID", GLib.Variant("(s)", ("org.freedesktop.DBus",)),
                          None, Gio.DBusCallFlags.NONE, 10000, None).unpack()[0]
    broker_parent = re.search(r"^PPid:\s+(\d+)$", Path(f"/proc/{broker}/status").read_text(), re.M)
    if broker_parent is None or int(broker_parent[1]) != parent:
        raise RuntimeError("The D-Bus broker is not owned by this dbus-run-session")

    def update_activation_environment():
        # The private broker predates this Python process's isolated profile.
        # D-Bus-activated desktop helpers must inherit it too, not the host's.
        values = {key: env.get(key, "") for key in (
            "XDG_RUNTIME_DIR", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME",
            "XDG_STATE_HOME", "GDK_BACKEND", "WAYLAND_DISPLAY", "DISPLAY", "XAUTHORITY",
            "XDG_SESSION_TYPE", "GNOME_KEYRING_CONTROL", "GNOME_KEYRING_PID",
            "SSH_AUTH_SOCK", "GPG_AGENT_INFO", "SESSION_MANAGER")}
        bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                      "UpdateActivationEnvironment", GLib.Variant("(a{ss})", (values,)),
                      None, Gio.DBusCallFlags.NONE, 10000, None)

    update_activation_environment()
    processes = []
    logs = []
    actions = []

    def launch(command, name):
        log = (output / f"{name}.log").open("w")
        logs.append(log)
        process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        processes.append(process)
        return process

    try:
        compositor = launch(["gnome-shell", "--headless", "--wayland", "--virtual-monitor=1280x960",
                             "--wayland-display=focus-acceptance"], "compositor")
        wait_for(lambda: (output / "runtime/focus-acceptance").exists() or compositor.poll() is not None)
        if compositor.poll() is not None:
            raise RuntimeError("Disposable compositor exited; see compositor.log")
        wait_for(lambda: "Using public X11 display" in (output / "compositor.log").read_text())
        env["DISPLAY"] = re.search(r"Using public X11 display (:[0-9]+)", (output / "compositor.log").read_text())[1]
        auth = list((output / "runtime").glob(".mutter-Xwaylandauth.*"))
        if auth:
            env["XAUTHORITY"] = str(auth[0])
        update_activation_environment()
        wait_for(lambda: bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "NameHasOwner", GLib.Variant("(s)", ("org.gnome.Mutter.RemoteDesktop",)), None, Gio.DBusCallFlags.NONE, 1000, None).unpack()[0], timeout=30)

        def call(path, interface, method, parameters=None):
            return bus.call_sync("org.gnome.Mutter.RemoteDesktop", path, interface, method,
                                 parameters, None, Gio.DBusCallFlags.NONE, 10000, None)

        session = call("/org/gnome/Mutter/RemoteDesktop", "org.gnome.Mutter.RemoteDesktop", "CreateSession").unpack()[0]
        interface = "org.gnome.Mutter.RemoteDesktop.Session"
        call(session, interface, "Start")
        xml = bus.call_sync("org.gnome.Mutter.RemoteDesktop", session, "org.freedesktop.DBus.Introspectable", "Introspect", None, None, Gio.DBusCallFlags.NONE, 1000, None).unpack()[0]
        (output / "remote-input-interface.xml").write_text(xml)

        def key(code, pressed):
            call(session, interface, "NotifyKeyboardKeycode", GLib.Variant("(ub)", (code, pressed)))

        def chord(modifier, code):
            key(modifier, True)
            key(code, True)
            key(code, False)
            key(modifier, False)
            actions.append({"time": time.monotonic(), "keys": [modifier, code]})
            time.sleep(0.7)

        launch(["/usr/bin/python3", str(Path(__file__).resolve()), "--companion"], "companion")
        time.sleep(1)
        text = "Focus target is the original insertion location.\n\n"
        text += "| Header | Other |\n| --- | --- |\n| Focus cell | Body |\n\n"
        text += "\n\n".join((f"Reading paragraph {i} " + "reading words " * 25).rstrip() for i in range(160)) + "\n"
        if document_format == "writerside":
            text = '<topic id="focus" title="Focus"><p>Focus target is the original insertion location.</p>' + ''.join(f'<p>Reading paragraph {i} ' + 'reading words ' * 25 + '</p>' for i in range(160)) + '</topic>'
        fixture = output / ("disposable.topic" if document_format == "writerside" else "disposable.md")
        fixture.write_text(text)
        probe = output / "probe"
        probe.mkdir()
        app = launch([str(Path(binary).resolve()), str(fixture), str(probe), mode], "application")
        wait_for(lambda: (probe / "ready").exists() or (probe / "done").exists() or app.poll() is not None)
        if not (probe / "ready").exists():
            raise RuntimeError("Application did not reach focus acceptance; see application.log/probe/error.txt")
        def lifecycle(expected):
            state = probe / "lifecycle"
            wait_for(lambda: state.exists() and state.read_text() == expected)

        lifecycle("resumed")
        for interval in [0.7, 0.7, 15, 0.7]:
            chord(56, 15)  # Real Alt-Tab through Mutter, not a framework lifecycle call.
            lifecycle("inactive")
            time.sleep(interval)
            chord(56, 15)
            lifecycle("resumed")
        if transitions == "minimize":
            chord(125, 35)  # Real GNOME Super-H minimize.
            time.sleep(1)
            chord(56, 15)  # Real Alt-Tab restores the minimized application.
        if transitions == "full":
            chord(125, 35)  # GNOME Super-H minimize.
            time.sleep(1)
            if backend == "x11":
                os.environ.update({key: env[key] for key in ("DISPLAY", "XAUTHORITY", "GDK_BACKEND") if key in env})
                from application_close_smoke import Desktop
                desktop = Desktop()
                try:
                    desktop.Gdk.init([])
                    window = desktop.window(app.pid, require_mapped=True, require_normal=True)
                    if window is not None:
                        # Some disposable desktops have no Super-H binding.
                        # Send the native WM iconify request to this owned XID.
                        window.iconify()
                        desktop.Gdk.Display.get_default().flush()
                        actions.append({"time": time.monotonic(), "native-iconify": True})
                    # Observe real native unmapping, not merely focus loss.
                    wait_for(lambda: desktop.window(app.pid, require_mapped=False, require_normal=True) is not None
                             and desktop.window(app.pid, require_mapped=True, require_normal=True) is None)
                    actions.append({"time": time.monotonic(), "minimized-unmapped": True})
                finally:
                    desktop.dispose()
            (probe / "restore-window").touch()
            wait_for(lambda: (probe / "window-restored").exists() or (probe / "done").exists())
            lifecycle("resumed")
        if transitions == "full" and backend == "x11":
            # Switch away again, then reactivate only by clicking native chrome.
            chord(56, 15)
            lifecycle("inactive")
            os.environ.update({key: env[key] for key in ("DISPLAY", "XAUTHORITY", "GDK_BACKEND") if key in env})
            from application_close_smoke import Desktop
            desktop = Desktop()
            try:
                desktop.Gdk.init([])
                window = desktop.window(app.pid, require_mapped=True, require_normal=True)
                if window is None:
                    raise RuntimeError("Missing owned application window")
                _, origin_x, origin_y = window.get_origin()
                call(session, interface, "NotifyPointerMotionRelative", GLib.Variant("(dd)", (-3000., -3000.)))
                call(session, interface, "NotifyPointerMotionRelative", GLib.Variant("(dd)", (float(origin_x + window.get_width() / 2), float(origin_y + 16))))
                call(session, interface, "NotifyPointerButton", GLib.Variant("(ib)", (272, True)))
                call(session, interface, "NotifyPointerButton", GLib.Variant("(ib)", (272, False)))
                actions.append({"time": time.monotonic(), "chrome-reactivation": True})
                lifecycle("resumed")
            finally:
                desktop.dispose()
        elif transitions == "full":
            chord(56, 15)
            chord(56, 15)
        time.sleep(1)
        (probe / "returned").touch()
        wait_for(lambda: (probe / "type-ready").exists() or (probe / "done").exists())
        key(44, True)  # Real native Z key; no tapping/refocusing the editable.
        key(44, False)
        time.sleep(0.5)
        (probe / "typed").touch()
        wait_for(lambda: (probe / "done").exists())
        (output / "actions.json").write_text(json.dumps({"backend": backend, "coverage": transitions, "documentFormat": document_format, "actions": actions}, indent=2))
        result = json.loads((probe / "result.json").read_text())
        if transitions == "minimize":
            frames = json.loads((probe / "frames.json").read_text())
            if not any(frame["lifecycle"] == "hidden" for frame in frames):
                raise RuntimeError("Minimize did not reach the hidden lifecycle state")
        print(json.dumps(result))
        if not all(value for group in result.values() for value in group.values()):
            raise RuntimeError("Native acceptance assertions failed")
    finally:
        for process in reversed(processes):
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=8)
        for log in logs:
            log.close()


if __name__ == "__main__":
    if sys.argv[1:] == ["--companion"]:
        companion()
    else:
        run(*sys.argv[1:])

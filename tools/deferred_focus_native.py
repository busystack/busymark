#!/usr/bin/python3
"""Run focus races on an owned desktop with profiles isolated before D-Bus.

Usage: python3 tools/deferred_focus_native.py BINARY NEW_OUTPUT BACKEND MODE
MODE: deferred-dialog, deferred-selection, deferred-selection-table, or editor.
The existing compositor driver performs the actual native input/lifecycle work.
"""
import json
import os
from pathlib import Path
import subprocess
import sys


def run(binary, output, backend, mode):
    if backend not in ["x11", "wayland"] or mode not in [
        "deferred-dialog", "deferred-selection", "deferred-selection-table", "editor"
    ]:
        raise ValueError("Unsupported native focus scenario")
    if mode.startswith("deferred-selection") and backend != "x11":
        raise ValueError("Native selection gesture requires the owned X11 window")
    output = Path(output).resolve()
    if len(os.fsencode(output / "desktop/runtime/focus-acceptance")) >= 108:
        raise ValueError("Use a shorter output path for the Wayland Unix socket")
    output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ)
    for key, name in [("XDG_RUNTIME_DIR", "runtime"), ("XDG_CONFIG_HOME", "config"),
                      ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                      ("XDG_STATE_HOME", "state")]:
        directory = output / name
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    for key in ["DISPLAY", "WAYLAND_DISPLAY", "XAUTHORITY", "SESSION_MANAGER",
                "GNOME_KEYRING_PID", "GNOME_KEYRING_CONTROL", "SSH_AUTH_SOCK", "GPG_AGENT_INFO"]:
        env.pop(key, None)
    command = [
        "/usr/bin/dbus-run-session", "--", "/usr/bin/python3",
        "tools/focus_restoration_native.py", str(Path(binary).resolve()),
        str(output / "desktop"), backend, mode, "alt-tab",
    ]
    with (output / "supervisor.log").open("w") as log:
        supervisor = subprocess.Popen(
            ["/usr/bin/python3", "tools/run_owned_fixture.py", "--report",
             str(output / "ownership.json"), "--duration", "240", "--", *command],
            env=env, stdin=subprocess.PIPE, stdout=log, stderr=subprocess.STDOUT)
        try:
            status = supervisor.wait(timeout=260)
        finally:
            if supervisor.poll() is None:
                supervisor.stdin.write(b"stop\n")
                supervisor.stdin.flush()
                supervisor.wait(timeout=15)
            supervisor.stdin.close()
    result_file = output / "desktop/probe/result.json"
    result = json.loads(result_file.read_text()) if result_file.exists() else None
    passed = status == 0 and result is not None and all(
        value for group in result.values() for value in group.values())
    print(json.dumps({"backend": backend, "mode": mode, "exitCode": status,
                      "passed": passed, "result": result}))
    if not passed:
        raise RuntimeError("Native focus acceptance failed; inspect retained output")


if __name__ == "__main__":
    run(*sys.argv[1:])

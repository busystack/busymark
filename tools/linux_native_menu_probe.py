#!/usr/bin/python3
"""GTK accessibility/X11 driver for the disposable TOC acceptance app.

Run only inside the probe's dedicated Xvfb and D-Bus session. It targets the
given process, never another BusyMark window or the user's desktop.
"""
import ctypes
import json
import os
import sys
import time

import gi

gi.require_version("Atspi", "2.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Atspi, Gdk  # noqa: E402


def app_for_pid(pid):
    desktop = Atspi.get_desktop(0)
    for index in range(desktop.get_child_count()):
        app = desktop.get_child_at_index(index)
        if app.get_process_id() == pid:
            return app
    raise RuntimeError(f"No accessible application for probe pid {pid}")


def walk(node, depth=0):
    if depth > 30:
        return
    yield node
    for index in range(node.get_child_count()):
        yield from walk(node.get_child_at_index(index), depth + 1)


def visible_dialog_nodes(app):
    dialogs = [node for node in walk(app)
               if node.get_role() == Atspi.Role.DIALOG
               and node.get_state_set().contains(Atspi.StateType.SHOWING)]
    if len(dialogs) != 1:
        raise RuntimeError(f"Expected one visible native dialog, got {len(dialogs)}")
    return list(walk(dialogs[0]))


def key(name):
    x11 = ctypes.CDLL("libX11.so.6")
    xtst = ctypes.CDLL("libXtst.so.6")
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
    x11.XKeysymToKeycode.restype = ctypes.c_uint
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
    xtst.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
    display = x11.XOpenDisplay(None)
    if not display:
        raise RuntimeError("Probe X11 display unavailable")
    code = x11.XKeysymToKeycode(display, Gdk.keyval_from_name(name))
    for pressed in (1, 0):
        xtst.XTestFakeKeyEvent(display, code, pressed, 0)
    x11.XFlush(display)
    x11.XCloseDisplay(display)


def main():
    if os.environ.get("BUSYMARK_NATIVE_PROBE") != "1":
        raise RuntimeError("Use an isolated probe session, not the user's desktop")
    if os.environ.get("GDK_BACKEND") != "x11":
        raise RuntimeError("Explicit GDK_BACKEND=x11 is required for the isolated display")
    pid, command, *args = sys.argv[1:]
    app = app_for_pid(int(pid))
    if command == "capture":
        root = Gdk.get_default_root_window()
        capture = Gdk.pixbuf_get_from_window(root, 0, 0, root.get_width(), root.get_height())
        capture.savev(args[0], "png", [], [])
    elif command == "key":
        key(args[0])
    elif command == "inspect":
        print(json.dumps([
            {"name": node.get_name(), "role": node.get_role_name(),
             "showing": node.get_state_set().contains(Atspi.StateType.SHOWING),
             "enabled": node.get_state_set().contains(Atspi.StateType.ENABLED)}
            for node in walk(app)
        ], ensure_ascii=False))
    elif command == "choose":
        matches = [node for node in walk(app)
                   if node.get_name() == args[0]
                   and node.get_role() in (Atspi.Role.MENU, Atspi.Role.MENU_ITEM,
                                           Atspi.Role.RADIO_MENU_ITEM, Atspi.Role.CHECK_MENU_ITEM)
                   and node.get_state_set().contains(Atspi.StateType.SHOWING)]
        if len(matches) != 1:
            raise RuntimeError(f"Expected one visible native menu item {args[0]!r}, got {len(matches)}")
        item = matches[0]
        if not item.get_state_set().contains(Atspi.StateType.ENABLED):
            raise RuntimeError(f"Native menu item disabled: {args[0]}")
        submenu = item.get_role() == Atspi.Role.MENU
        action = item.get_action_iface()
        if not action.do_action(0):
            raise RuntimeError(f"Could not activate native menu item: {args[0]}")
        time.sleep(0.3)
        print("submenu" if submenu else "command")
    elif command == "activate":
        matches = [node for node in visible_dialog_nodes(app)
                   if node.get_name() == args[0]
                   and node.get_role() in (Atspi.Role.PUSH_BUTTON,
                                           Atspi.Role.TOGGLE_BUTTON,
                                           Atspi.Role.LINK)
                   and node.get_state_set().contains(Atspi.StateType.SHOWING)]
        if len(matches) != 1:
            raise RuntimeError(f"Expected one visible native control {args[0]!r}, got {len(matches)}")
        control = matches[0]
        if not control.get_state_set().contains(Atspi.StateType.ENABLED):
            raise RuntimeError(f"Native control disabled: {args[0]}")
        if not control.get_action_iface().do_action(0):
            raise RuntimeError(f"Could not activate native control: {args[0]}")
        time.sleep(0.3)
    elif command == "has":
        matches = [node for node in visible_dialog_nodes(app)
                   if node.get_name() == args[0]
                   and node.get_state_set().contains(Atspi.StateType.SHOWING)]
        print("true" if matches else "false")
    elif command == "set-entry":
        index_arg, value = args[0].split("\n", 1)
        entries = [node for node in visible_dialog_nodes(app)
                   if node.get_role() in (Atspi.Role.ENTRY, Atspi.Role.TEXT)
                   and node.get_state_set().contains(Atspi.StateType.SHOWING)]
        index = int(index_arg)
        if index < 0 or index >= len(entries):
            raise RuntimeError(f"Visible native entry {index} not found; got {len(entries)}")
        if not entries[index].set_text_contents(value):
            raise RuntimeError(f"Could not set native entry {index}")
        time.sleep(0.3)
    else:
        raise RuntimeError(f"Unknown probe command {command}")


if __name__ == "__main__":
    main()

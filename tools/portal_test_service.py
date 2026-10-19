#!/usr/bin/python3
"""Owned portal fixture. The caller must provide an isolated D-Bus address.

Control messages on stdin and events on stdout are JSON lines. No desktop bus
address is inherited implicitly. Held replies capture their old value so tests
can deliver a newer signal before releasing the initial response.
"""
import argparse
import json
import os
import socket
import sys

import gi
gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--address', required=True)
    parser.add_argument('--hold', choices=['none', 'getall', 'read', 'name'], default='none')
    parser.add_argument('--malformed', action='store_true')
    parser.add_argument('--fail', action='store_true')
    parser.add_argument('--malformed-key')
    parser.add_argument('--fail-key')
    parser.add_argument('--omit-key')
    parser.add_argument('--scale', type=float, default=1.5)
    parser.add_argument('--control-socket')
    args = parser.parse_args()
    control = None
    source, output = sys.stdin, sys.stdout
    if args.control_socket:
        control = socket.socket(socket.AF_UNIX)
        control.connect(args.control_socket)
        source = control.makefile('r')
        output = control.makefile('w', buffering=1)
    connection = Gio.DBusConnection.new_for_address_sync(
        args.address, Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT |
        Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION, None, None)
    values = {
        ('org.gnome.desktop.interface', 'accent-color'): GLib.Variant('s', 'purple'),
        ('org.freedesktop.appearance', 'accent-color'): GLib.Variant('(ddd)', (.2, .4, .6)),
        ('org.gnome.desktop.interface', 'clock-format'): GLib.Variant('s', '12h'),
        ('org.freedesktop.appearance', 'color-scheme'): GLib.Variant('u', 1),
        ('org.gnome.desktop.interface', 'enable-animations'): GLib.Variant('b', False),
        ('org.gnome.desktop.interface', 'gtk-theme'): GLib.Variant('s', 'Yaru-dark'),
        ('org.gnome.desktop.a11y.interface', 'high-contrast'): GLib.Variant('b', True),
        ('org.gnome.desktop.interface', 'text-scaling-factor'): GLib.Variant('d', args.scale),
    }
    xml = '''<node>
      <interface name="org.freedesktop.portal.Settings">
        <method name="Read"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="out"/></method>
        <signal name="SettingChanged"><arg type="s"/><arg type="s"/><arg type="v"/></signal>
      </interface>
      <interface name="org.freedesktop.DBus.Properties">
        <method name="GetAll"><arg type="s" direction="in"/><arg type="a{sv}" direction="out"/></method>
      </interface>
    </node>'''
    node = Gio.DBusNodeInfo.new_for_xml(xml)
    pending = []
    hold = args.hold
    name = 'org.freedesktop.portal.Desktop'
    path = '/org/freedesktop/portal/desktop'
    loop = GLib.MainLoop()

    def emit(**event):
        print(json.dumps(event), file=output, flush=True)

    def respond(call, response, failed=False):
        if args.fail or failed:
            call.return_dbus_error('org.freedesktop.portal.Error.Failed', 'Controlled failure')
        else:
            call.return_value(response)

    def method(_connection, _sender, _path, _interface, member, parameters, call):
        key = tuple(parameters.unpack())
        if member == 'Read':
            value = values.get(key)
            if value is None or key[1] == args.omit_key:
                emit(event='request', member=member, key=key, held=False)
                call.return_dbus_error('org.freedesktop.portal.Error.NotFound', 'Controlled missing key')
                return
            payload = value if args.malformed or key[1] == args.malformed_key else GLib.Variant('v', value)
            response = GLib.Variant('(v)', (payload,))
        elif member == 'GetAll':
            response = GLib.Variant('(a{sv})', ({},))
        else:
            call.return_dbus_error('org.freedesktop.DBus.Error.UnknownMethod', member)
            return
        held = hold == member.lower()
        if held:
            pending.append((call, response, member == 'Read' and key[1] == args.fail_key))
        emit(event='request', member=member, key=key, held=held)
        if not held:
            respond(call, response, member == 'Read' and key[1] == args.fail_key)

    registrations = [connection.register_object(path, interface, method, None, None)
                     for interface in node.interfaces]

    def own():
        reply = connection.call_sync('org.freedesktop.DBus', '/org/freedesktop/DBus',
            'org.freedesktop.DBus', 'RequestName', GLib.Variant('(su)', (name, 0)),
            GLib.VariantType.new('(u)'), Gio.DBusCallFlags.NONE, -1, None)
        assert reply.unpack()[0] in (1, 4)
        emit(event='owned', uniqueName=connection.get_unique_name())

    def command(message):
        nonlocal hold
        action = message['action']
        if action == 'release':
            hold = 'none'
            for call, response, failed in pending:
                respond(call, response, failed)
            pending.clear()
        elif action == 'change':
            key = (message['namespace'], message['key'])
            value = GLib.Variant(message['type'], message['value'])
            values[key] = value
            connection.emit_signal(None, path, 'org.freedesktop.portal.Settings',
                'SettingChanged', GLib.Variant('(ssv)', (*key, value)))
            connection.flush_sync(None)
        elif action == 'own':
            own()
        elif action == 'drop':
            connection.call_sync('org.freedesktop.DBus', '/org/freedesktop/DBus',
                'org.freedesktop.DBus', 'ReleaseName', GLib.Variant('(s)', (name,)),
                GLib.VariantType.new('(u)'), Gio.DBusCallFlags.NONE, -1, None)
        elif action == 'quit':
            loop.quit()
        else:
            raise AssertionError(action)
        emit(event='command', action=action)
        return action != 'quit'

    control_buffer = b''

    def read_commands(_fd, condition):
        nonlocal control_buffer
        data = os.read(source.fileno(), 65536)
        if not data:
            loop.quit()
            return False
        control_buffer += data
        assert len(control_buffer) <= 1024 * 1024
        while b'\n' in control_buffer:
            line, control_buffer = control_buffer.split(b'\n', 1)
            if not command(json.loads(line)):
                return False
        return True

    # Read the descriptor directly: TextIOWrapper.readline may prefetch a
    # second command without leaving descriptor readiness for another source.
    GLib.io_add_watch(source, GLib.IOCondition.IN | GLib.IOCondition.HUP, read_commands)
    if hold != 'name':
        own()
    emit(event='ready', pid=os.getpid())
    loop.run()
    for call, _, _ in pending:
        call.return_dbus_error('org.freedesktop.portal.Error.Cancelled', 'Fixture stopping')
    for registration in registrations:
        connection.unregister_object(registration)
    connection.close_sync(None)
    if control:
        control.close()


if __name__ == '__main__':
    main()

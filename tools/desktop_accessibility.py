#!/usr/bin/python3
"""Find and activate a named control owned by one application on AT-SPI."""

import argparse
import time

import gi

gi.require_version('Atspi', '2.0')
from gi.repository import Atspi, GLib


def descendants(node, depth=0):
    yield node
    if depth < 24:
        for index in range(min(node.get_child_count(), 180)):
            child = node.get_child_at_index(index)
            if child is not None:
                yield from descendants(child, depth + 1)


def application(pid):
    desktop = Atspi.get_desktop(0)
    for index in range(desktop.get_child_count()):
        node = desktop.get_child_at_index(index)
        if node is not None and node.get_process_id() == pid:
            return node


def observe(args):
    app = application(args.pid)
    if app is None:
        return False
    if args.operation == 'present':
        return True
    found = False
    for node in descendants(app):
        role = node.get_role_name()
        name = node.get_name()
        if args.operation == 'dump':
            if name:
                print(f'{role} {name!r}')
            continue
        if args.role is not None and role != args.role:
            continue
        if args.label and args.label not in (name, node.get_description()):
            continue
        found = True
        if args.operation == 'gone':
            continue
        if args.operation == 'click':
            actions = node.get_action_iface()
            if actions is None or not actions.get_n_actions() or not actions.do_action(0):
                continue
        if args.operation == 'focused' and not node.get_state_set().contains(Atspi.StateType.FOCUSED):
            continue
        print(role if role == 'password text' else f'{role} {name!r}')
        return True
    return args.operation == 'dump' or (args.operation == 'gone' and not found)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pid', type=int)
    parser.add_argument('operation', choices=['present', 'wait', 'gone', 'click', 'focused', 'dump'])
    parser.add_argument('label')
    parser.add_argument('seconds', type=float)
    parser.add_argument('--role')
    args = parser.parse_args()
    Atspi.init()
    deadline = time.monotonic() + args.seconds
    while True:
        try:
            if observe(args):
                return 0
        except GLib.Error:
            # Flutter can replace an accessible node between reads.
            pass
        if time.monotonic() >= deadline:
            raise SystemExit(f'AT-SPI {args.operation} did not settle: {args.label!r}')
        time.sleep(0.15)


if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""Exercise the actual release app's resource menus on an owned X11 desktop."""

import argparse
import json
import os
from pathlib import Path
import tempfile

from git_native_smoke import DesktopRun
from view_selector_native_acceptance import menu_rows, wait_document_text

NEW = ['New Markdown File', 'New Nextcloud Note', 'New Writerside Project']
OPEN = ['Open Markdown File', 'Open Folder or Writerside Project', 'Browse Nextcloud Notes']


def run(binary, output, theme, remapped):
    output.mkdir(parents=True)
    with tempfile.TemporaryDirectory(prefix='busymark-resource-menu-') as fixture:
        root = Path(fixture)
        document = root / 'example.md'
        original = '# Native menu acceptance\n'
        document.write_text(original)
        settings = output / 'xdg_data_home/io.busystack.busymark/settings.json'
        settings.parent.mkdir(parents=True)
        values = {'localeTag': 'en', 'themeModePreference': theme, 'autoSave': False,
                  'sidebarVisible': True, 'documentViewMode': 'source'}
        if remapped:
            values['shortcutOverrides'] = {
                command: {'key': key, 'control': False, 'shift': False,
                          'alt': False, 'meta': False}
                for command, key in [('file.newDocument', 0x100000806),
                                     ('file.open', 0x100000808),
                                     ('view.sidebarSelector', 0x100000807)]}
        settings.write_text(json.dumps(values))
        os.environ['BUSYSTACK_NATIVE_PLAIN_DIRECTORY'] = '1'
        os.environ['BUSYSTACK_NATIVE_THEME'] = theme
        desktop = DesktopRun(binary, output, root, 1.0)
        new_key = ('F6',) if remapped else ('Control_L', 'n')
        open_key = ('F8',) if remapped else ('Control_L', 'o')
        sidebar_key = ('F7',) if remapped else ('Control_L', 'Shift_L', 'F9')
        new_name = 'New Menu (F6)' if remapped else 'New Menu (Ctrl+N)'
        open_name = 'Open Menu (F8)' if remapped else 'Open Menu (Ctrl+O)'

        def snapshot(name, **kwargs):
            desktop.send('accessibility', name=name, **kwargs)
            return json.loads((output / f'{name}-accessibility.json').read_text())['nodes']

        def bounds(label, role):
            rows = snapshot('_control', boundsName=label, boundsRole=role)
            matches = [row['bounds'] for row in rows if row['name'] == label and
                       row['role'] == role and 'bounds' in row]
            if len(matches) != 1 or any(value <= 0 for value in matches[0][2:]):
                raise RuntimeError(f'Missing visible bounds for {label}: {matches}')
            return matches[0]

        def menu(name, entries):
            visible = menu_rows(desktop.wait_accessible(
                lambda rows: bool(menu_rows(rows)), name))
            ordered = sorted(visible, key=lambda row: row['indexInParent'])
            if [row['name'] for row in ordered] != entries:
                raise RuntimeError(f'{name}: wrong menu entries: {ordered}')
            return bounds(entries[0], ordered[0]['role'])

        def closed():
            desktop.wait_accessible(lambda rows: not menu_rows(rows), '_menu-closed')

        def visible(*names):
            desktop.wait_accessible(
                lambda rows: set(names) <= {row['name'].split('\n', 1)[0] for row in rows}, '_controls-ready')

        try:
            visible(new_name, open_name)
            desktop.key('Alt_L', 'Left')
            visible('Home', 'Recent', 'New Markdown File', 'Search', new_name, open_name, 'Main menu')
            desktop.capture('welcome-header')

            for name, key, entries in [(open_name, open_key, OPEN), (new_name, new_key, NEW)]:
                # The capture shows the header controls relative to the right
                # window edge. Flutter's AT-SPI virtual buttons expose names
                # and roles, and the opened GTK rows supply measured bounds.
                right_inset = 228 if name == open_name else 188
                desktop.send('click', x=desktop.width-right_inset, y=27)
                pointer = menu('_pointer-menu', entries)
                desktop.key('Escape')
                closed()
                desktop.send('key', names=list(key), pressed=True)
                try:
                    keyboard = menu('_held-menu', entries)
                    if pointer != keyboard:
                        raise RuntimeError(f'Pointer and keyboard popup geometry differs: {pointer}, {keyboard}')
                    if len(key) > 1:
                        desktop.send('key', names=list(key[:-1]), pressed=False)
                    # Let the X server repeat the opening key with modifiers up.
                    desktop.send('wait', seconds=1)
                    menu('_after-repeat', entries)
                    desktop.capture('open-menu' if entries == OPEN else 'new-menu')
                finally:
                    desktop.send('key', names=[key[-1]], pressed=False)
                desktop.key('Escape')
                closed()

            desktop.send('resize', width=560, height=700)
            desktop.key('F9')
            desktop.key(*sidebar_key)
            menu('_welcome-sidebar', ['Recent'])
            desktop.key('e')
            closed()
            visible('Home', 'Recent')
            desktop.capture('narrow-welcome')
            desktop.key('F9')
            desktop.send('resize', width=1050, height=800)

            # Reopen the fixture through Recent, then put the caret in Source.
            desktop.key(*sidebar_key)
            menu('_welcome-sidebar', ['Recent'])
            desktop.key('Escape')
            closed()
            def is_recent_fixture(row):
                return (row['role'] == 'push button' and row['enabled'] and
                        row['name'].split('\n', 1)[0] == root.name)

            rows = desktop.wait_accessible(
                lambda rows: any(map(is_recent_fixture, rows)), '_recent-fixture')
            recent = next(row['name'] for row in rows if is_recent_fixture(row))
            desktop.send('activateAccessible', name=recent, role='push button')
            wait_document_text(desktop, original)
            desktop.send('click', x=402, y=125)
            desktop.key('Control_L', 'End')
            desktop.key(*new_key)
            menu('_editor-cancel', NEW)
            desktop.key('Escape')
            closed()
            desktop.send('text', value='editor-focus')
            wait_document_text(desktop, original + 'editor-focus')

            desktop.key(*new_key)
            menu('_create-from-source', NEW)
            desktop.key('m')
            closed()
            desktop.send('text', value='first-keystrokes')
            wait_document_text(desktop, 'first-keystrokes')
            desktop.capture('workspace-new-source')
            desktop.send('resize', width=600, height=730)
            desktop.key(*sidebar_key)
            desktop.wait_accessible(
                lambda rows: any(row['name'] == 'Recent' and row['showing']
                                 for row in menu_rows(rows)), '_narrow-workspace-selector')
            desktop.key('e')
            closed()
            visible('Recent', new_name, open_name, 'Main menu')
            desktop.capture('narrow-workspace')
            desktop.send('resize', width=1050, height=800)

            desktop.key(*open_key)
            menu('_workspace-open', OPEN)
            desktop.key('Down')
            desktop.key('Escape')
            closed()
            if document.read_text() != original:
                raise RuntimeError('Menu open, cancellation or creation altered the original file')
            for index in range(2):
                desktop.key('Control_L', 'w')
                visible('Discard')
                desktop.send('activateAccessible', name='Discard', role='push button')
                desktop.wait_accessible(
                    lambda rows: not any(row['name'] == 'Discard' for row in rows),
                    f'_discard-closed-{index}')
            desktop.close()
        finally:
            if desktop.process.poll() is None:
                desktop.process.stdin.close()
                desktop.process.wait(timeout=40)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    for theme, remapped in [('light', False), ('dark', True)]:
        run(args.binary.resolve(), args.output.resolve() / theme, theme, remapped)


if __name__ == '__main__':
    main()

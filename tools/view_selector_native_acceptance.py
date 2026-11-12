#!/usr/bin/env python3
"""Real keyboard acceptance using the existing sealed-build/private-desktop gates.

Run from BusyMark: python3 tools/view_selector_native_acceptance.py BINARY OUTPUT
No toolkit mocks, synthetic Flutter events, or bypasses of native provenance.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from git_native_smoke import DesktopRun
from sidebar_native_acceptance import wait_state

SIDEBAR = {'F': 'Files', 'T': 'Table of Contents', 'O': 'Outline', 'C': 'Commit',
           'G': 'Git Log', 'L': 'Local History', 'B': 'Clipboard History',
           'R': 'References'}
CONTENT = {'E': 'Editor', 'S': 'Source', 'R': 'Reading', 'D': 'Dual'}


def menu_rows(rows):
    return [row for row in rows if row['showing'] and row['role'] in
            {'check menu item', 'menu item'}]


def run(binary, output, writerside, git, remapped):
    output.mkdir(parents=True)
    root = Path(tempfile.mkdtemp(prefix='busymark-selector-')) / 'workspace'
    (output / 'workspace-path.txt').write_text(str(root))
    if writerside:
        shutil.copytree('test/fixtures/writerside/toc_ui', root)
        document = root / 'topics/home.md'
    else:
        root.mkdir()
        document = root / 'home.md'
    original = '# Selector acceptance\n\n## Heading\n\nDocument unchanged.\n'
    document.write_text(original)
    if git:
        def command(*args):
            subprocess.run(['git', '-C', str(root), *args], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        command('init', '-b', 'main')
        command('config', 'user.name', 'Selector acceptance')
        command('config', 'user.email', 'selector@example.invalid')
        command('add', '.')
        command('commit', '-m', 'Native selector fixture')
    settings = output / 'xdg_data_home/io.busystack.busymark/settings.json'
    settings.parent.mkdir(parents=True)
    options = {'localeTag': 'en', 'themeModePreference': 'light', 'autoSave': False,
               'sidebarVisible': True, 'documentViewMode': 'source',
               'trustedGitWorkspacePaths': [str(root)] if git else []}
    if remapped:
        # Serialize through the same persisted keymap schema as Settings.
        options['shortcutOverrides'] = {
            'view.sidebarSelector': {'key': 0x100000806, 'control': False,
                                     'shift': False, 'alt': False, 'meta': False},
            'view.contentSelector': {'key': 0x100000808, 'control': False,
                                     'shift': False, 'alt': False, 'meta': False}}
    settings.write_text(json.dumps(options))
    previous_plain = os.environ.get('BUSYSTACK_NATIVE_PLAIN_DIRECTORY')
    os.environ['BUSYSTACK_NATIVE_PLAIN_DIRECTORY'] = '0' if git else '1'
    try:
        desktop = DesktopRun(binary, output, root, 1.0)
    finally:
        if previous_plain is None:
            os.environ.pop('BUSYSTACK_NATIVE_PLAIN_DIRECTORY', None)
        else:
            os.environ['BUSYSTACK_NATIVE_PLAIN_DIRECTORY'] = previous_plain
    sidebar_key = ('F6',) if remapped else ('Control_L', 'Shift_L', 'F9')
    content_key = ('F8',) if remapped else ('Control_L', 'Shift_L', 'F10')
    try:
        desktop.key('Control_L', 'Shift_L', 'd')
        desktop.send('text', value='home.md')
        desktop.key('Return')
        desktop.send('wait', seconds=2)

        def open_menu(key, expected=None):
            desktop.key(*key)
            rows = wait_state(desktop, lambda rows: bool(menu_rows(rows)), '_selector-open')
            if expected is not None:
                actual = [row['name'] for row in menu_rows(rows)]
                if set(actual) != set(expected):
                    raise RuntimeError(f'Wrong native selector or context-menu conflict: {actual}')
            return menu_rows(rows)

        def closed():
            wait_state(desktop, lambda rows: not menu_rows(rows), '_selector-closed')

        desktop.key('F9')
        open_menu(sidebar_key)
        desktop.capture('hidden-sidebar-revealed')
        desktop.key('Escape'); closed()
        expected_sidebar = 'Sidebar view (F6)' if remapped else 'Sidebar view (Ctrl+Shift+F9)'
        expected_content = 'Content view (F8)' if remapped else 'Content view (Ctrl+Shift+F10)'
        wait_state(desktop, lambda rows: all(any(row['name'] == label and row['showing'] for row in rows)
                   for label in [expected_sidebar, expected_content, 'Hide sidebar (F9)']), '_selector-tooltips')
        for letter, label in SIDEBAR.items():
            rows = open_menu(sidebar_key)
            matching = [row for row in rows if row['name'] == label]
            available = (letter != 'T' or writerside) and (letter not in 'CG' or git)
            if available and (len(matching) != 1 or not matching[0]['enabled']):
                raise RuntimeError('Available native view is missing or disabled: ' + label)
            if not available and any(row['enabled'] for row in matching):
                raise RuntimeError('Unavailable native view can activate: ' + label)
            desktop.key(letter.lower())
            if available:
                closed()
                desktop.capture('sidebar-' + letter)
            else:
                wait_state(desktop, lambda rows: bool(menu_rows(rows)), '_unavailable-still-open')
                desktop.key('Escape'); closed()
        # Arrow/Enter activation and checked state use GTK's existing menu.
        open_menu(sidebar_key); desktop.key('Home'); desktop.key('Down')
        desktop.key('Return'); closed()
        for letter, label in CONTENT.items():
            open_menu(content_key, CONTENT.values())
            desktop.key(letter.lower()); closed()
            desktop.capture('content-' + letter)
        open_menu(content_key, CONTENT.values()); desktop.key('s'); closed()
        for number in '123456':
            desktop.key('Control_L', number)
            if number in '1234': desktop.key('Control_L', 'Shift_L', number)
        rows = open_menu(content_key, CONTENT.values())
        if [row['name'] for row in rows if row['checked']] != ['Source']:
            raise RuntimeError('Retired numeric shortcuts changed Content View')
        desktop.key('Escape'); closed()
        # Dismiss from a real focused source field, then type at its saved caret.
        desktop.send('click', x=desktop.width * 3 // 4, y=230)
        desktop.key('Control_L', 'End')
        open_menu(content_key, CONTENT.values()); desktop.key('Escape'); closed()
        desktop.send('text', value='FOCUS_SENTINEL')
        desktop.key('Control_L', 's'); desktop.send('wait', seconds=.5)
        if document.read_text() != original + 'FOCUS_SENTINEL':
            raise RuntimeError('Menu dismissal lost the document caret/focus')
        desktop.key('Control_L', 'z'); desktop.key('Control_L', 's')
        desktop.send('wait', seconds=.5)
        if document.read_text() != original:
            raise RuntimeError('Mnemonic key reached the document editor or undo failed')
        rows = open_menu(('Shift_L', 'F10'))
        if set(row['name'] for row in rows) == set(CONTENT.values()):
            raise RuntimeError('Shift+F10 opened Content View instead of the focused context menu')
        desktop.capture('standard-shift-f10'); desktop.key('Escape'); closed()
        open_menu(content_key, CONTENT.values()); desktop.key('Escape'); closed()
        if git:
            desktop.sidebar_view('C')
            desktop.key('F5'); desktop.key('Control_L', 'Return')
            desktop.key('Control_L', 'Shift_L', 'b')
            desktop.key('Control_L', 'Shift_L', 'p')
            wait_state(desktop, lambda rows: any(row['focused'] and row['role'] == 'text'
                       for row in rows), '_application-palette-focused')
            desktop.capture('git-application-command-palette')
            desktop.key('Escape')
        desktop.capture('final')
        desktop.send('quit')
        if desktop.process.wait(timeout=30) != 0:
            raise RuntimeError('Native desktop acceptance failed')
        (output / 'selector-result.json').write_text(json.dumps({'passed': True,
            'writerside': writerside, 'git': git, 'remapped': remapped}))
    finally:
        if desktop.process.poll() is None:
            desktop.process.terminate(); desktop.process.wait(timeout=20)
        desktop.log.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    results = []
    for writerside, git, remapped in [(False, False, False), (False, True, False),
            (True, False, False), (True, True, False), (True, True, True)]:
        name = f'{"writerside" if writerside else "ordinary"}-{"git" if git else "plain"}-{"custom" if remapped else "default"}'
        try:
            run(args.binary.resolve(), args.output.resolve() / name, writerside, git, remapped)
            results.append({'case': name, 'passed': True})
        except Exception as error:
            results.append({'case': name, 'passed': False, 'error': str(error)})
    (args.output / 'matrix-result.json').write_text(json.dumps(results, indent=2))
    if not all(row['passed'] for row in results):
        raise SystemExit('Native selector acceptance failed; inspect matrix-result.json')


if __name__ == '__main__':
    main()

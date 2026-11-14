#!/usr/bin/env python3
"""Real keyboard acceptance using the existing sealed-build/private-desktop gates.

Run from BusyMark: python3 tools/view_selector_native_acceptance.py BINARY OUTPUT
No toolkit mocks, synthetic Flutter events, or bypasses of native provenance.
"""
import argparse
from concurrent.futures import ProcessPoolExecutor
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from git_native_smoke import DesktopRun
from sidebar_native_acceptance import wait_state

SIDEBAR = {'F': 'Files', 'T': 'Table of Contents', 'O': 'Outline', 'C': 'Commit',
           'G': 'Git Log', 'L': 'Local History', 'B': 'Clipboard History',
           'R': 'References'}
CONTENT = {'E': 'Editor', 'S': 'Source', 'R': 'Reading', 'D': 'Dual'}


def menu_rows(rows):
    return [row for row in rows if row['showing'] and row['role'] in
            {'check menu item', 'menu item'}]


def wait_document_text(desktop, expected):
    # XTest submission and Flutter's editable/model publication are asynchronous.
    # Observe the actual source text before invoking Save; never resend input.
    wait_state(desktop, lambda rows: any(row['showing'] and
               row['name'] == expected for row in rows), '_source-text-published')


def wait_saved(document, expected):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if document.read_text() == expected:
            return
        time.sleep(.1)
    raise RuntimeError('Save did not persist the exact expected source text')


def verify_settings(desktop, remapped):
    desktop.key('Control_L', 'Shift_L', 'p')
    wait_state(desktop, lambda rows: any(row['showing'] and row['focused'] and
               row['role'] == 'text' for row in rows), '_command-query-focused')
    desktop.send('text', value='shortcuts')
    wait_state(desktop, lambda rows: any(row['showing'] and
               'Keyboard Shortcuts' in row['name'] for row in rows), '_shortcut-command-result')
    desktop.key('Return')
    wait_state(desktop, lambda rows: any(row['showing'] and
               'Keyboard Shortcuts' in row['name'] for row in rows), '_settings-open')
    sidebar = 'F6' if remapped else 'Ctrl+Shift+F9'
    content = 'F8' if remapped else 'Ctrl+Shift+F10'
    for _ in range(30):
        desktop.send('accessibility', name='settings-effective-bindings')
        rows = json.loads((desktop.output / 'settings-effective-bindings-accessibility.json').read_text())['nodes']
        visible = '\n'.join(row['name'] for row in rows if row['showing'])
        if all(label in visible for label in ['Sidebar view', 'Content view', sidebar, content]):
            desktop.capture('effective-shortcut-settings')
            desktop.key('Alt_L', 'Left')
            return
        desktop.send('scroll', x=desktop.width * 3 // 4,
                     y=desktop.height * 3 // 4, direction='down', steps=3)
    raise RuntimeError('Settings did not display the effective selector bindings')


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
        # A real Git row lets the shortcut audit focus the Git control without
        # sending editing keys into the retained Source field. This pre-existing
        # fixture change must remain unchanged through native acceptance.
        (root / 'pending.md').write_text('# Pending native fixture\n')
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
        previous_sidebar = 'Files'
        for letter, label in SIDEBAR.items():
            rows = open_menu(sidebar_key)
            if [row['name'] for row in rows if row['checked']] != [previous_sidebar]:
                raise RuntimeError('Sidebar mnemonic did not activate its fixed view')
            matching = [row for row in rows if row['name'] == label]
            available = letter != 'T' or writerside
            if available and (len(matching) != 1 or not matching[0]['enabled']):
                raise RuntimeError('Available native view is missing or disabled: ' + label)
            if not available and any(row['enabled'] for row in matching):
                raise RuntimeError('Unavailable native view can activate: ' + label)
            desktop.key(letter.lower())
            if available:
                closed()
                desktop.capture('sidebar-' + letter)
                previous_sidebar = label
                if letter in 'CG' and not git:
                    wait_state(desktop, lambda rows: all(any(
                        row['showing'] and text in row['name'] for row in rows)
                        for text in [desktop.catalog['gitNotRepositoryMessage'],
                                     desktop.catalog['gitHostInitializeHere'],
                                     desktop.catalog['gitHostCloneRepository2']]),
                        '_non-git-discovery-ready')
            else:
                wait_state(desktop, lambda rows: bool(menu_rows(rows)), '_unavailable-still-open')
                desktop.key('Escape'); closed()
        # Arrow/Enter activation and checked state use GTK's existing menu.
        open_menu(sidebar_key); desktop.key('Home'); desktop.key('Down')
        desktop.key('Return'); closed()
        previous_content = 'Source'
        for letter, label in CONTENT.items():
            rows = open_menu(content_key, CONTENT.values())
            if [row['name'] for row in rows if row['checked']] != [previous_content]:
                raise RuntimeError('Content mnemonic did not activate its fixed view')
            desktop.key(letter.lower()); closed()
            desktop.capture('content-' + letter)
            previous_content = label
        open_menu(content_key, CONTENT.values()); desktop.key('s'); closed()
        for number in '123456':
            desktop.key('Control_L', number)
            if number in '1234': desktop.key('Control_L', 'Shift_L', number)
        rows = open_menu(content_key, CONTENT.values())
        if [row['name'] for row in rows if row['checked']] != ['Source']:
            raise RuntimeError('Retired numeric shortcuts changed Content View')
        desktop.key('Escape'); closed()
        # Dismiss from a real focused source field, then type at its saved caret.
        # Target the visible first source line, rather than empty canvas beyond
        # the editable's measured text width.
        desktop.send('click', x=desktop.width // 2, y=125)
        desktop.key('Control_L', 'End')
        for selector_key in [content_key, sidebar_key]:
            open_menu(selector_key); desktop.key('Escape'); closed()
            desktop.send('text', value='focussentinel')
            wait_document_text(desktop, original + 'focussentinel')
            desktop.key('Control_L', 's')
            wait_saved(document, original + 'focussentinel')
            desktop.key('Control_L', 'z')
            wait_document_text(desktop, original)
            desktop.key('Control_L', 's')
            wait_saved(document, original)
        for context_key in [('Shift_L', 'F10'), ('Menu',)]:
            rows = open_menu(context_key)
            if not {'Local History…', 'Clipboard History', 'Select all'}.issubset(
                    {row['name'] for row in rows}):
                raise RuntimeError('Standard context key did not open the focused Source menu')
            desktop.capture('standard-' + '-'.join(context_key))
            desktop.key('Escape'); closed()
        open_menu(content_key, CONTENT.values()); desktop.key('Escape'); closed()
        if writerside:
            # Configuration documents have Source only. Exercise the real GTK
            # bridge with disabled single-choice rows, retaining their letters.
            configuration = root / 'writerside.cfg'
            saved_configuration = configuration.read_bytes()
            # Configuration files are opened from the existing Files view;
            # document search intentionally indexes authoring documents only.
            open_menu(sidebar_key); desktop.key('f'); closed()
            file_rows = wait_state(desktop, lambda rows: any(row['showing'] and
                row['enabled'] and row['role'] == 'panel' and
                row['name'].split('\n', 1)[0] == 'writerside.cfg' for row in rows),
                '_configuration-file-ready')
            file_label = next(row['name'] for row in file_rows if row['showing']
                and row['enabled'] and row['role'] == 'panel' and
                row['name'].split('\n', 1)[0] == 'writerside.cfg')
            desktop.send('activateAccessible', name=file_label, role='panel')
            wait_document_text(desktop, saved_configuration.decode())
            rows = open_menu(content_key, CONTENT.values())
            for row in rows:
                if row['enabled'] != (row['name'] == 'Source'):
                    raise RuntimeError('Incorrect configuration view availability: ' + row['name'])
            for letter in ['e', 'r', 'd']:
                desktop.key(letter)
                wait_state(desktop, lambda rows: bool(menu_rows(rows)), '_disabled-content-still-open')
            desktop.key('s'); closed()
            wait_document_text(desktop, saved_configuration.decode())
            if configuration.read_bytes() != saved_configuration:
                raise RuntimeError('Unavailable view mnemonic changed the configuration document')
            desktop.capture('configuration-source-only')
        if git:
            open_menu(sidebar_key); desktop.key('c'); closed()
            wait_state(desktop, lambda rows: any(row['showing'] and
                       row['role'] == 'table cell' and row['name'] == 'pending.md'
                       for row in rows), '_git-change-ready')
            desktop.click_accessible('pending.md', 'table cell')
            wait_state(desktop, lambda rows: any(row['showing'] and row['focused']
                       and row['role'] in {'tree table', 'table cell'} for row in rows),
                       '_git-control-focused')
            desktop.key('F5'); desktop.key('Control_L', 'Return')
            desktop.key('Control_L', 'Shift_L', 'b')
            desktop.key('Control_L', 'Shift_L', 'p')
            wait_state(desktop, lambda rows: any(row['focused'] and row['role'] == 'text'
                       for row in rows), '_application-palette-focused')
            desktop.capture('git-application-command-palette')
            desktop.key('Escape')
        verify_settings(desktop, remapped)
        desktop.capture('final')
        desktop.close()
        (output / 'selector-result.json').write_text(json.dumps({'passed': True,
            'writerside': writerside, 'git': git, 'remapped': remapped}))
    finally:
        if desktop.process.poll() is None:
            desktop.process.terminate(); desktop.process.wait(timeout=20)
        desktop.log.close()


def run_case(arguments):
    binary, output, writerside, git, remapped = arguments
    name = f'{"writerside" if writerside else "ordinary"}-{"git" if git else "plain"}-{"custom" if remapped else "default"}'
    try:
        run(binary, output / name, writerside, git, remapped)
        return {'case': name, 'passed': True}
    except Exception as error:
        return {'case': name, 'passed': False, 'error': str(error)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--jobs', type=int, choices=[1, 2], default=1,
                        help='Independent private desktop processes (default: 1)')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    cases = [(args.binary.resolve(), args.output.resolve(), writerside, git, remapped)
             for writerside, git, remapped in [(True, False, False),
             (True, True, False), (True, True, True),
             (False, True, False), (False, False, False)]]
    if args.jobs == 1:
        results = list(map(run_case, cases))
    else:
        # Each worker owns its environment, D-Bus, X server, profile and fixture.
        # Every case still runs all native input and lifecycle/integrity gates.
        with ProcessPoolExecutor(max_workers=args.jobs) as executor:
            results = list(executor.map(run_case, cases))
    (args.output / 'matrix-result.json').write_text(json.dumps(results, indent=2))
    if not all(row['passed'] for row in results):
        raise SystemExit('Native selector acceptance failed; inspect matrix-result.json')


if __name__ == '__main__':
    main()

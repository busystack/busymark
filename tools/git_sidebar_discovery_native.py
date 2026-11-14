#!/usr/bin/env python3
"""Exercise Git discovery through the shipping Sidebar selector on private X11.

Requires BUSYSTACK_NATIVE_RECEIPT for the sealed binary. --installed uses the
ordinary confined Snap launcher and private profile/bus. --project copies a
local reproduction project, including its index and working files.
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


class SnapRun(DesktopRun):
    def __init__(self, binary, output, repository, scale):
        self.output = output
        self.catalog = json.loads(Path('lib/l10n/app_en.arb').read_text())
        self.rtl = False
        self.log = (output / 'desktop.log').open('w')
        env = dict(os.environ, BUSYSTACK_NATIVE_APP_SETTINGS=str(
            output / 'xdg_data_home/io.busystack.busymark/settings.json'))
        self.process = subprocess.Popen([
            '/usr/bin/python3', 'tools/git_native_snap_session.py',
            str(binary), str(output), str(repository), str(scale)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.log,
            text=True, bufsize=1, env=env)
        self.width, self.height = self.read(lambda value: 'pid' in value)['size']


def visible(rows, text):
    return any(row['showing'] and text in row['name'] for row in rows)


def select(desktop, view):
    wait_state(desktop, lambda rows: visible(rows,
        desktop.catalog['sidebarViewMenu']), '_sidebar-ready')
    desktop.key('Control_L', 'Shift_L', 'F9')
    rows = wait_state(desktop, lambda rows: any(row['showing'] and
        row['role'] == 'check menu item' for row in rows), '_selector-open')
    entries = [row for row in rows if row['showing'] and
               row['role'] == 'check menu item']
    for label in ['Commit', 'Git Log']:
        matches = [row for row in entries if row['name'] == label]
        if len(matches) != 1 or not matches[0]['enabled']:
            raise RuntimeError('Git entry unavailable before discovery: ' + label)
    desktop.selector_count = getattr(desktop, 'selector_count', 0) + 1
    desktop.capture(f'selector-{desktop.selector_count}-' + view.replace(' ', '-'))
    desktop.key('c' if view == 'Commit' else 'g')
    wait_state(desktop, lambda rows: not any(row['showing'] and
        row['role'] == 'check menu item' for row in rows), '_selector-closed')


def run(binary, output, root, initial, outcome, installed):
    output.mkdir(parents=True)
    settings = output / 'xdg_data_home/io.busystack.busymark/settings.json'
    settings.parent.mkdir(parents=True)
    settings.write_text(json.dumps({'localeTag': 'en', 'autoSave': False,
        'sidebarVisible': True, 'documentViewMode': 'source',
        'trustedGitWorkspacePaths': []}))
    os.environ['BUSYSTACK_NATIVE_PLAIN_DIRECTORY'] = '1' if outcome == 'plain' else '0'
    desktop = (SnapRun if installed else DesktopRun)(binary, output, root, 1.0)
    try:
        select(desktop, initial)
        catalog = desktop.catalog
        if outcome in {'plain', 'ancestor'}:
            messages = ([catalog[key] for key in ['gitNotRepositoryMessage',
                'gitHostInitializeHere', 'gitHostCloneRepository2']]
                if outcome == 'plain' else [catalog['gitWorkspaceRootRequired']])
            for view in [initial, 'Git Log' if initial == 'Commit' else 'Commit']:
                if view != initial:
                    select(desktop, view)
                wait_state(desktop, lambda rows: all(visible(rows, message)
                    for message in messages), '_discovery-result')
                desktop.capture('discovery-' + view.replace(' ', '-'))
        else:
            if initial == 'Git Log':
                wait_state(desktop, lambda rows: visible(rows,
                    catalog['gitUiGitLog']), '_restricted-log')
                desktop.capture('restricted-log')
                select(desktop, 'Commit')
            notice = catalog['gitOperationsRequireTrust']
            trust = catalog['gitTrustWorkspace']
            wait_state(desktop, lambda rows: visible(rows, notice), '_untrusted-commit')
            desktop.capture('exclusive-trust-notice')
            desktop.send('activateAccessible', name=trust)
            wait_state(desktop, lambda rows: visible(rows,
                catalog['gitTrustRequiredMessage']) and visible(rows, str(root)),
                '_trust-confirmation')
            desktop.capture('explicit-trust-confirmation')
            desktop.send('activateAccessible', name=catalog['cancel'])
            wait_state(desktop, lambda rows: visible(rows, notice) and
                not visible(rows, catalog['gitTrustRequiredMessage']), '_trust-cancelled')
            desktop.send('activateAccessible', name=trust)
            wait_state(desktop, lambda rows: visible(rows,
                catalog['gitTrustRequiredMessage']), '_trust-confirmation-again')
            desktop.send('activateAccessible', name=trust)
            wait_state(desktop, lambda rows: not visible(rows, notice) and
                visible(rows, catalog['gitUiCommitAndPush']), '_trusted-commit')
            desktop.capture('trusted-commit')
            select(desktop, 'Git Log')
            wait_state(desktop, lambda rows: visible(rows,
                catalog['gitUiGitLog']), '_trusted-log')
            desktop.capture('trusted-log')
        desktop.close()
    finally:
        if desktop.process.poll() is None:
            desktop.process.terminate()
            desktop.process.wait(timeout=20)
        desktop.log.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--installed', action='store_true')
    parser.add_argument('--project', type=Path)
    args = parser.parse_args()
    args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    # A plain fixture below this checkout would discover BusyMark's ancestor
    # repository. Snap fixtures also need a path visible through confinement.
    fixture_parent = Path.home() / 'snap/busymark/common' if args.installed else Path('/tmp')
    fixture_parent.mkdir(parents=True, exist_ok=True)
    fixtures = Path(tempfile.mkdtemp(prefix='git-sidebar-fixtures-', dir=fixture_parent))
    (args.output / 'fixtures-root.txt').write_text(str(fixtures))
    cases = [('markdown', False, 'git'), ('writerside', True, 'git'),
             ('plain-markdown', False, 'plain'), ('plain-writerside', True, 'plain'),
             ('ancestor-writerside', True, 'ancestor')]
    if args.project:
        cases.append(('project-copy', True, 'git'))
    results = []
    for name, writerside, outcome in cases:
        for initial in ['Commit', 'Git Log']:
            case = args.output / (name + '-' + initial.replace(' ', '-'))
            parent = fixtures / case.name
            parent.mkdir(parents=True)
            root = parent / 'workspace'
            if name == 'project-copy':
                shutil.copytree(args.project.expanduser(), root)
            elif writerside:
                shutil.copytree('test/fixtures/writerside/toc_ui', root)
            else:
                root.mkdir()
                (root / 'home.md').write_text('# Git discovery acceptance\n')
            if outcome != 'plain' and name != 'project-copy':
                repository = parent if outcome == 'ancestor' else root
                for command in [['init', '-b', 'main'],
                    ['-c', 'user.name=Discovery acceptance', '-c',
                     'user.email=discovery@example.invalid', 'commit',
                     '--allow-empty', '--no-gpg-sign', '-m', 'Discovery fixture']]:
                    subprocess.run(['git', '-C', str(repository), *command],
                        check=True, stdout=subprocess.DEVNULL)
            result = {'case': case.name, 'passed': False}
            try:
                run(args.binary.resolve(), case / 'native', root, initial,
                    outcome, args.installed)
                result['passed'] = True
            except Exception as error:
                result['error'] = str(error)
            results.append(result)
            (args.output / 'results.json').write_text(json.dumps(results, indent=2))
            print(json.dumps(result), flush=True)
    if not all(result['passed'] for result in results):
        raise SystemExit('Git discovery native acceptance failed')


if __name__ == '__main__':
    main()

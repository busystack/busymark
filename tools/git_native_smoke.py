#!/usr/bin/env python3
"""Capture real shipping Git interfaces on private desktops, with no UI mocks.

Usage: git_native_smoke.py BINARY OUTPUT [--quick]
Run from the BusyMark repository with the approved Flutter SDK on PATH.
The full run covers both themes, en/de/ja/ar, 1.0/1.5 desktop text scaling,
normal/narrow windows, Branches, the information header, its native menu and Log.
Rendered widget contracts are the deterministic layout gate; these PNGs require
human inspection before graphical acceptance.
"""
import json
from collections import Counter
from PIL import Image

def dominant(image):
    return max(image.getcolors(image.width * image.height), key=lambda pair: pair[0])[1]

def graph_rendered(image):
    rows = [y for y in range(image.height) if any(
        max(image.getpixel((x, y)))-min(image.getpixel((x, y))) > 60
        for x in range(image.width))]
    pixels = sum(count for count, color in image.getcolors(image.width * image.height)
                 if max(color)-min(color) > 60)
    return (30 < pixels < image.width*image.height/3 and bool(rows) and
            rows[-1]-rows[0] > 100)

def native_history_graph_bounds(table, subject, rtl):
    # The shared GTK bridge rounds a cell origin and ceils its width
    # independently. In RTL their sum can exceed the integer viewport by one
    # pixel. Inspect only the painted intersection, and reject larger drift
    # or a header that is not the table's first logical column.
    edge = subject[2]-table[2] if rtl else subject[0]-table[0]
    top = max(table[1], subject[3])
    if not (table[0]-1 <= subject[0] < subject[2] <= table[2]+1
            and abs(edge) <= 1 and subject[2]-subject[0] > 40
            and table[3] > top+100):
        raise RuntimeError(f'Native history graph column geometry is invalid: table={table}, subject={subject}')
    left, right = max(table[0], subject[0]), min(table[2], subject[2])
    return (right-40 if rtl else left, top, right if rtl else left+40,
            min(table[3], top+400))

import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import time


def fixture(root, many=False):
    root.mkdir()
    def git(*args):
        return subprocess.check_output(['git', '-C', str(root), *args], text=True, stderr=subprocess.DEVNULL)
    git('init', '-b', 'main')
    git('config', 'user.name', 'Native UI acceptance')
    git('config', 'user.email', 'native@example.invalid')
    for i in range(8):
        (root / 'README.md').write_text(f'# Native UI acceptance\n\nRevision {i}.\n')
        git('add', 'README.md')
        git('commit', '-m', f'Improve native history review {i}')
    for branch in ['feature/native-controls', 'feature/long-branch-name-with-readable-tracking-and-worktree-metadata']:
        git('branch', branch)
    git('update-ref', 'refs/remotes/origin/main', 'HEAD~2')
    git('config', 'remote.origin.url', str(root.parent / 'unused-remote'))
    git('config', 'remote.origin.fetch', '+refs/heads/*:refs/remotes/origin/*')
    git('config', 'branch.main.remote', 'origin')
    git('config', 'branch.main.merge', 'refs/heads/main')
    git('tag', 'v1.0', 'HEAD~3')
    git('switch', '-c', 'feature/parallel-history')
    (root / 'feature.md').write_text('# Parallel history 日本語 العربية\n')
    git('add', 'feature.md')
    git('commit', '-m', 'Add parallel feature history 日本語 العربية')
    git('switch', 'main')
    (root / 'README.md').write_text('# Native UI acceptance\n\nMain-line changes for merge review.\n')
    git('add', 'README.md')
    git('commit', '-m', 'Keep the main line visible beside feature history')
    git('merge', '--no-ff', 'feature/parallel-history', '-m', 'Merge native presentation remediation with a deliberately long subject that must truncate in the sidebar and remain readable in history and exact commit details')
    if many:
        for index in range(80):
            git('branch', f'review/branch-{index:03}')
            git('tag', f'review-tag-{index:03}')
        for index in range(210):
            git('commit', '--allow-empty', '--no-gpg-sign', '-m', f'Review pagination and graph continuity {index:03}')
    return root


class DesktopRun:
    def __init__(self, binary, output, repository, scale, locale='en'):
        self.output = output
        self.rtl = locale == 'ar'
        self.catalog = json.loads((Path(__file__).resolve().parents[1] /
                                   f'lib/l10n/app_{locale}.arb').read_text())
        self.log = (output / 'desktop.log').open('w')
        self.process = subprocess.Popen(['dbus-run-session', '--', '/usr/bin/python3', 'tools/git_native_desktop.py',
            str(binary), str(output), str(repository), str(scale)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.log, text=True, bufsize=1)
        self.width, self.height = self.read(lambda value: 'pid' in value)['size']
    def read(self, predicate):
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if not select.select([self.process.stdout], [], [], 1)[0]:
                if self.process.poll() is not None:
                    raise RuntimeError(f'Native desktop exited: {self.output}')
                continue
            line = self.process.stdout.readline()
            if not line:
                raise RuntimeError(f'Native desktop closed its output; inspect {self.output / "desktop.log"}')
            self.log.write(line)
            self.log.flush()
            try:
                value = json.loads(line)
            except json.JSONDecodeError:
                continue
            if predicate(value):
                return value
        raise TimeoutError(f'Native desktop did not respond: {self.output}')
    def send(self, command, **arguments):
        payload = {'command': command, **arguments}
        self.process.stdin.write(json.dumps(payload) + '\n')
        self.process.stdin.flush()
        self.read(lambda value: value.get('done') == payload)
    def key(self, *names):
        self.send('key', names=list(names))
    def capture(self, name):
        self.send('wait', seconds=.3)
        self.send('capture', name=name)
    def checkpoint(self):
        self.send('capture', name='_checkpoint')
        return Image.open(self.output / '_checkpoint.png').convert('RGB')
    def wait_accessible(self, predicate, name, **request):
        for _ in range(40):
            self.send('accessibility', name=name, **request)
            rows = json.loads((self.output / (name+'-accessibility.json')).read_text())['nodes']
            if predicate(rows):
                return rows
            self.send('wait', seconds=.25)
        raise RuntimeError('Expected owned native accessibility state did not arrive: '+name)
    def activate_message(self, key, trim_ellipsis=False):
        label = self.catalog[key]
        if trim_ellipsis:
            label = label.removesuffix('…')
        self.wait_accessible(lambda rows: len([row for row in rows
            if row['name'] == label and row['enabled']]) == 1, '_action-ready')
        self.send('activateAccessible', name=label)
    def accessible_bounds(self, label, role):
        if role not in {'table', 'table cell', 'column header'}:
            raise ValueError('Geometry inspection requires a native GTK table node')
        self.send('accessibility', name='_geometry', boundsName=label, boundsRole=role)
        rows = json.loads((self.output / '_geometry-accessibility.json').read_text())['nodes']
        matches = [row for row in rows if row['name'] == label and row['role'] == role]
        if len(matches) != 1 or 'bounds' not in matches[0]:
            raise RuntimeError('Expected exactly one owned native geometry: '+label)
        x, y, width, height = matches[0]['bounds']
        if width <= 0 or height <= 0:
            raise RuntimeError('Owned native control has no visible geometry: '+label)
        return x, y, x+width, y+height
    def click_accessible(self, label, role, button=1):
        if role == 'panel' and button == 1:
            self.send('activateAccessible', name=label, role=role)
            return
        left, top, right, bottom = self.accessible_bounds(label, role)
        self.send('click', x=(left+right)//2, y=(top+bottom)//2, button=button)
    def focus_history_field(self, key, trim_ellipsis=False):
        label = self.catalog[key]
        if trim_ellipsis:
            label = label.removesuffix('…')
        role = 'text'
        self.wait_accessible(lambda rows: len([row for row in rows if row['name'] == label
            and row['role'] == role and row['enabled']]) == 1, '_editor-ready')
        # Flutter text fields expose focus state but no AT-SPI action. Place
        # real pointer input in the current dialog's filter band, relative to
        # the measured native table, and require that exact editor to focus.
        table = self.accessible_bounds(self.catalog['gitUiGitCommits'], 'table')
        fraction = {'gitUiMessage': 1/6, 'gitUiAuthor': 1/2, 'gitUiPath': 5/6}
        x = (round(table[0]+(table[2]-table[0])*fraction[key]) if key in fraction else
             table[0]-140)
        self.send('click', x=x, y=self.history_box[1]+70)
    def expect_editor_text(self, key, expected, trim_ellipsis=False):
        label = self.catalog[key]
        if trim_ellipsis:
            label = label.removesuffix('…')
        # Qualify the real keyboard transaction: its intended owned editor
        # must report both focus and exactly the received text. A preliminary
        # focus notification can precede publication of the editable state.
        self.wait_accessible(lambda rows: len([row for row in rows if row['name'] == label
            and row['role'] == 'text' and row['enabled'] and row['focused']
            and row.get('text') == expected]) == 1, '_editor-input-verified', textName=label)
    def commit_row(self, subject, button=1):
        rows = self.wait_accessible(lambda rows: any(row['role'] == 'table cell'
            and row['name'].endswith(subject) for row in rows), '_commit-row-ready')
        names = [row['name'] for row in rows if row['role'] == 'table cell'
                 and row['name'].endswith(subject)]
        if len(names) != 1:
            raise RuntimeError('Expected one native fixture commit: '+subject)
        self.click_accessible(names[0], 'table cell', button)
    def branches(self):
        self.activate_message('gitUiSelectAnotherBranch')
        self.branch_box = self.modal(400)
    def log_view(self, rtl):
        self.activate_message('sidebarViewMenu')
        self.wait_accessible(lambda rows: any(row['role'] == 'check menu item'
            and row['name'] == self.catalog['gitHostGitLog'] for row in rows), '_view-menu-ready')
        # This fixture is a Markdown folder: Files, Outline, Commit, Git Log.
        # Retain real keyboard selection, then verify the selected shared view.
        self.key('Home')
        for _ in range(3):
            self.key('Down')
        self.key('Return')
        self.wait_accessible(lambda rows: not any(row['role'] == 'check menu item' for row in rows)
            and any(row['role'] == 'panel' and row['name'].split('\n', 1)[0] ==
                    self.catalog['gitUiGitLog'] for row in rows), '_log-view-ready')
        rows = self.wait_accessible(lambda rows: any(
            line == self.catalog['gitUiSelectACommitForDetailsAndChangedFiles']
            or line.startswith(self.catalog['gitUiChangedFiles'] + ' (')
            for row in rows for line in row['name'].split('\n')), '_log-selection-ready')
        if any(line == self.catalog['gitUiSelectACommitForDetailsAndChangedFiles']
               for row in rows for line in row['name'].split('\n')):
            self.capture('log-before-first-selection')
            self.activate_message('gitUiSelectAnotherCommit')
            self.wait_history()
            self.activate_message('gitUiSelectThisCommit')
        self.wait_sidebar(rtl, information=True)
    def sidebar_menu_x(self, rtl):
        picture = self.checkpoint()
        edge = self.width-8 if rtl else 8
        color = picture.getpixel((edge, 48))
        step = -1 if rtl else 1
        boundary = edge
        while picture.getpixel((boundary, 48)) == color:
            boundary += step
        return boundary+24 if rtl else boundary-24
    def wait_sidebar(self, rtl, information=False):
        previous = None
        for _ in range(60):
            picture = self.checkpoint()
            pixels = picture.load()
            left = self.width-258 if rtl else 10
            top, bottom = (150, 210) if information else (114, 144)
            region = [pixels[x, y] for x in range(left+8, left+240, 2) for y in range(top, bottom, 2)]
            background = Counter(region).most_common(1)[0][0]
            contrast = sum(max(abs(a-b) for a,b in zip(color, background)) > 50 for color in region)
            signature = picture.crop((left+8, top, left+240, bottom)).tobytes()
            if contrast > (80 if information else 15) and signature == previous:
                return
            previous = signature
            self.send('wait', seconds=1)
        raise RuntimeError('Git sidebar did not render its expected content; no dependent input was sent')
    def modal(self, minimum_height):
        for _ in range(60):
            picture = self.checkpoint()
            pixels = picture.load()
            center = picture.crop((self.width//2-80, self.height//2-60, self.width//2+80, self.height//2+60))
            color = dominant(center)
            rows = [y for y in range(45, self.height-30) if sum(pixels[x,y] == color for x in range(20, self.width-20, 4)) > self.width/16]
            columns = [x for x in range(20, self.width-20) if sum(pixels[x,y] == color for y in range(45, self.height-30, 4)) > self.height/28]
            if rows and columns and rows[-1]-rows[0] >= minimum_height:
                bounds = (columns[0], rows[0], columns[-1], rows[-1])
                if minimum_height == 400:
                    # Follow the modal's clear outer content inset. Do not
                    # merge a same-colored GTK titlebar into its geometry.
                    inset = range(columns[0]+4, columns[0]+13)
                    runs, start = [], None
                    for y in range(45, self.height-30):
                        match = sum(pixels[x,y] == color for x in inset) >= 4
                        if match and start is None:
                            start = y
                        if not match and start is not None:
                            runs.append((start, y-1)); start = None
                    if start is not None:
                        runs.append((start, self.height-31))
                    if not runs:
                        continue
                    top, bottom = max(runs, key=lambda run: run[1]-run[0])
                    if bottom-top < minimum_height:
                        continue
                    bounds = (columns[0], top, columns[-1], bottom)
                if (30 < bounds[0] < self.width//2 < bounds[2] < self.width-30
                        and bounds[1] < self.height//2 < bounds[3]):
                    return bounds
            self.send('wait', seconds=1)
        raise RuntimeError('Expected native modal did not render; no dependent input was sent')
    def wait_graph(self):
        self.wait_accessible(lambda rows: any(row['role'] == 'table' and
            row['name'] == self.catalog['gitUiGitCommits'] and row['busy'] is False
            for row in rows) and any(row['role'] == 'table cell' for row in rows), '_history-loaded')
        table = self.accessible_bounds(self.catalog['gitUiGitCommits'], 'table')
        subject = self.accessible_bounds(self.catalog['gitUiSubjectReferences'], 'column header')
        # The two-lane fixture fits in the shared graph's minimum 40-pixel
        # subject-cell inset. Inspect that real native column, mirrored for
        # RTL, rather than assuming an orange accent across the whole dialog.
        bounds = native_history_graph_bounds(table, subject, self.rtl)
        for _ in range(60):
            image = self.checkpoint().crop(bounds)
            if graph_rendered(image):
                return
            self.send('wait', seconds=1)
        raise RuntimeError('The real history graph did not render')
    def wait_history(self):
        # Filter submission can move focus to the selected result. Wait for
        # actual stable results, then explicitly focus the next editor before
        # typing. A fixed delay alone can photograph a still-loading table.
        previous = None
        for _ in range(60):
            self.send('accessibility', name='_history-loading')
            rows = json.loads((self.output / '_history-loading-accessibility.json').read_text())['nodes']
            ready = any(row['role'] == 'table' and row['name'] == self.catalog['gitUiGitCommits']
                        and row['busy'] is False for row in rows)
            picture = self.checkpoint()
            area = picture.crop((50, 150, self.width-50, 635))
            signature = area.tobytes()
            if ready and signature == previous:
                return
            previous = signature
            self.send('wait', seconds=1)
        raise RuntimeError('History results did not settle after native filtering')
    def selector(self, rtl):
        self.wait_accessible(lambda rows: any(row['name'] ==
            self.catalog['gitUiSelectAnotherCommit'].removesuffix('…') and row['enabled']
            for row in rows), '_inspector-selector-ready')
        # A surviving comparison also has an Actions button. Exercise the
        # sidebar's actual pointer target using its measured native boundary.
        self.send('click', x=self.sidebar_menu_x(rtl), y=130)
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_header-actions-ready')
        self.capture('header-actions')
        self.key('Home')
        self.capture('header-actions-keyboard')
        self.key('Escape')
        self.wait_accessible(lambda rows: not any(row['role'] == 'menu item' for row in rows),
                             '_header-actions-closed')
        self.activate_message('gitUiSelectAnotherCommit', trim_ellipsis=True)
        self.history_box = self.modal(500)
        self.wait_graph()
    def detailed_branches(self):
        left, top, right, _ = self.branch_box
        self.send('click', x=left+145, y=top+103)
        self.wait_accessible(lambda rows: any(row['name'] == self.catalog['gitUiSearchBranchesAndTags']
            and row['role'] == 'text' and row['focused'] for row in rows), '_branch-search-focused')
        self.capture('branches-search-focused')
        self.send('text', value='origin')
        self.expect_editor_text('gitUiSearchBranchesAndTags', 'origin')
        self.capture('branches-search-results')
        self.key('Control_L', 'a')
        self.capture('branches-search-selection')
        self.key('Control_L', 'c')
        self.key('BackSpace')
        self.key('Control_L', 'v')
        self.expect_editor_text('gitUiSearchBranchesAndTags', 'origin')
        self.capture('branches-search-pasted')
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.expect_editor_text('gitUiSearchBranchesAndTags', '')
        self.key('Down')
        # The first result can be the Local branches expander. Move into a
        # branch row before opening its keyboard context menu.
        self.key('Down')
        self.key('Menu')
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_branch-keyboard-menu-ready')
        self.capture('branches-keyboard-menu')
        self.key('Escape')
        self.key('Shift_L', 'F10')
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_branch-shift-f10-ready')
        self.capture('branches-shift-f10')
        self.key('Escape')
        self.send('click', x=left+135, y=top+223, button=3)
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_branch-secondary-menu-ready')
        self.capture('branches-secondary-menu')
        self.key('Escape')
        self.send('move', x=right-120, y=top+103)
        self.capture('new-branch-hover')
        self.send('click', x=left+145, y=top+103)
        self.key('Tab')
        self.capture('new-branch-keyboard-focus')
        self.send('press', x=right-120, y=top+103)
        self.capture('new-branch-pressed')
        self.send('release', x=right-120, y=top+103)
        self.wait_accessible(lambda rows: any(row['name'] == self.catalog['gitUiLocalBranchName']
            for row in rows), '_create-branch-ready')
        self.capture('existing-create-branch-workflow')
        self.key('Escape')
        self.wait_accessible(lambda rows: any(row['name'] == self.catalog['gitUiSearchBranchesAndTags']
            and row['role'] == 'text' for row in rows), '_branches-restored')
        self.send('click', x=right-32, y=top+103)
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_branch-actions-ready')
        self.capture('branches-general-actions')
        self.key('Escape')
    def detailed_history(self):
        self.commit_row('Keep the main line visible beside feature history')
        self.capture('history-unfocused-filters')
        self.focus_history_field('gitUiMessage', trim_ellipsis=True)
        self.capture('history-focused-filter')
        self.send('text', value='native')
        self.expect_editor_text('gitUiMessage', 'native', trim_ellipsis=True)
        self.send('resize', width=600, height=730)
        self.capture('history-filter-focus-narrow')
        self.send('resize', width=self.width, height=self.height)
        self.capture('history-filter-focus-restored')
        self.key('Return')
        self.wait_history()
        self.capture('history-message-filtered')
        self.focus_history_field('gitUiMessage', trim_ellipsis=True)
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.expect_editor_text('gitUiMessage', '', trim_ellipsis=True)
        self.key('Return')
        self.wait_history()
        for key, query, name in [('gitUiAuthor', 'acceptance', 'author'), ('gitUiPath', 'feature.md', 'path')]:
            self.focus_history_field(key, trim_ellipsis=True)
            self.send('text', value=query)
            self.expect_editor_text(key, query, trim_ellipsis=True)
            self.key('Return')
            self.wait_history()
            self.capture(f'history-{name}-filtered')
            self.focus_history_field(key, trim_ellipsis=True)
            self.key('Control_L', 'a')
            self.key('BackSpace')
            self.expect_editor_text(key, '', trim_ellipsis=True)
            self.key('Return')
            self.wait_history()
        self.activate_message('gitUiDate')
        self.capture('history-date-dialog')
        self.key('Escape')
        self.commit_row('Keep the main line visible beside feature history', button=3)
        self.capture('history-commit-context')
        self.key('Escape')
        self.focus_history_field('gitUiSearchBranchesAndTags')
        self.send('text', value='origin')
        self.expect_editor_text('gitUiSearchBranchesAndTags', 'origin')
        self.capture('history-reference-search')
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.expect_editor_text('gitUiSearchBranchesAndTags', '')
        self.commit_row('Keep the main line visible beside feature history')
        self.capture('history-candidate')
        self.reference_interactions()
    def reference_interactions(self):
        self.focus_history_field('gitUiSearchBranchesAndTags')
        self.key('Control_L', 'a')
        self.send('text', value='origin')
        self.expect_editor_text('gitUiSearchBranchesAndTags', 'origin')
        self.capture('history-reference-search')
        # Search retains the All/Local/Remote group rows. The matching remote
        # is the fourth 34-pixel reference row below this dialog's search.
        table = self.accessible_bounds(self.catalog['gitUiGitCommits'], 'table')
        self.send('click', x=table[0]-140,
                  y=self.history_box[1]+214, button=3)
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_reference-context-ready')
        self.capture('history-reference-context')
        self.key('Escape')
        self.key('Shift_L', 'F10')
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_reference-keyboard-context-ready')
        self.capture('history-reference-keyboard-context')
        self.key('Escape')
        self.click_accessible('origin/main', 'panel')
        self.wait_history()
        self.capture('history-remote-filtered')
        self.reset_history_filters()
        self.focus_history_field('gitUiSearchBranchesAndTags')
        self.key('Control_L', 'a')
        self.send('text', value='v')
        self.key('1')
        self.key('period')
        self.key('0')
        self.expect_editor_text('gitUiSearchBranchesAndTags', 'v1.0')
        self.capture('history-tag-search')
        self.click_accessible('v1.0', 'panel')
        self.wait_history()
        self.capture('history-tag-filtered')
        self.reset_history_filters()
        self.focus_history_field('gitUiSearchBranchesAndTags')
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.expect_editor_text('gitUiSearchBranchesAndTags', '')
    def reset_history_filters(self):
        self.activate_message('gitUiActions')
        rows = self.wait_accessible(lambda rows: any(row['role'] == 'menu item' and
            row['name'] == self.catalog['gitUiResetFilters'] for row in rows), '_reset-filters-ready')
        items = sorted([row for row in rows if row['role'] == 'menu item' and row['enabled']],
                       key=lambda row: row['indexInParent'])
        indices = [row['indexInParent'] for row in items]
        targets = [i for i, row in enumerate(items) if row['name'] == self.catalog['gitUiResetFilters']]
        if (len(targets) != 1 or any(index < 0 for index in indices)
                or len(set(indices)) != len(indices)):
            raise RuntimeError('The native filter menu has no unambiguous keyboard order')
        self.capture('history-navigation-actions')
        self.key('Home')
        for _ in range(targets[0]):
            self.key('Down')
        self.key('Return')
        self.wait_history()
        self.wait_accessible(lambda rows: any(row['name'] == self.catalog['gitUiAllReferences']
            and row['selected'] for row in rows), '_history-filters-reset')
    def selection_and_comparisons(self):
        self.selector(False)
        self.commit_row('Keep the main line visible beside feature history')
        self.capture('candidate-before-cancel')
        self.key('Escape')
        self.send('move', x=700, y=500)
        self.capture('canceled-candidate-keeps-original')
        self.selector(False)
        self.commit_row('Keep the main line visible beside feature history')
        self.key('Return')
        self.send('move', x=700, y=500)
        self.capture('confirmed-by-keyboard')
        self.open_comparison('README.md')
        self.capture('historical-comparison-one')
        self.selector(False)
        self.commit_row('Improve native history review 7')
        _, _, right, bottom = self.history_box
        self.send('click', x=right-90, y=bottom-31)
        self.send('move', x=700, y=500)
        self.capture('confirmed-by-mouse')
        self.open_comparison('README.md')
        self.capture('independent-historical-tabs')
        self.selector(False)
        self.commit_row('Merge native presentation remediation with a deliberately long subject that must truncate in the sidebar and remain readable in history and exact commit details')
        self.key('Return')
        self.open_comparison('feature.md')
        self.capture('merge-first-parent-comparison')
        rows = self.wait_accessible(lambda rows: any(row['role'] == 'panel' and
            row['enabled'] and row['name'].startswith('Compare parent 1: ') for row in rows), '_parent-ready')
        parent = [row['name'] for row in rows if row['role'] == 'panel' and
                  row['enabled'] and row['name'].startswith('Compare parent 1: ')]
        if len(parent) != 1:
            raise RuntimeError('Expected the merge inspector parent selector')
        self.send('activateAccessible', name=parent[0], role='panel')
        self.wait_accessible(lambda rows: any(row['role'] == 'menu item' for row in rows),
                             '_parent-menu-ready')
        self.capture('merge-parent-menu')
        self.key('Home')
        self.key('Down')
        self.key('Return')
        self.open_comparison('README.md')
        self.capture('merge-second-parent-comparison')
    def open_comparison(self, path):
        self.wait_accessible(lambda rows: len([row for row in rows if row['name'] == path
            and row['role'] == 'panel' and row['enabled']]) == 1, '_changed-file-ready')
        self.send('activateAccessible', name=path, role='panel')
        self.wait_accessible(lambda rows: any(row['name'] == self.catalog['gitUiSearchComparison']
            for row in rows), '_comparison-ready')
    def close(self):
        self.send('close')
        self.process.stdin.close()
        # Application exit still has the driver's unchanged 15-second bound.
        # Allow its subsequent complete payload/source/Git hashing to finish
        # under concurrent build I/O before collecting the verified receipt.
        status = self.process.wait(timeout=120)
        self.log.close()
        receipt = json.loads((self.output / 'receipt.json').read_text())
        if (status or not receipt.get('naturalExit') or not receipt.get('repositoryUnchanged')
                or not receipt['engine']['matches']
                or receipt.get('credentialService', {}).get('ready') is not True):
            raise RuntimeError(f'Native run failed its lifecycle/integrity checks: {self.output}')


def main():
    binary, output = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    many = '--many' in sys.argv
    repository = fixture(Path(tempfile.mkdtemp(prefix='busymark-git-native-')) / 'repository', many=many)
    (output / 'repository.txt').write_text(str(repository))
    references_only = '--references-only' in sys.argv
    combinations = [('light', 'en', 1.0)] if '--quick' in sys.argv or many or references_only else [
        (theme, locale, scale) for theme in ['light', 'dark'] for locale in ['en', 'de', 'ja', 'ar'] for scale in [1.0, 1.5]]
    for theme in ['light', 'dark']:
        if f'--theme={theme}' in sys.argv:
            combinations = [case for case in combinations if case[0] == theme]
    for argument in sys.argv[3:]:
        if argument.startswith('--case='):
            combinations = [case for case in combinations if '-'.join(map(str, case)) == argument.removeprefix('--case=')]
    if not combinations:
        raise ValueError('No matching native presentation case')
    for theme, locale, scale in combinations:
        target = output / f'{theme}-{locale}-{scale}'
        settings = target / 'xdg_data_home/io.busystack.busymark'
        settings.mkdir(parents=True, exist_ok=True)
        (target / 'repository.txt').write_text(str(repository))
        (settings / 'settings.json').write_text(json.dumps({'themeModePreference': theme, 'localeTag': locale,
            'trustedGitWorkspacePaths': [str(repository)], 'documentViewMode': 'editor'}, ensure_ascii=False))
        print(f'Native capture: {theme} {locale} scale {scale}', flush=True)
        desktop = DesktopRun(binary, target, repository, scale, locale=locale)
        rtl = locale == 'ar'
        desktop.key('Control_L', '4')
        desktop.wait_sidebar(rtl)
        desktop.branches()
        desktop.capture('branches')
        if many:
            desktop.send('scroll', x=650, y=550, direction='down', steps=200)
            desktop.capture('many-branches-bottom')
            desktop.send('scroll', x=650, y=550, direction='up', steps=200)
        if locale == 'en' and scale == 1.0 and not many and not references_only:
            desktop.detailed_branches()
        desktop.key('Escape')
        desktop.log_view(rtl)
        desktop.send('move', x=desktop.width//2, y=500)
        desktop.capture('inspector')
        desktop.selector(rtl)
        desktop.capture('history')
        if references_only:
            desktop.reference_interactions()
            desktop.key('Escape')
            desktop.close()
            continue
        if many:
            desktop.send('scroll', x=800, y=500, direction='down', steps=200)
            desktop.capture('history-first-page-bottom')
            desktop.send('click', x=760, y=615)
            desktop.wait_graph()
            desktop.send('resize', width=600, height=730)
            desktop.capture('history-next-page')
        if locale == 'en' and scale == 1.0 and not many:
            desktop.detailed_history()
        desktop.send('resize', width=600, height=730)
        desktop.capture('history-narrow')
        desktop.key('Escape')
        desktop.capture('inspector-after-cancel')
        desktop.send('resize', width=desktop.width, height=desktop.height)
        if locale == 'en' and scale == 1.0 and not many:
            desktop.selection_and_comparisons()
        desktop.key('Control_L', '4')
        desktop.wait_sidebar(rtl)
        desktop.branches()
        desktop.send('resize', width=600, height=730)
        desktop.capture('branches-narrow')
        desktop.key('Escape')
        desktop.close()
    print('Native captures complete; inspect every case before accepting graphical presentation.', flush=True)


if __name__ == '__main__':
    main()

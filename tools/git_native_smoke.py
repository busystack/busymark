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
    def __init__(self, binary, output, repository, scale):
        self.output = output
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
        for _ in range(60):
            image = self.checkpoint().crop((50, 200, self.width-50, 600))
            colors = image.getcolors(image.width * image.height)
            graph = sum(count for count, (r,g,b) in colors if r > 160 and g < 140 and b < 100)
            if graph > 30:
                return
            self.send('wait', seconds=1)
        raise RuntimeError('The real history graph did not render')
    def wait_history(self):
        # Filter submission can move focus to the selected result. Wait for
        # actual stable results, then explicitly focus the next editor before
        # typing. A fixed delay alone can photograph a still-loading table.
        previous = None
        for _ in range(60):
            picture = self.checkpoint()
            area = picture.crop((50, 150, self.width-50, 635))
            busy = any(sum(1 for x in range(50, self.width-50, 4)
                           if (lambda c: c[0] > 180 and c[1] < 140 and c[2] < 100)(picture.getpixel((x, y)))) > self.width / 8
                       for y in range(150, 220))
            signature = area.tobytes()
            if not busy and signature == previous:
                return
            previous = signature
            self.send('wait', seconds=1)
        raise RuntimeError('History results did not settle after native filtering')
    def selector(self, rtl):
        self.send('click', x=self.sidebar_menu_x(rtl), y=122)
        self.capture('header-actions')
        self.key('Home')
        self.key('Return')
        self.history_box = self.modal(500)
        self.wait_graph()
    def detailed_branches(self):
        left, top, right, _ = self.branch_box
        self.send('click', x=left+145, y=top+103)
        self.capture('branches-search-focused')
        self.send('text', value='origin')
        self.capture('branches-search-results')
        self.key('Control_L', 'a')
        self.capture('branches-search-selection')
        self.key('Control_L', 'c')
        self.key('BackSpace')
        self.key('Control_L', 'v')
        self.capture('branches-search-pasted')
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.key('Down')
        self.key('Menu')
        self.capture('branches-keyboard-menu')
        self.key('Escape')
        self.key('Shift_L', 'F10')
        self.capture('branches-shift-f10')
        self.key('Escape')
        self.send('click', x=left+135, y=top+223, button=3)
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
        self.capture('existing-create-branch-workflow')
        self.key('Escape')
        self.send('click', x=right-32, y=top+103)
        self.capture('branches-general-actions')
        self.key('Escape')
    def detailed_history(self):
        self.send('click', x=500, y=202)
        self.capture('history-unfocused-filters')
        self.send('click', x=200, y=126)
        self.capture('history-focused-filter')
        self.send('text', value='native')
        self.send('resize', width=600, height=730)
        self.capture('history-filter-focus-narrow')
        self.send('resize', width=self.width, height=self.height)
        self.capture('history-filter-focus-restored')
        self.key('Return')
        self.wait_history()
        self.capture('history-message-filtered')
        self.send('click', x=200, y=126)
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.key('Return')
        self.wait_history()
        for x, query, name in [(500, 'acceptance', 'author'), (850, 'feature.md', 'path')]:
            self.send('click', x=x, y=126)
            self.send('text', value=query)
            self.key('Return')
            self.wait_history()
            self.capture(f'history-{name}-filtered')
            self.send('click', x=x, y=126)
            self.key('Control_L', 'a')
            self.key('BackSpace')
            self.key('Return')
            self.wait_history()
        self.send('click', x=1070, y=126)
        self.capture('history-date-dialog')
        self.key('Escape')
        self.send('click', x=500, y=235, button=3)
        self.capture('history-commit-context')
        self.key('Escape')
        self.send('click', x=130, y=168)
        self.send('text', value='origin')
        self.capture('history-reference-search')
        self.key('Control_L', 'a')
        self.key('BackSpace')
        self.send('click', x=500, y=235)
        self.capture('history-candidate')
        self.reference_interactions()
    def reference_interactions(self):
        self.send('click', x=130, y=168)
        self.key('Control_L', 'a')
        self.send('text', value='origin')
        self.capture('history-reference-search')
        self.send('click', x=130, y=320, button=3)
        self.capture('history-reference-context')
        self.key('Escape')
        self.key('Shift_L', 'F10')
        self.capture('history-reference-keyboard-context')
        self.key('Escape')
        self.send('click', x=130, y=320)
        self.wait_history()
        self.capture('history-remote-filtered')
        self.reset_history_filters()
        self.send('click', x=130, y=168)
        self.key('Control_L', 'a')
        self.send('text', value='v')
        self.key('1')
        self.key('period')
        self.key('0')
        self.capture('history-tag-search')
        self.send('click', x=130, y=355)
        self.wait_history()
        self.capture('history-tag-filtered')
        self.reset_history_filters()
        self.send('click', x=130, y=168)
        self.key('Control_L', 'a')
        self.key('BackSpace')
    def reset_history_filters(self):
        self.send('click', x=1136, y=126)
        self.capture('history-navigation-actions')
        self.key('Home')
        self.key('Return')
        self.wait_history()
    def selection_and_comparisons(self):
        self.selector(False)
        self.send('click', x=500, y=235)
        self.capture('candidate-before-cancel')
        self.key('Escape')
        self.send('move', x=700, y=500)
        self.capture('canceled-candidate-keeps-original')
        self.selector(False)
        self.send('click', x=500, y=235)
        self.key('Return')
        self.send('move', x=700, y=500)
        self.capture('confirmed-by-keyboard')
        self.send('click', x=100, y=295)
        self.capture('historical-comparison-one')
        self.selector(False)
        self.send('click', x=500, y=270)
        self.send('click', x=1170, y=657)
        self.send('move', x=700, y=500)
        self.capture('confirmed-by-mouse')
        self.send('click', x=100, y=295)
        self.capture('independent-historical-tabs')
        self.selector(False)
        self.send('click', x=500, y=201)
        self.key('Return')
        self.send('click', x=100, y=295)
        self.capture('merge-first-parent-comparison')
        self.send('click', x=150, y=238)
        self.capture('merge-parent-menu')
        self.key('Home')
        self.key('Down')
        self.key('Return')
        self.send('click', x=100, y=295)
        self.capture('merge-second-parent-comparison')
    def close(self):
        self.send('close')
        self.process.stdin.close()
        status = self.process.wait(timeout=30)
        self.log.close()
        receipt = json.loads((self.output / 'receipt.json').read_text())
        if status or not receipt.get('naturalExit') or not receipt.get('repositoryUnchanged') or not receipt['engine']['matches']:
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
        desktop = DesktopRun(binary, target, repository, scale)
        rtl = locale == 'ar'
        desktop.key('Control_L', '4')
        desktop.wait_sidebar(rtl)
        desktop.send('click', x=desktop.width-100 if rtl else 100, y=130)
        desktop.branch_box = desktop.modal(400)
        desktop.capture('branches')
        if many:
            desktop.send('scroll', x=650, y=550, direction='down', steps=200)
            desktop.capture('many-branches-bottom')
            desktop.send('scroll', x=650, y=550, direction='up', steps=200)
        if locale == 'en' and scale == 1.0 and not many and not references_only:
            desktop.detailed_branches()
        desktop.key('Escape')
        # Use native keyboard menu navigation, independent of translated labels.
        desktop.send('click', x=desktop.sidebar_menu_x(rtl), y=82)
        desktop.key('Home')
        for _ in range(3):
            desktop.key('Down')
        desktop.key('Return')
        desktop.wait_sidebar(rtl, information=True)
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
        desktop.send('click', x=desktop.width-100 if rtl else 100, y=130)
        desktop.branch_box = desktop.modal(400)
        desktop.send('resize', width=600, height=730)
        desktop.capture('branches-narrow')
        desktop.key('Escape')
        desktop.close()
    print('Native captures complete; inspect every case before accepting graphical presentation.', flush=True)


if __name__ == '__main__':
    main()

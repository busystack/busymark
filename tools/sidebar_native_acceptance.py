#!/usr/bin/env python3
"""Real application captures on an isolated desktop; no widget mocks.

Uses the existing sealed-source/official-engine/owned AT-SPI/unchanged-Git gates.
The --baseline option records old presentation without asserting its new icon.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from PIL import Image
from git_native_smoke import DesktopRun


def fixture(parent):
    root = parent / 'sidebar-project'
    shutil.copytree('test/fixtures/writerside/toc_ui', root)
    home = root / 'topics/home.md'
    home.write_text('# Introduction\n\n## Getting started\n\n[Review guide](review.md)\n\n## Details\n\n[Reusable content](reused.md)\n')
    (root / 'topics/review.md').write_text('# Review\n\n[Introduction](home.md#getting-started)\n')
    def git(*args):
        subprocess.run(['git', '-C', str(root), *args], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    git('init', '-b', 'main')
    git('config', 'user.name', 'Sidebar acceptance')
    git('config', 'user.email', 'sidebar@example.invalid')
    git('add', '.')
    git('commit', '-m', 'Introduce the Writerside sidebar fixture')
    git('commit', '--allow-empty', '-m', 'Confirm native sidebar reference navigation')
    git('branch', 'feature/long-context-日本語-العربية')
    git('update-ref', 'refs/remotes/origin/main', 'HEAD~1')
    git('config', 'branch.main.remote', 'origin')
    git('config', 'branch.main.merge', 'refs/heads/main')
    git('config', 'remote.origin.url', str(parent/'unused-remote'))
    home.write_text(home.read_text()+'\nUnstaged fixture content.\n')
    (root / 'topics/staged.md').write_text('# Staged document\n')
    git('add', 'topics/staged.md')
    return root


def choose(desktop, index, rtl):
    desktop.send('click', x=desktop.sidebar_menu_x(rtl), y=82)
    desktop.key('Home')
    for _ in range(index): desktop.key('Down')
    desktop.key('Return')
    desktop.send('move', x=desktop.width//2, y=500)
    desktop.send('wait', seconds=1)


def run(binary, output, root, theme, locale, scale, narrow, baseline):
    output.mkdir(parents=True)
    settings = output / 'xdg_data_home/io.busystack.busymark'
    settings.mkdir(parents=True)
    (settings / 'settings.json').write_text(json.dumps({
        'themeModePreference': theme, 'localeTag': locale,
        'autoSave': False, 'trustedGitWorkspacePaths': [str(root)],
        'documentViewMode': 'source'}, ensure_ascii=False))
    desktop = DesktopRun(binary, output, root, scale)
    rtl = locale == 'ar'
    try:
        # Normal product navigation opens a real source buffer.
        desktop.key('Control_L', 'p')
        desktop.send('text', value='home.md')
        desktop.key('Return')
        desktop.send('wait', seconds=2)
        desktop.capture('opened-document')
        if narrow:
            desktop.send('resize', width=920, height=850)
            desktop.width, desktop.height = 920, 850
        # Populate Clipboard and Local History through ordinary editor commands.
        desktop.send('click', x=desktop.width//2+80, y=230)
        desktop.key('Control_L', 'a'); desktop.key('Control_L', 'c')
        desktop.key('Control_L', 'End'); desktop.key('Return'); desktop.key('a')
        desktop.key('Control_L', 's')
        desktop.send('wait', seconds=1)
        desktop.key('Control_L', 'z'); desktop.key('Control_L', 'z')
        desktop.key('Control_L', 's')
        desktop.send('wait', seconds=1)
        selector = None
        for index, name in enumerate(['files', 'toc', 'outline', 'commit', 'git-log', 'local-history', 'clipboard', 'references']):
            choose(desktop, index, rtl)
            desktop.capture(name)
            desktop.send('accessibility', name=name)
            picture = Image.open(output/(name+'.png')).convert('RGB')
            x = desktop.sidebar_menu_x(rtl)
            trigger = picture.crop((x-8, 74, x+8, 90)).tobytes()
            if selector is None: selector = trigger
            if not baseline and trigger != selector:
                raise RuntimeError('Sidebar View trigger pixels changed for '+name)
            if name == 'references':
                desktop.send('click', x=desktop.width-120 if rtl else 120, y=270, button=3)
                desktop.capture('references-context')
                desktop.key('Escape')
        # Close naturally and retain the existing unchanged-Git validation.
        desktop.close()
    except BaseException:
        if desktop.process.poll() is None:
            desktop.process.terminate(); desktop.process.wait(timeout=20)
        raise


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--baseline', action='store_true')
    parser.add_argument('--matrix', action='store_true')
    args=parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    parent=Path(tempfile.mkdtemp(prefix='sidebar-fixture-', dir=args.output.resolve()))
    root=fixture(parent)
    cases=[('light','en',1.0,False)]
    if args.matrix:
        cases=[(theme, locale, scale, narrow) for theme in ['light','dark']
               for locale in ['en','de','ja','ar'] for scale in [1.0,1.5] for narrow in [False,True]]
    (args.output/'fixture.json').write_text(json.dumps({'root':str(root),'cases':cases}, indent=2))
    for theme,locale,scale,narrow in cases:
        target=args.output/f'{theme}-{locale}-{scale}-{"narrow" if narrow else "normal"}'
        print(str(target), flush=True)
        run(args.binary.resolve(), target.resolve(), root, theme, locale, scale, narrow, args.baseline)


if __name__=='__main__': main()

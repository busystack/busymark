#!/usr/bin/env python3
"""Exercise the shipping Git Log on private native desktops; inspect the PNGs.

Uses real repository history and native pointer/keyboard input. The existing
desktop helper checks the compiled-source receipt, official engine and unchanged
repository. No application test hooks or substitute widgets are involved.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

from git_native_smoke import DesktopRun, fixture


def main():
    binary, output = map(lambda value: Path(value).resolve(), sys.argv[1:3])
    output.mkdir(parents=True, exist_ok=True)
    repository = output / 'repository'
    if not repository.exists():
        fixture(repository)
        for name in ['root.md', 'docs/guide.md', 'docs/nested/topic.md']:
            path = repository / name
            path.parent.mkdir(exist_ok=True, parents=True)
            path.write_text('# Historical tree geometry\n')
        subprocess.run(['git', '-C', str(repository), 'add', '.'], check=True)
        subprocess.run(['git', '-C', str(repository), 'commit', '-m',
                        'Review root and grouped historical files with native navigation'], check=True)
    def repository_state():
        return {name: subprocess.check_output(
            ['git', '-C', str(repository), *arguments], text=True)
            for name, arguments in {
                'head': ['rev-parse', '--verify', 'HEAD'],
                'branch': ['symbolic-ref', '--quiet', 'HEAD'],
                'references': ['show-ref'],
                'status': ['status', '--porcelain=v1'],
            }.items()}

    baseline_file = output / 'repository-baseline.json'
    if not baseline_file.exists():
        baseline_file.write_text(json.dumps(repository_state(), indent=2))
    baseline = json.loads(baseline_file.read_text())

    def record_identity(target):
        current = repository_state()
        path = target / 'receipt.json'
        receipt = json.loads(path.read_text())
        receipt['repositoryIdentityUnchanged'] = current == baseline
        receipt['repositoryIdentity'] = current
        path.write_text(json.dumps(receipt, indent=2))
        if current != baseline:
            raise RuntimeError(f'Repository HEAD/branch/refs/status changed: {target}')
    cases = [(theme, locale, scale) for theme in ['light', 'dark']
             for locale in ['en', 'de', 'ja', 'ar'] for scale in [1.0, 1.5]]
    if '--quick' in sys.argv:
        cases = cases[:1]
    for argument in sys.argv:
        if argument.startswith('--locale='):
            cases = [case for case in cases if case[1] == argument.split('=', 1)[1]]
        if argument.startswith('--case='):
            cases = [case for case in cases if '-'.join(map(str, case)) == argument.split('=', 1)[1]]
    failures = []
    for theme, locale, scale in cases:
        if repository_state() != baseline:
            raise RuntimeError('Native fixture identity differs from its baseline')
        target = output / f'{theme}-{locale}-{scale}'
        if target.exists():
            target = output / f'{theme}-{locale}-{scale}-retry-{time.time_ns()}'
        settings = target / 'xdg_data_home/io.busystack.busymark/settings.json'
        settings.parent.mkdir(parents=True, exist_ok=True)
        settings.write_text(json.dumps({
            'themeModePreference': theme, 'localeTag': locale,
            'trustedGitWorkspacePaths': [str(repository)],
            'documentViewMode': 'editor'}, ensure_ascii=False))
        print(f'Native navigation: {theme} {locale} {scale}', flush=True)
        d = DesktopRun(binary, target, repository, scale)
        rtl = locale == 'ar'
        d.key('Control_L', '4')
        d.wait_sidebar(rtl)
        d.log_view(rtl)
        d.send('move', x=d.width//2, y=500)
        d.capture('inspector-root-and-nested-files')
        if locale == 'en' and scale == 1.0:
            d.send('click', x=100, y=351)
            d.capture('historical-guide-comparison-tab')
            d.send('click', x=100, y=453)
            d.capture('independent-historical-comparison-tabs')
            d.send('click', x=100, y=453, button=3)
            d.capture('historical-file-context-menu')
            d.key('Escape')

        def selector():
            d.wait_sidebar(rtl, information=True)
            current_menu = d.sidebar_menu_x(rtl)
            d.send('click', x=current_menu + (42 if rtl else -42), y=122)
            d.wait_graph()
            d.wait_history()

        if '--dates-only' in sys.argv or '--narrow-only' in sys.argv:
            selector()
        else:
            selector()
            d.capture('history-sidebar-open')
            # The modal surface uses the application's documented 40px outer inset.
            toggle_x = d.width-68 if rtl else 68
            d.send('move', x=toggle_x, y=78)
            d.capture('header-toggle-hover')
            d.send('press', x=toggle_x, y=78)
            d.capture('header-toggle-pressed')
            d.send('release', x=toggle_x, y=78)
            d.capture('history-sidebar-closed')
            d.send('click', x=d.width-200 if rtl else 200, y=126)
            d.key('Shift_L', 'Tab')
            d.capture('header-toggle-keyboard-focus')
            d.key('space')
            d.send('move', x=700, y=500)
            d.capture('history-sidebar-reopened')
            if '--header-only' in sys.argv:
                d.key('Escape')
                d.close()
                record_identity(target)
                continue
            if locale == 'en' and scale == 1.0:
                search_x = 170 if not rtl else d.width-170
                d.send('click', x=search_x, y=120)
                d.send('text', value='origin')
                d.capture('reference-search')
                d.send('click', x=130 if not rtl else d.width-130, y=265, button=3)
                d.capture('reference-context-menu')
                d.key('Escape')
                d.key('Shift_L', 'F10')
                d.capture('reference-keyboard-context-menu')
                d.key('Escape')
                d.send('click', x=130 if not rtl else d.width-130, y=265)
                d.wait_history()
                d.capture('remote-reference-selected')
                d.send('click', x=toggle_x, y=78)
                d.capture('filtered-sidebar-hidden')
                d.send('click', x=toggle_x, y=78)
                d.capture('filtered-sidebar-restored')
                d.send('click', x=search_x, y=120)
                d.key('Control_L', 'a')
                d.key('BackSpace')
                d.send('click', x=120 if not rtl else d.width-120, y=197)
                d.capture('local-references-collapsed')
                d.send('click', x=toggle_x, y=78)
                d.send('click', x=toggle_x, y=78)
                d.capture('collapsed-group-restored')
                d.send('click', x=120 if not rtl else d.width-120, y=197)
                d.capture('local-references-expanded')
                for group, y in [('remote', 367), ('tags', 435)]:
                    d.send('click', x=120 if not rtl else d.width-120, y=y)
                    d.capture(f'{group}-references-collapsed')
                    d.send('click', x=120 if not rtl else d.width-120, y=y)
                    d.capture(f'{group}-references-expanded')
                d.send('click', x=search_x, y=120)
                d.send('text', value='main')
                d.capture('local-and-remote-results')
                d.send('click', x=120 if not rtl else d.width-120, y=231)
                d.wait_history()
                d.capture('local-reference-selected')
                d.send('click', x=search_x, y=120)
                d.key('Control_L', 'a')
                d.key('BackSpace')
            # At narrow widths the header opens the same pane as a temporary
            # overlay; closing it restores the readable table.
            d.send('resize', width=600, height=730)
            d.send('wait', seconds=2)
            d.capture('history-narrow-table')
            d.send('click', x=532 if rtl else 68, y=78)
            d.capture('history-narrow-reference-overlay')
            d.send('click', x=532 if rtl else 68, y=78)
            d.capture('history-narrow-overlay-closed')
            d.send('resize', width=d.width, height=d.height)
            d.send('wait', seconds=2)
            d.send('click', x=700, y=360)
            d.capture('different-candidate-before-cancel')
            d.key('Escape')
            d.capture('canceled-selection')
            selector()
            d.send('click', x=700, y=360)
            d.key('Return')
            d.capture('confirmed-selection-by-keyboard')
            selector()
        # Focus the final Path editor, then activate the next native control
        # (Date) with the keyboard. This is independent of translated widths.
        d.send('click', x=180 if rtl else 1000, y=126)
        d.key('Tab')
        d.key('Return')
        if '--narrow-only' in sys.argv:
            d.send('resize', width=600, height=730)
            d.send('wait', seconds=2)
            d.capture('date-narrow-empty')
            d.key('Tab')
            d.capture('date-narrow-keyboard-focus')
            d.key('Escape')
            d.key('Escape')
            try:
                d.close()
            except RuntimeError as error:
                failures.append({'case': target.name, 'failure': str(error)})
            record_identity(target)
            continue
        # Clear through the real editing controls, even if a reviewed range
        # was restored with workspace state. The empty capture must be empty.
        for y in [330, 420]:
            d.send('click', x=520, y=y)
            d.key('Control_L', 'a')
            d.key('BackSpace')
        d.capture('date-empty')
        d.send('click', x=520, y=330)
        d.capture('date-start-focused')
        dates = {
            'en': ('11/04/2026', '11/01/2026', '11/05/2026'),
            'de': ('04.11.2026', '01.11.2026', '05.11.2026'),
            'ja': ('2026/11/04', '2026/11/01', '2026/11/05'),
            'ar': ('04/11/2026', '01/11/2026', '05/11/2026'),
        }[locale]
        def type_date(value):
            d.send('text', value=value)
        type_date(dates[0])
        d.send('click', x=520, y=420)
        type_date(dates[1])
        d.capture('date-invalid-range')
        d.key('Control_L', 'a')
        type_date(dates[2])
        d.capture('date-corrected-range')
        picture = d.checkpoint()
        footer = picture.crop((370 if rtl else 820, 445, 480 if rtl else 920, 530))
        orange = sum(count for count, (r, g, b) in footer.getcolors(footer.width * footer.height)
                     if r > 180 and 50 < g < 160 and b < 90)
        if orange < 150:
            raise RuntimeError(f'Date Save did not become enabled; inspect {target}')
        d.key('Return')
        d.wait_history()
        d.capture('date-saved-filter')
        d.send('click', x=180 if rtl else 1000, y=126)
        d.key('Tab')
        d.key('Return')
        d.capture('date-reopened-values')
        d.send('resize', width=600, height=730)
        d.send('wait', seconds=2)
        d.capture('date-narrow-reopened-values')
        d.key('Tab')
        d.capture('date-narrow-keyboard-focus')
        d.send('resize', width=d.width, height=d.height)
        d.send('wait', seconds=2)
        d.key('Escape')
        d.capture('date-cancel-preserves-filter')
        d.key('Escape')
        d.capture('final-inspector-idle')
        try:
            d.close()
        except RuntimeError as error:
            failures.append({'case': target.name, 'failure': str(error)})
            print(f'Native lifecycle check failed: {target.name}: {error}', flush=True)
        record_identity(target)
    summary = output / ('lifecycle-failures-' + '-'.join(sorted({case[1] for case in cases}))
                        + f'-{time.time_ns()}.json')
    summary.write_text(json.dumps(failures, indent=2))
    if failures:
        raise RuntimeError(f'Native lifecycle failures remain; inspect {summary}')
    print('Native inputs complete. Inspect the captures and receipts.', flush=True)


if __name__ == '__main__':
    main()

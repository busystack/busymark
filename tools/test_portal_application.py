#!/usr/bin/python3
"""Controlled portal acceptance through the existing compiled close observer.

Use an owned disposable X11 display. Deliberate portal withholding is functional
proof, never a natural startup benchmark. A confined fixture must use a disposable
parallel Snap and output under its common directory. Snap launches on the normal
session bus; only the application then selects the owned test bus. No host portal
service or desktop configuration is changed.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

from application_close_smoke import accepted
from portal_test_support import Fixture, expect_snapshot

HERE = Path(__file__).resolve().parent


def wait_status(report, phase, process, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            status = json.loads(report.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            status = {}
        if status.get('phase') == 'failed':
            raise AssertionError(status)
        if status.get('phase') == phase:
            return status
        if process.poll() is not None:
            raise AssertionError('Close observer exited before ' + phase)
        time.sleep(.02)
    raise AssertionError('Compiled application did not progress to ' + phase)


def local_schemas(root, backend, accessibility=False):
    root.mkdir()
    sources = Path('/usr/share/glib-2.0/schemas')
    for source in sources.glob('*.xml'):
        shutil.copy2(source, root / source.name)
    memory_a11y = accessibility and backend == 'memory'
    (root / '99-busymark-portal-test.gschema.override').write_text(
        "[org.gnome.desktop.interface]\nclock-format='24h'\n"
        "gtk-theme='Adwaita'\ncolor-scheme='prefer-light'\n"
        f"enable-animations={str(not memory_a11y).lower()}\n"
        f"text-scaling-factor={'1.0' if backend == 'dconf' else '1.25'}\n"
        "[org.gnome.desktop.a11y.interface]\n"
        f"high-contrast={str(memory_a11y).lower()}\n")
    subprocess.run(['/usr/bin/glib-compile-schemas', '--strict', str(root)], check=True)


def exercise(args, name, root):
    held = name in ['delayed', 'close-pending', 'restart', 'local-accessibility',
                    'application-preference']
    hold = 'getall' if name == 'getall-pending' else 'read' if held else 'none'
    f = Fixture(root, Path('/not-used'), ['--hold', hold],
                missing=name == 'missing', socket_parent=args.socket_parent)
    observer = report = None
    error = None
    try:
        f.start_bus()
        schemas = root / 'schemas'
        local_schemas(schemas, args.settings_backend, name == "local-accessibility")
        database = None
        if args.settings_backend == 'dconf':
            keys = root / 'dconf-keys'
            keys.mkdir()
            (keys / '10-local').write_text(
                "[org/gnome/desktop/interface]\nclock-format='24h'\n"
                "gtk-theme='Adwaita'\ncolor-scheme='prefer-light'\n"
                f"enable-animations={str(name != 'local-accessibility').lower()}\ntext-scaling-factor=1.25\n"
                "[org/gnome/desktop/a11y/interface]\n"
                f"high-contrast={str(name == 'local-accessibility').lower()}\n")
            database = root / 'local-settings.db'
            subprocess.run(['/usr/bin/dconf', 'compile', str(database), str(keys)], check=True)
            f.record['localBackend'] = 'dconf; compiled synthetic DB scale1.25 versus schema default1.0'
        else:
            f.record['localBackend'] = 'memory; synthetic schema default1.25'
        output = root / 'compiled'
        if name in ['application-preference', 'fast-preference']:
            # The compiled fixture seeds its observer-created isolated profile
            # before application.main. Do not pre-create the observer's fresh
            # evidence root: its refusal to overwrite evidence must remain.
            (root / 'portal-initial-theme').write_text('dark')
        report = output / '0-portal-settings/application.json'
        command = ['/usr/bin/python3', str(HERE / 'application_close_smoke.py'),
                   '--output', str(output), '--cycles', '1', '--fresh-profile',
                   '--scenarios', 'portal-settings', '--audit-input',
                   '--settings-schema-dir', str(schemas), '--portal-bus-address', f.address,
                   '--settings-backend', args.settings_backend]
        if args.engine_manifest is not None:
            command += ['--expected-engine', str(args.engine_manifest)]
        if database is not None:
            command += ['--local-settings-db', str(database)]
        if args.snap_instance:
            command += ['--snap-instance', args.snap_instance, '--snap-fixture']
        else:
            command += ['--', str(args.application)]
        # Preserve the real session bus until snap-confine has created its
        # normal systemd scope. The observer transfers the private bus address
        # only inside the confined application, without a policy change.
        observer = f.launch(command, 'compiled-observer', environment=os.environ.copy())
        if held:
            f.held()
        # GTK's synchronous proxy constructor can time out after 25 seconds.
        # Waiting for that timeout would falsely certify responsiveness. The
        # controlled GetAll case must publish a real frame/editor while the
        # service is withholding replies, within the original 5-second bound.
        initial = wait_status(report, 'portal-local', observer,
                              timeout=5 if name == 'getall-pending' else 40)
        assert initial['localFramesProgressed'] and initial['portalEditorPublished'], initial
        snapshots = initial['settingsSnapshots']
        assert snapshots, initial
        if name in ['application-preference', 'fast-preference']:
            assert initial['applicationThemeSnapshots'][0] == 'dark', initial
        if name == 'local-accessibility':
            assert snapshots[0] == dict(clock12=False, dark=False, animations=False, contrast=True, scale=1.25), snapshots
        elif name not in ['fast', 'fast-preference', 'getall-pending']:
            expect_snapshot(snapshots[0], nondefault=False, scale=1.25)
        expected = dict(clock12=True, dark=True, animations=False, contrast=True, scale=1.5)
        if name not in ['close-pending', 'missing']:
            if name == 'restart':
                f.command('drop')
                f.start_service(['--scale', '2'])
                expected['scale'] = 2
            elif name != 'getall-pending':
                f.command('release')
            # Properties.GetAll must remain withheld until the process has
            # naturally closed. This exercises startup consumers outside the
            # Flutter settings provider, including GTK's Inhibit proxy.
            Path(str(report) + '.portal-authority').write_text(json.dumps(expected))
            authority = wait_status(report, 'portal-authority', observer)
            expect_snapshot(authority['authoritySettingsVerified'], scale=expected['scale'])
            assert len(authority['settingsSnapshots']) <= 2, authority
            assert authority['portalApplicationThemePreserved'], authority
            if name == 'restart':
                f.command('release')  # Stale owner responses must not win.
        Path(str(report) + '.portal-close').touch()
        observer.wait(timeout=80)
        summary = json.loads((output / 'summary.json').read_text())
        assert observer.returncode == 0 and summary['failures'] == 0, summary
        assert all(accepted(record) for record in summary['records']), summary
        f.record['compiledSummary'] = summary
        f.client = observer  # Already naturally exited; fixture owns identity.
    except Exception as failure:
        error = repr(failure)
    finally:
        # Restore only owned fixture barriers. Retain the failed classification,
        # then let the normal application/observer close before scoped cleanup.
        if observer is not None and observer.poll() is None:
            for _, channel in f.services:
                try:
                    channel.send({'action': 'release'})
                except OSError:
                    pass
            if report is not None:
                report.parent.mkdir(parents=True, exist_ok=True)
                Path(str(report) + '.portal-close').touch()
            try:
                observer.wait(timeout=85)
            except subprocess.TimeoutExpired:
                pass
        if observer is not None and observer.poll() is not None:
            f.client = observer
        result = f.cleanup(error)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--application', type=Path)
    parser.add_argument('--snap-instance')
    parser.add_argument('--expected-engine', '--engine-manifest', dest='engine_manifest', type=Path,
                        help='Optional expected official engine library; no production receipt required')
    parser.add_argument('--settings-backend', choices=['memory', 'dconf'], default='dconf')
    parser.add_argument('--socket-parent', type=Path,
                        help='Short writable common-directory path for confined UNIX sockets')
    cases = ['fast', 'fast-preference', 'delayed', 'close-pending', 'missing', 'restart',
             'local-accessibility', 'application-preference', 'getall-pending']
    parser.add_argument('--cases', nargs='+', choices=cases, default=cases)
    args = parser.parse_args()
    if bool(args.application) == bool(args.snap_instance):
        parser.error('Select one compiled application or disposable parallel Snap')
    args.output = args.output.resolve()
    if args.engine_manifest is not None:
        args.engine_manifest = args.engine_manifest.resolve()
    if args.application:
        args.application = args.application.resolve()
    args.output.mkdir(parents=True, exist_ok=False)
    records = []
    for name in args.cases:
        record = exercise(args, name, args.output / name)
        records.append(dict(case=name, **record))
        (args.output / 'summary.json').write_text(json.dumps(records, indent=2))
        print(name, 'PASS' if record['ok'] else 'FAIL', flush=True)
        if not record['ok']:
            raise SystemExit('Compiled portal acceptance failed: ' + str(args.output))


if __name__ == '__main__':
    main()

"""Build-policy and CI topology controls, separate from GTK acceptance.

Uses PyYAML (a CI test prerequisite). Comments/documentation are not policy.
The Snap recipe pins the official archive; CI must select that same version.
"""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import unittest
from urllib.parse import urlparse

import yaml

ROOT = Path(__file__).resolve().parent.parent


class OfficialFlutterWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = yaml.safe_load((ROOT / '.github/workflows/flutter-linux.yml').read_text())
        cls.native = yaml.safe_load((ROOT / '.github/workflows/flutter-linux-native.yml').read_text())
        cls.recipe = yaml.safe_load((ROOT / 'snap/snapcraft.yaml').read_text())

    def test_ci_and_snap_select_the_same_official_archive(self):
        sdk = self.recipe['parts']['flutter-sdk']
        url = urlparse(sdk['source'])
        self.assertEqual((url.scheme, url.netloc), ('https', 'storage.googleapis.com'))
        match = re.fullmatch(r'/flutter_infra_release/releases/stable/linux/flutter_linux_(\d+\.\d+\.\d+)-stable.tar.xz', url.path)
        self.assertIsNotNone(match)
        self.assertRegex(sdk['source-checksum'], r'^sha256/[a-f0-9]{64}$')
        selections = [s['with'] for workflow in [self.workflow, self.native] for job in workflow['jobs'].values()
                      for s in job.get('steps', []) if s.get('uses', '').startswith('subosito/flutter-action@')]
        self.assertTrue(selections)
        for selection in selections:
            self.assertEqual(selection['flutter-version'], match[1])
            self.assertEqual(selection['channel'], 'stable')
        self.assertEqual(self.native['jobs']['development-modes']['strategy']['matrix']['mode'], ['debug', 'profile'])
        self.assertEqual(self.recipe['confinement'], 'strict')

    def test_snap_runtime_copies_unmodified_official_sdk_payload(self):
        script = self.recipe['parts']['flutter-runtime']['override-build']
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            stage, output = root / 'stage', root / 'install'
            library = stage / 'flutter-sdk/bin/cache/artifacts/engine/linux-x64-release/libflutter_linux_gtk.so'
            library.parent.mkdir(parents=True)
            library.write_bytes(b'\x7fELFowned official-payload control')
            subprocess.run(['bash', '-euc', script], check=True, env={**os.environ, 'CRAFT_STAGE': str(stage), 'CRAFT_PART_INSTALL': str(output)})
            self.assertEqual((output / 'lib/libflutter_linux_gtk.so').read_bytes(), library.read_bytes())

    def test_tooling_job_installs_its_python_test_dependencies(self):
        script = next(s for s in self.workflow['jobs']['verify']['steps'] if s.get('id') == 'linux-dependencies')['run']
        # Parse executed command tokens, not a comment mentioning the packages.
        commands = [shlex.split(line, comments=True) for line in script.replace('\\\n', '').splitlines()]
        packages = {arg for command in commands if command[:3] == ['sudo', 'apt-get', 'install']
                    for arg in command[3:]}
        self.assertTrue({'python3-pil', 'python3-yaml'}.issubset(packages))

    def test_snap_build_invokes_selected_sdk_with_locked_inputs(self):
        # Execute the real build preamble in a disposable tree. The SDK spy
        # stops at build admission, before compilation or staging. Documentation
        # and comments cannot affect these assertions about actual argv.
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            stage = root / 'stage'
            sdk = stage / 'flutter-sdk'
            (sdk / 'bin').mkdir(parents=True)
            spy = sdk / 'bin/flutter'
            spy.write_text('''#!/usr/bin/python3
import json, os, sys
with open(os.environ['BUILD_CALLS'], 'a') as output:
    output.write(json.dumps(sys.argv) + '\\n')
raise SystemExit(77 if sys.argv[1:2] == ['build'] else 0)
''')
            spy.chmod(0o700)
            calls = root / 'calls.jsonl'
            result = subprocess.run(['bash', '-euc', self.recipe['parts']['busymark']['override-build']],
                                    cwd=root, env={**os.environ, 'CRAFT_STAGE': str(stage),
                                                   'CRAFT_PART_BUILD': str(root / 'build'),
                                                   'CRAFT_PART_INSTALL': str(root / 'install'),
                                                   'BUILD_CALLS': str(calls)}, capture_output=True, text=True)
            self.assertEqual(result.returncode, 77, result.stdout + result.stderr)
            invocations = [json.loads(line) for line in calls.read_text().splitlines()]
            self.assertEqual(invocations[0], [str(spy), 'pub', 'get', '--enforce-lockfile'])
            self.assertEqual(invocations[1], [str(spy), 'build', 'linux', '--release', '--no-pub',
                                               '--verbose', '--target', 'lib/main.dart'])

    def test_local_repack_resolves_sdk_names_and_paths_before_building(self):
        # Run the helper, stopping at dependency resolution. No scaffold is
        # consumed, compiled payload staged, or installed application touched.
        cases = ['default', 'command', 'absolute', 'relative', 'missing',
                 'nonexecutable', 'wrong-version']
        for case in cases:
            with self.subTest(selection=case), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                (root / 'tools').mkdir()
                (root / 'linux').mkdir()
                for name in ['tools/build_install_snap_local.sh', 'pubspec.yaml',
                             'linux/CMakeLists.txt']:
                    shutil.copyfile(ROOT / name, root / name)
                (root / 'bin').mkdir()
                spy = root / 'bin/flutter'
                spy.write_text('''#!/usr/bin/python3
import json, os, sys
with open(os.environ['BUILD_CALLS'], 'a') as output:
    output.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1:] == ['--version', '--machine']:
    print(json.dumps({'frameworkVersion': os.environ['SPY_VERSION']}))
    raise SystemExit(0)
raise SystemExit(77 if sys.argv[1:] == ['pub', 'get', '--enforce-lockfile'] else 99)
''')
                spy.chmod(0o600 if case == 'nonexecutable' else 0o700)
                calls = root / 'calls.jsonl'
                protected = root / 'snap-root'
                protected.mkdir()
                (protected / 'sentinel').write_text('preserve')
                env = {key: value for key, value in os.environ.items()
                       if not key.startswith('BUSYMARK_')}
                env.update(PATH=str(spy.parent) + ':/usr/bin:/bin', HOME=str(root),
                           BUILD_CALLS=str(calls), SPY_VERSION='0.0.0' if case == 'wrong-version' else '3.47.5',
                           BUSYMARK_BUILD_TMP_ROOT=str(root / 'tmp'))
                if case != 'default':
                    env['BUSYMARK_FLUTTER_BIN'] = {
                        'command': 'flutter', 'relative': './bin/flutter',
                        'missing': 'no-such-owned-sdk',
                    }.get(case, str(spy))
                result = subprocess.run(
                    ['bash', str(root / 'tools/build_install_snap_local.sh'),
                     '--no-install', '--no-run', '--skip-tests', '--skip-bundled-git',
                     '--root', str(protected), '--scaffold', str(root / 'unused'),
                     '--output', str(root / 'unused.snap')],
                    cwd=root, env=env, capture_output=True, text=True, timeout=15)
                observed = [json.loads(line) for line in calls.read_text().splitlines()] if calls.exists() else []
                if case in ['missing', 'nonexecutable', 'wrong-version']:
                    self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                    self.assertEqual(observed, [['--version', '--machine']] if case == 'wrong-version' else [])
                    self.assertIn('official Flutter 3.47.5', result.stderr)
                else:
                    self.assertEqual(result.returncode, 77, result.stdout + result.stderr)
                    self.assertEqual(observed, [['--version', '--machine'], ['pub', 'get', '--enforce-lockfile']])
                self.assertEqual((protected / 'sentinel').read_text(), 'preserve')
                self.assertFalse((root / 'unused.snap').exists())

    def test_pull_requests_cover_the_integrated_release_and_main(self):
        triggers = self.workflow.get('on', self.workflow.get(True))
        self.assertTrue({'main', 'release/v0.6.3'}.issubset(triggers['pull_request']['branches']))
        self.assertIn('main', triggers['push']['branches'])
        for event in ['pull_request', 'push']:
            self.assertNotIn('paths', triggers[event])
            self.assertNotIn('paths-ignore', triggers[event])
        self.assertNotIn('pull_request_target', triggers)
        self.assertEqual(self.workflow['permissions'], {'contents': 'read'})
        native_triggers = self.native.get('on', self.native.get(True))
        self.assertIn('workflow_dispatch', native_triggers)

    def _automatic_native_jobs(self):
        callers = [job for job in self.workflow['jobs'].values()
                   if job.get('uses') == './.github/workflows/flutter-linux-native.yml']
        self.assertEqual(len(callers), 1)
        caller = callers[0]
        self.assertNotIn('if', caller)
        self.assertNotIn('needs', caller)
        self.assertNotIn('continue-on-error', caller)
        self.assertIs(caller['with']['run-stress'], False)
        triggers = self.native.get('on', self.native.get(True))
        setting = triggers['workflow_call']['inputs']['run-stress']
        self.assertEqual(setting['type'], 'boolean')
        self.assertIs(setting['default'], False)
        for name in ['verify', 'snap']:
            self.assertNotIn('if', self.native['jobs'][name])
            self.assertNotIn('needs', self.native['jobs'][name])
        return self.native['jobs']

    def test_automatic_native_checks_reach_packages_dictionaries_and_wayland(self):
        jobs = self._automatic_native_jobs()
        required = {
            'verify': [
                ('test -s "$spelling_root/dictionaries.json"', ['release-build']),
                ('dictionaryInstalledDuringRun', ['release-build']),
                ('GDK_BACKEND=wayland', ['release-build', 'web-sandbox']),
            ],
            'snap': [
                ('sudo snap install --dangerous "${{ steps.snap-artifact.outputs.snap }}"',
                 ['snap-artifact', 'strict-desktop']),
                ('gdk-pixbuf-query-loaders', ['strict-install', 'strict-session']),
                ('inspect_dependencies()', ['strict-install', 'strict-session']),
                ('before_revision=', ['strict-install', 'strict-session']),
                ('visualization-release-x11.json', ['strict-install', 'strict-session']),
                ('GDK_BACKEND=wayland', ['strict-install', 'strict-session']),
            ],
        }
        for job_name, checks in required.items():
            steps = jobs[job_name]['steps']
            by_id = {s['id']: s for s in steps if 'id' in s}
            for invocation, prerequisites in checks:
                with self.subTest(job=job_name, invocation=invocation):
                    matches = [s for s in steps if invocation in s.get('run', '')]
                    self.assertEqual(len(matches), 1)
                    step = matches[0]
                    gates = [f"steps.{name}.outcome == 'success'" for name in prerequisites]
                    if job_name == 'verify' and invocation == 'GDK_BACKEND=wayland':
                        gates.insert(1, "(!inputs.run-stress || steps.release-main.outcome == 'success')")
                    self.assertEqual(step['if'], '${{ !cancelled() && ' + ' && '.join(gates) + ' }}')
                    self.assertNotIn('continue-on-error', step)
                    for prerequisite in prerequisites:
                        self.assertLess(steps.index(by_id[prerequisite]), steps.index(step))
                        self.assertIn(f"steps.{prerequisite}.outcome == 'success'", step['if'])
            dictionary = next(s for s in steps if 'dictionaryInstalledDuringRun' in s.get('run', ''))
            for assertion in ['dictionaryInstalledDuringRun', 'personalWordPresentBeforeRun', 'report["ok"]']:
                self.assertIn(assertion, dictionary['run'])
            self.assertIn('xvfb-run', dictionary['run'])
            self.assertIn('GDK_BACKEND=x11', dictionary['run'])
            offline = 'unshare --net' if job_name == 'verify' else 'sudo snap disconnect busymark:network'
            self.assertIn(offline, dictionary['run'])

    def test_automatic_wayland_checks_prepare_a_compositor_and_shipping_binary(self):
        jobs = self._automatic_native_jobs()
        for name in ['verify', 'snap']:
            steps = jobs[name]['steps']
            step = next(s for s in steps if 'GDK_BACKEND=wayland' in s.get('run', ''))
            dependencies = next(s for s in steps if s.get('id') ==
                                ('linux-dependencies' if name == 'verify' else 'strict-desktop'))
            commands = [shlex.split(line, comments=True) for line in
                        dependencies['run'].replace('\\\n', '').splitlines()]
            installed = {arg for command in commands
                         if command[:3] == ['sudo', 'apt-get', 'install']
                         for arg in command[3:]}
            self.assertTrue({'weston', 'xvfb'}.issubset(installed))
            self.assertLess(steps.index(dependencies), steps.index(step))
            for prerequisite in ['weston --backend=headless-backend.so',
                                 'test -S "$runtime_dir/wayland-99"',
                                 'WAYLAND_DISPLAY=wayland-99', '--spelling-release-smoke=',
                                 '--visualization-release-smoke=', 'report["ok"]', 'test -s']:
                self.assertIn(prerequisite, step['run'])
            if name == 'verify':
                self.assertIn("(!inputs.run-stress || steps.release-main.outcome == 'success')", step['if'])
                self.assertIn('build/linux/x64/release/bundle/busymark', step['run'])
                self.assertIn('tools/visualization_smoke.py', step['run'])
            else:
                self.assertIn('snap run busymark', step['run'])
                self.assertNotIn('strict-parallel', step['if'])
                self.assertNotIn('busymark_close', step['run'])

    def test_stress_campaigns_remain_explicit(self):
        jobs = self._automatic_native_jobs()
        triggers = self.native.get('on', self.native.get(True))
        self.assertIs(triggers['workflow_dispatch']['inputs']['run-stress']['default'], True)
        self.assertEqual(jobs['development-modes']['if'], '${{ inputs.run-stress }}')
        gated_ids = {'release-fixture', 'release-main', 'strict-parallel',
                     'strict-close-install', 'strict-fixture-source',
                     'close-fixture-snap', 'strict-fixture-install'}
        found = set()
        for name in ['verify', 'snap']:
            for step in jobs[name]['steps']:
                script = step.get('run', '')
                if step.get('id') in gated_ids:
                    found.add(step['id'])
                if (step.get('id') in gated_ids or '--cycles 100' in script or
                        '--cycles 3 --fresh-profile' in script):
                    self.assertIn('inputs.run-stress &&', step['if'])
        self.assertEqual(found, gated_ids)

    def test_standalone_desktop_sessions_are_scoped(self):
        steps = self._automatic_native_jobs()['verify']['steps']
        dependencies = next(s for s in steps if s.get('id') == 'linux-dependencies')
        commands = [shlex.split(line, comments=True) for line in
                    dependencies['run'].replace('\\\n', '').splitlines()]
        installed = {arg for command in commands
                     if command[:3] == ['sudo', 'apt-get', 'install']
                     for arg in command[3:]}
        self.assertIn('dbus-daemon', installed)
        for selector, count in [('dictionaryInstalledDuringRun', 2),
                                ('GDK_BACKEND=wayland', 3)]:
            step = next(s for s in steps if selector in s.get('run', ''))
            command = step['run'].replace('\\\n', '')
            self.assertEqual(len(re.findall(r'dbus-run-session\s+--\s+env\b', command)), count)
            self.assertNotIn('dbus-launch', command)

    def test_wayland_checks_run_independently_and_preserve_failures(self):
        jobs = self._automatic_native_jobs()
        block = re.compile(
            r"(?P<start>bash -euo pipefail <<'(?P<tag>\w+)' \|\| checks_failed=1\n)"
            r"(?P<body>.*?)(?P<end>\n(?P=tag)\n)", re.DOTALL)
        for job, expected in [('verify', ['spelling', 'renderers', 'compiled']),
                              ('snap', ['spelling', 'compiled'])]:
            script = next(s['run'] for s in jobs[job]['steps']
                          if 'GDK_BACKEND=wayland' in s.get('run', ''))
            self.assertRegex(script, r'(?m)^export runtime_dir$')
            orchestration = script[script.index('checks_failed=0'):]

            def product(match):
                tokens = shlex.split(match['body'].replace('\\\n', ''), comments=True)
                if any(token.startswith('--spelling-release-smoke=') for token in tokens):
                    return 'spelling'
                if 'tools/visualization_smoke.py' in tokens:
                    return 'renderers'
                if any(token.startswith('--visualization-release-smoke=') for token in tokens):
                    return 'compiled'
                self.fail('Wayland child has no required product invocation')

            self.assertEqual([product(match) for match in block.finditer(orchestration)], expected)
            # Execute the maintained parent shell with controlled child outcomes.
            # A failed spelling, renderer or compiled check must not hide a later
            # result, and every failure must still fail the overall step.
            for failed in [None, *expected]:
                with self.subTest(job=job, failed=failed), tempfile.TemporaryDirectory() as temp:
                    calls = Path(temp) / 'calls'

                    def controlled_child(match):
                        name = product(match)
                        return (match['start'] +
                                f"printf '%s\\n' {shlex.quote(name)} >> \"$CALLS\"\n"
                                f"exit {int(name == failed)}" + match['end'])

                    result = subprocess.run(
                        ['bash', '-euo', 'pipefail', '-c',
                         block.sub(controlled_child, orchestration)],
                        env={**os.environ, 'CALLS': str(calls)},
                        capture_output=True, text=True)
                    self.assertEqual(result.returncode, int(failed is not None),
                                     result.stdout + result.stderr)
                    self.assertEqual(calls.read_text().splitlines(), expected)

    def test_automatic_product_checks_use_a_prepared_release_and_desktop(self):
        steps = self.workflow['jobs']['verify']['steps']
        build = next(s for s in steps if s.get('id') == 'release-build')
        dependencies = next(s for s in steps if s.get('id') == 'linux-dependencies')
        node = next(s for s in steps if s.get('id') == 'node')
        packages = next(s for s in steps if s.get('id') == 'flutter-packages')
        sandbox = next(s for s in steps if s.get('id') == 'web-sandbox')
        self.assertIn('flutter build linux --release', build['run'])
        self.assertIn('flutter pub get --enforce-lockfile', packages['run'])
        for prerequisite in [dependencies, node, packages]:
            self.assertLess(steps.index(prerequisite), steps.index(build))
            self.assertIn(f"steps.{prerequisite['id']}.outcome == 'success'", build['if'])
        scripts = '\n'.join(step.get('run', '') for step in steps)
        self.assertIn('flutter test --concurrency=2', scripts)
        for invocation in ['tools/test_gtk_accent_host.sh', 'tools/test_web_render_host.sh',
                           'tools/visualization_smoke.py', '--visualization-release-smoke=']:
            matching = [s for s in steps if invocation in s.get('run', '')]
            self.assertEqual(len(matching), 1, invocation)
            step = matching[0]
            self.assertLess(steps.index(build), steps.index(step))
            self.assertIn("steps.release-build.outcome == 'success'", step['if'])
            self.assertIn('!cancelled()', step['if'])
            self.assertIn('xvfb-run', step['run'])
            self.assertIn('GDK_BACKEND=x11', step['run'])
            self.assertNotIn('continue-on-error', step)
            self.assertNotIn('|| true', step['run'])
            if invocation != 'tools/test_gtk_accent_host.sh':
                self.assertLess(steps.index(sandbox), steps.index(step))
                self.assertIn("steps.web-sandbox.outcome == 'success'", step['if'])
            if invocation == 'tools/visualization_smoke.py':
                for resource in ['/share/busymark/visualization', '/libexec/busymark/d2']:
                    self.assertIn('build/linux/x64/release/bundle' + resource, step['run'])
            if invocation == '--visualization-release-smoke=':
                self.assertIn('build/linux/x64/release/bundle/busymark', step['run'])
                self.assertIn('report["ok"]', step['run'])
                self.assertIn('test -s', step['run'])

    def test_native_shortcut_metadata_runs_with_compiler_and_display_prerequisites(self):
        steps = self.workflow['jobs']['verify']['steps']
        step = next(s for s in steps if 'tools/test_native_shortcut_metadata.sh' in s.get('run', ''))
        dependencies = next(s for s in steps if s.get('id') == 'linux-dependencies')
        self.assertLess(steps.index(dependencies), steps.index(step))
        self.assertIn("steps.linux-dependencies.outcome == 'success'", step['if'])
        self.assertIn('!cancelled()', step['if'])
        self.assertNotIn('continue-on-error', step)
        commands = [shlex.split(line, comments=True) for line in
                    dependencies['run'].replace('\\\n', '').splitlines()]
        installed = {arg for command in commands
                     if command[:3] == ['sudo', 'apt-get', 'install']
                     for arg in command[3:]}
        self.assertTrue({'clang', 'pkg-config', 'libgtk-3-dev', 'xvfb'}.issubset(installed))
        self.assertEqual(shlex.split(step['run']), [
            'xvfb-run', '-a', 'env', 'GDK_BACKEND=x11',
            'bash', 'tools/test_native_shortcut_metadata.sh',
        ])

    def test_automatic_gtk_probes_have_display_and_build_prerequisites(self):
        steps = self.workflow['jobs']['verify']['steps']
        for script, prerequisite in [
                ('tools/test_gtk_accent.sh', 'linux-dependencies'),
                ('tools/test_native_shortcut_metadata.sh', 'linux-dependencies'),
                ('tools/test_gtk_accent_host.sh', 'release-build')]:
            with self.subTest(script=script):
                matches = [s for s in steps if script in s.get('run', '')]
                self.assertEqual(len(matches), 1)
                step = matches[0]
                self.assertEqual(shlex.split(step['run']),
                                 ['xvfb-run', '-a', 'env', 'GDK_BACKEND=x11', 'bash', script])
                preparation = next(s for s in steps if s.get('id') == prerequisite)
                self.assertLess(steps.index(preparation), steps.index(step))
                self.assertIn(f"steps.{prerequisite}.outcome == 'success'", step['if'])
                self.assertIn('!cancelled()', step['if'])
                self.assertNotIn('continue-on-error', step)

    def test_native_failures_remain_required_and_independent(self):
        ordinary_counts = {}
        for job_name, job in self.native['jobs'].items():
            steps = job['steps']
            ids = {step['id'] for step in steps if 'id' in step}
            for step in steps:
                script = step.get('run', '')
                condition = step.get('if', '')
                for prerequisite in re.findall(r"steps.([\w-]+).outcome == 'success'", condition):
                    self.assertIn(prerequisite, ids)
                    self.assertIn('!cancelled()', condition)
                if 'tools/application_close_smoke.py' in script:
                    self.assertNotIn('continue-on-error', step)
                    self.assertNotIn('|| true', script)
                    # Preserve stress counts, provenance and ordinary closure.
                    if '--plain' in script or '--snap-instance busymark_close' in script:
                        ordinary_counts[job_name] = int(re.search(r'--cycles (\d+)', script)[1])
                        self.assertIn('--expected-engine', script)
        self.assertEqual(ordinary_counts, {'verify': 100, 'snap': 100, 'development-modes': 10})

    def test_development_modes_prepare_locked_dependencies(self):
        steps = self.native['jobs']['development-modes']['steps']
        preparation = [step for step in steps
                       if step.get('run', '').strip() == 'flutter pub get --enforce-lockfile']
        self.assertEqual(len(preparation), 1)
        # Clean jobs need dependency resolution before either --no-pub build.
        self.assertIn("steps.flutter-sdk.outcome == 'success'", preparation[0]['if'])
        self.assertIn('!cancelled()', preparation[0]['if'])
        self.assertNotIn('continue-on-error', preparation[0])
        builds = [step for step in steps
                  if step.get('run', '').startswith('flutter build linux ')]
        self.assertEqual(len(builds), 2)
        for build in builds:
            with self.subTest(build=build['name']):
                self.assertIn('--no-pub', shlex.split(build['run']))
                self.assertLess(steps.index(preparation[0]), steps.index(build))

    def test_native_runners_prepare_webkit_without_blocking_plain_closes(self):
        for job_name, build_id in [('verify', 'release-build'),
                                   ('development-modes', 'mode-build')]:
            with self.subTest(job=job_name):
                steps = self.native['jobs'][job_name]['steps']
                by_id = {step['id']: step for step in steps if 'id' in step}
                dependencies = by_id['linux-dependencies']
                commands = [shlex.split(line) for line in
                            dependencies['run'].replace('\\\n', '').splitlines()]
                installed = {arg for command in commands
                             if command[:3] == ['sudo', 'apt-get', 'install']
                             for arg in command[3:]}
                self.assertTrue({'apparmor-profiles', 'bubblewrap'}.issubset(installed))
                sandbox = by_id['web-sandbox']
                self.assertLess(steps.index(dependencies), steps.index(sandbox))
                self.assertIn("steps.linux-dependencies.outcome == 'success'", sandbox['if'])
                self.assertIn('bwrap --ro-bind / / --unshare-user --unshare-pid', sandbox['run'])
                self.assertIn('/usr/share/apparmor/extra-profiles/bwrap-userns-restrict', sandbox['run'])
                self.assertNotIn('continue-on-error', sandbox)
                build = by_id[build_id]
                for prerequisite in ['linux-dependencies', 'node', 'flutter-packages']:
                    self.assertLess(steps.index(by_id[prerequisite]), steps.index(build))
                    self.assertIn(f"steps.{prerequisite}.outcome == 'success'", build['if'])
                self.assertNotIn('steps.web-sandbox', build['if'])
                for step in steps:
                    script = step.get('run', '')
                    if 'tools/application_close_smoke.py' in script and '--plain' in script:
                        self.assertNotIn('steps.web-sandbox', step['if'])
                    if '--video ' in script or 'tools/visualization_smoke.py' in script:
                        self.assertLess(steps.index(sandbox), steps.index(step))
                        self.assertIn("steps.web-sandbox.outcome == 'success'", step['if'])

    def test_snap_desktop_types_and_session_dependencies_precede_install(self):
        steps = self.native['jobs']['snap']['steps']
        desktop = next(s for s in steps if s.get('id') == 'strict-desktop')
        commands = [shlex.split(line) for line in
                    desktop['run'].replace('\\\n', '').splitlines()]
        installed = {arg for command in commands
                     if command[:3] == ['sudo', 'apt-get', 'install']
                     for arg in command[3:]}
        self.assertTrue({'xvfb', 'python3-gi', 'gir1.2-gtk-3.0',
                         'dbus-user-session'}.issubset(installed))
        self.assertIn("steps.snap-artifact.outcome == 'success'", desktop['if'])
        install = next(s for s in steps if s.get('id') == 'strict-install')
        self.assertLess(steps.index(desktop), steps.index(install))
        for prerequisite in ['snap-artifact', 'strict-desktop']:
            self.assertIn(f"steps.{prerequisite}.outcome == 'success'", install['if'])

    def test_snap_artifact_selection_requires_inspection_and_a_successful_build(self):
        steps = self.native['jobs']['snap']['steps']
        selection = next(s for s in steps if s.get('id') == 'snap-artifact')
        inspection = next(s for s in steps if s.get('id') == 'snap-inspection')
        self.assertLess(steps.index(inspection), steps.index(selection))
        self.assertIn('apt-get install -y squashfs-tools', inspection['run'])
        self.assertIn("steps.snap-inspection.outcome == 'success'", selection['if'])
        self.assertIn("steps.snapcraft.outcome == 'success'", selection['if'])
        self.assertIn("steps.snapcraft-retry.outcome == 'success'", selection['if'])
        for scenario in ['primary', 'retry', 'stale', 'foreign', 'wrong-recipe', 'missing', 'failed']:
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                workspace, run_temp = root / 'workspace', root / 'runner'
                workspace.mkdir()
                run_temp.mkdir()
                (workspace / 'snap').mkdir()
                recipe = workspace / 'snap/snapcraft.yaml'
                recipe.write_text('name: owned-control\nconfinement: strict\n')
                marker = run_temp / 'busymark-snap-build-start'
                marker.touch()
                os.utime(marker, (1, 1))
                artifact = (root if scenario == 'foreign' else workspace) / 'candidate.snap'
                artifact.write_bytes(b'controlled artifact')
                if scenario == 'stale':
                    os.utime(artifact, (0, 0))
                if scenario == 'missing':
                    artifact.unlink()
                bin_dir = root / 'bin'
                bin_dir.mkdir()
                unsquashfs = bin_dir / 'unsquashfs'
                unsquashfs.write_text('#!/bin/sh\ncat "$CONTROL_RECIPE"\n')
                unsquashfs.chmod(0o700)
                wrong = root / 'wrong.yaml'
                wrong.write_text('name: different-control\n')
                env = {**os.environ, 'PATH': str(bin_dir) + ':' + os.environ['PATH'],
                       'GITHUB_WORKSPACE': str(workspace), 'RUNNER_TEMP': str(run_temp),
                       'GITHUB_OUTPUT': str(root / 'output'), 'PRIMARY_SNAP': str(artifact),
                       'PRIMARY_OUTCOME': 'failure' if scenario in ['retry', 'failed'] else 'success',
                       'RETRY_SNAP': str(artifact), 'RETRY_OUTCOME': 'success' if scenario == 'retry' else 'failure',
                       'CONTROL_RECIPE': str(wrong if scenario == 'wrong-recipe' else recipe)}
                result = subprocess.run(['bash', '-euc', selection['run']], cwd=workspace,
                                        env=env, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode == 0, scenario in ['primary', 'retry'],
                                 result.stdout + result.stderr)
                output = root / 'output'
                if result.returncode == 0:
                    self.assertEqual(output.read_text(), f'snap={artifact.resolve()}\n')
                else:
                    self.assertFalse(output.exists())

    def test_parallel_snap_setup_is_shared_and_required_by_every_named_install(self):
        steps = self.native['jobs']['snap']['steps']
        setup = [step for step in steps
                 if step.get('run', '').strip() ==
                 'sudo snap set system experimental.parallel-instances=true']
        self.assertEqual(len(setup), 1, 'Parallel-instance setup must be a shared step')
        setup = setup[0]
        self.assertNotIn('continue-on-error', setup)
        prerequisite = f"steps.{setup['id']}.outcome == 'success'"
        installs = [step for step in steps
                    if re.search(r'\bsnap install\b[^\n]*--name=', step.get('run', ''))]
        self.assertEqual(len(installs), 2)
        for install in installs:
            with self.subTest(install=install['name']):
                self.assertLess(steps.index(setup), steps.index(install))
                self.assertIn(prerequisite, install.get('if', ''))
                self.assertIn('!cancelled()', install['if'])

    def test_snap_launches_keep_the_systemd_user_session_bus(self):
        steps = self.native['jobs']['snap']['steps']
        sessions = [step for step in steps if step.get('id') == 'strict-session']
        self.assertEqual(len(sessions), 1)
        session = sessions[0]
        dependencies = next(step for step in steps
                            if 'apt-get install' in step.get('run', '') and 'dbus-user-session' in step['run'])
        packages = [shlex.split(line) for line in dependencies['run'].splitlines()]
        self.assertTrue(any(command[:3] == ['sudo', 'apt-get', 'install'] and
                            'dbus-user-session' in command[3:] for command in packages))
        self.assertLess(steps.index(dependencies), steps.index(session))
        self.assertIn('sudo systemctl start "user@${session_uid}.service"', session['run'])
        self.assertIn('test -S "$runtime_dir/bus"', session['run'])
        self.assertIn('DBUS_SESSION_BUS_ADDRESS=unix:path=$runtime_dir/bus', session['run'])
        self.assertIn('XDG_RUNTIME_DIR=$runtime_dir', session['run'])
        self.assertIn('"$GITHUB_ENV"', session['run'])
        self.assertNotIn('continue-on-error', session)
        launches = [step for step in steps if 'snap run' in step.get('run', '') or
                    'tools/application_close_smoke.py' in step.get('run', '')]
        self.assertTrue(launches)
        for launch in launches:
            with self.subTest(launch=launch['name']):
                self.assertLess(steps.index(session), steps.index(launch))
                self.assertIn("steps.strict-session.outcome == 'success'", launch['if'])
                self.assertNotIn('dbus-run-session', launch['run'])

    def test_shell_steps_parse(self):
        for workflow in [self.workflow, self.native]:
            for job in workflow['jobs'].values():
                for step in job.get('steps', []):
                    if 'run' in step:
                        script = re.sub(r'\$\{\{.*?\}\}', 'owned-placeholder', step['run'])
                        subprocess.run(['bash', '-n'], input=script, text=True, check=True)


class BundleInstallTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        self.build = self.root / 'build'
        self.bundle = self.build / 'bundle'
        (self.source / 'payload').write_text('installed')
        # Exercise the maintained module without needing Flutter or plugins.
        (self.source / 'CMakeLists.txt').write_text(f'''
cmake_minimum_required(VERSION 3.13)
project(bundle_control NONE)
include("{ROOT / 'linux/cmake/BundleInstall.cmake'}")
if(FAIL_AFTER_DEFAULT)
  message(FATAL_ERROR "Controlled dependency failure")
endif()
busymark_clean_default_bundle()
install(FILES payload DESTINATION "${{CMAKE_INSTALL_PREFIX}}/data" COMPONENT Runtime)
''')
        self.env = dict(os.environ)
        self.env.pop('CMAKE_INSTALL_PREFIX', None)

    def cmake(self, *args, success=True, environment=None):
        result = subprocess.run(['cmake', *map(str, args)], env=environment or self.env,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)

    def sentinel(self, directory):
        directory.mkdir(parents=True, exist_ok=True)
        target = directory / 'preserve'
        target.write_text('unrelated')
        return target

    def test_default_bundle_cleanup_preserves_siblings(self):
        self.cmake('-S', self.source, '-B', self.build)
        stale = self.sentinel(self.bundle)
        sibling = self.sentinel(self.build / 'unrelated')
        self.cmake('--install', self.build)
        self.assertFalse(stale.exists())
        self.assertEqual(sibling.read_text(), 'unrelated')
        self.assertEqual((self.bundle / 'data/payload').read_text(), 'installed')

    def test_explicit_prefix_does_not_clean_either_destination(self):
        custom = self.root / 'custom-stage'
        self.cmake('-S', self.source, '-B', self.build, f'-DCMAKE_INSTALL_PREFIX={custom}')
        original = self.sentinel(self.bundle)
        existing = self.sentinel(custom)
        self.cmake('--install', self.build)
        self.assertEqual(original.read_text(), 'unrelated')
        self.assertEqual(existing.read_text(), 'unrelated')
        self.assertEqual((custom / 'data/payload').read_text(), 'installed')

    def test_destdir_does_not_clean_the_real_bundle_or_staged_files(self):
        self.cmake('-S', self.source, '-B', self.build)
        destdir = self.root / 'destdir'
        staged = destdir / self.bundle.relative_to(self.bundle.anchor)
        original = self.sentinel(self.bundle)
        existing = self.sentinel(staged)
        self.cmake('--install', self.build, environment={**self.env, 'DESTDIR': str(destdir)})
        self.assertEqual(original.read_text(), 'unrelated')
        self.assertEqual(existing.read_text(), 'unrelated')
        self.assertEqual((staged / 'data/payload').read_text(), 'installed')

    def test_failed_first_configure_retains_the_safe_default(self):
        self.cmake('-S', self.source, '-B', self.build, '-DFAIL_AFTER_DEFAULT=ON', success=False)
        self.assertIn(f'CMAKE_INSTALL_PREFIX:PATH={self.bundle}',
                      (self.build / 'CMakeCache.txt').read_text())
        self.cmake('-S', self.source, '-B', self.build, '-DFAIL_AFTER_DEFAULT=OFF')
        self.cmake('--install', self.build)
        self.assertEqual((self.bundle / 'data/payload').read_text(), 'installed')


if __name__ == '__main__':
    unittest.main()

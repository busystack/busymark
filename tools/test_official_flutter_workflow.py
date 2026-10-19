"""Build-policy and CI topology controls, separate from GTK acceptance.

Uses PyYAML (a CI test prerequisite). Comments/documentation are not policy.
The Snap recipe pins the official archive; CI must select that same version.
"""
import hashlib
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
        cls.recipe = yaml.safe_load((ROOT / 'snap/snapcraft.yaml').read_text())

    def step(self, job, name):
        return next(s for s in self.workflow['jobs'][job]['steps'] if s.get('name') == name)

    def test_ci_and_snap_select_the_same_official_archive(self):
        sdk = self.recipe['parts']['flutter-sdk']
        url = urlparse(sdk['source'])
        self.assertEqual((url.scheme, url.netloc), ('https', 'storage.googleapis.com'))
        match = re.fullmatch(r'/flutter_infra_release/releases/stable/linux/flutter_linux_(\d+\.\d+\.\d+)-stable.tar.xz', url.path)
        self.assertIsNotNone(match)
        self.assertRegex(sdk['source-checksum'], r'^sha256/[a-f0-9]{64}$')
        selections = [s['with'] for job in self.workflow['jobs'].values()
                      for s in job['steps'] if s.get('uses', '').startswith('subosito/flutter-action@')]
        self.assertTrue(selections)
        for selection in selections:
            self.assertEqual(selection['flutter-version'], match[1])
            self.assertEqual(selection['channel'], 'stable')
        self.assertEqual(self.workflow['jobs']['development-modes']['strategy']['matrix']['mode'], ['debug', 'profile'])
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
        script = self.step('verify', 'Install Linux build dependencies')['run']
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

    def test_required_native_failures_do_not_suppress_independent_checks(self):
        checks = {
            'verify': {
                'Test including bundled D2 and Typst paths': 'release-build',
                'Exercise demand-driven native visualization lifecycle': 'release-build',
                'Run real WebKit, PlantUML, Mermaid, OpenAPI, and D2 smoke tests': 'release-build',
                'Exercise the release binary visualization and PDF paths under X11': 'release-build',
                'Build compiled-close fixture': 'release-build',
                'Require usable content while portal replies are withheld': 'release-fixture',
                'Exercise live application close, persistence, media and reopening': 'release-fixture',
                'Restore main target for Wayland checks': 'release-build',
                'Run spelling and visualization smoke tests under Wayland': 'release-main',
            },
            'snap': {
                'Verify GTK SVG icon loader and portable icon caches': 'strict-install',
                'Verify shared runtimes, packaged tools, media, and resources': 'strict-install',
                'Prepare a separate compiled-close fixture package': 'strict-install',
                'Build genuine strict compiled-close fixture': 'strict-fixture-source',
                'Verify strict Save Discard Cancel media rendering and reopening': 'strict-fixture-install',
                'Require usable confined content while portal replies are withheld': 'strict-fixture-install',
            },
            'development-modes': {
                'Build development-mode compiled-close fixture': 'mode-build',
                'Require development-mode portal responsiveness': 'mode-fixture',
                'Verify development-mode documents media and reopening': 'mode-fixture',
            },
        }
        for job, steps in checks.items():
            ids = {s.get('id') for s in self.workflow['jobs'][job]['steps']}
            for name, prerequisite in steps.items():
                with self.subTest(job=job, check=name):
                    step = self.step(job, name)
                    self.assertEqual(step.get('if'), "${{ !cancelled() && steps." + prerequisite + ".outcome == 'success' }}")
                    self.assertIn(prerequisite, ids)
                    self.assertNotIn('continue-on-error', step)
        for job, name, cycles in [('verify', 'Require 100 natural closes of the shipping release', 100),
                                  ('snap', 'Require 100 natural closes under strict confinement', 100),
                                  ('development-modes', 'Verify development mode GTK engine and natural close', 10)]:
            step = self.step(job, name)
            self.assertNotIn('continue-on-error', step)
            self.assertRegex(step['run'], rf'--cycles {cycles}\b')
        for job, name in [('verify', 'Require usable content while portal replies are withheld'),
                          ('development-modes', 'Require development-mode portal responsiveness')]:
            self.assertNotIn('application_close_smoke.py', self.step(job, name)['run'])

    def test_shell_steps_parse(self):
        for job in self.workflow['jobs'].values():
            for step in job['steps']:
                if 'run' in step:
                    script = re.sub(r'\$\{\{.*?\}\}', 'owned-placeholder', step['run'])
                    subprocess.run(['bash', '-n'], input=script, text=True, check=True)

    def test_upstream_patch_composition_remains_review_material(self):
        root = ROOT / 'docs/upstream/flutter'
        lock = json.loads((root / 'engine.lock.json').read_text())
        for patch in lock['patches']:
            self.assertEqual(hashlib.sha256((root / patch['file']).read_bytes()).hexdigest(), patch['sha256'])
        self.assertFalse((ROOT / 'tools/flutter_engine/engine.py').exists())
        self.assertFalse((ROOT / 'linux/cmake/CorrectedFlutterEngine.cmake').exists())


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

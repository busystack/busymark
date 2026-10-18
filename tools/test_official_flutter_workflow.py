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

    def test_executable_build_arguments_do_not_select_a_local_engine(self):
        scripts = [part.get('override-build', '') for part in self.recipe['parts'].values()]
        scripts += [step.get('run', '') for job in self.workflow['jobs'].values() for step in job['steps']]
        for script in scripts:
            self.assertFalse(any(word.startswith('--local-engine') for word in shlex.split(script, comments=True)))
        build = shlex.split(self.recipe['parts']['busymark']['override-build'], comments=True)
        start = build.index('flutter', build.index('--enforce-lockfile'))
        self.assertEqual(build[start:start + 4], ['flutter', 'build', 'linux', '--release'])

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


if __name__ == '__main__':
    unittest.main()

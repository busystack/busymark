"""Production must build with the official SDK, without private engine inputs."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent.parent


class OfficialFlutterWorkflowTest(unittest.TestCase):
    def test_no_private_engine_selection_in_production_workflows(self):
        for name in ['README.md', '.github/workflows/flutter-linux.yml',
                     'snap/snapcraft.yaml', 'linux/CMakeLists.txt',
                     'tools/build_install_snap_local.sh']:
            source = (ROOT / name).read_text()
            for forbidden in ['tools/flutter_engine', 'BUSYMARK_ENGINE_CACHE',
                              '--local-engine', 'busymark-engine.json',
                              'CorrectedFlutterEngine', 'tools/flutter.py']:
                with self.subTest(file=name, forbidden=forbidden):
                    self.assertNotIn(forbidden, source)

    def test_snap_downloads_exact_official_archive_and_keeps_standard_modes(self):
        recipe = (ROOT / 'snap/snapcraft.yaml').read_text()
        self.assertIn('flutter_linux_3.47.5-stable.tar.xz', recipe)
        self.assertIn('2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb', recipe)
        self.assertNotIn('engine.py', recipe)
        self.assertIn('flutter build linux --release', recipe)
        workflow = (ROOT / '.github/workflows/flutter-linux.yml').read_text()
        self.assertIn("flutter-version: '3.47.5'", workflow)
        self.assertIn('mode: [debug, profile]', workflow)

    def test_upstream_patch_composition_remains_review_material(self):
        import hashlib, json
        root = ROOT / 'docs/upstream/flutter'
        lock = json.loads((root / 'engine.lock.json').read_text())
        for patch in lock['patches']:
            self.assertEqual(hashlib.sha256((root / patch['file']).read_bytes()).hexdigest(), patch['sha256'])
        self.assertFalse((ROOT / 'tools/flutter_engine/engine.py').exists())
        self.assertFalse((ROOT / 'linux/cmake/CorrectedFlutterEngine.cmake').exists())


if __name__ == '__main__':
    unittest.main()

"""Fail-closed selection checks. Native lifetime correctness has separate tests."""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).parent / "flutter_engine/engine.py"
spec = importlib.util.spec_from_file_location("busymark_engine", SOURCE)
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)


class FlutterWrapperSelectionTest(unittest.TestCase):
    def test_attach_cannot_certify_an_unverified_running_engine(self):
        source = Path(__file__).parent / 'flutter.py'
        spec = importlib.util.spec_from_file_location('busymark_flutter_wrapper', source)
        wrapper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(wrapper)
        with patch.object(sys, 'argv', ['flutter.py', 'attach', '-d', 'linux']), \
             patch.object(wrapper.engine, 'cache_root', return_value=Path('/unused')), \
             patch.object(wrapper.engine, 'framework', return_value=Path('/unused/sdk')), \
             patch.object(wrapper.engine, 'verify'), \
             patch.object(wrapper.subprocess, 'call', return_value=0) as launch:
            with self.assertRaisesRegex(RuntimeError, 'cannot verify the loaded GTK engine'):
                wrapper.main()
            launch.assert_not_called()

    def test_prebuilt_application_cannot_bypass_corrected_engine_assembly(self):
        source = Path(__file__).parent / 'flutter.py'
        spec = importlib.util.spec_from_file_location('busymark_flutter_wrapper', source)
        wrapper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(wrapper)
        for option in [['--use-application-binary=/old/application'], ['--use-application-binary', '/old/application']]:
            with self.subTest(option=option), patch.object(sys, 'argv', ['flutter.py', 'run', *option]):
                with self.assertRaisesRegex(RuntimeError, 'bypasses corrected-engine assembly'):
                    wrapper.main()


class EngineSelectionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bm-engine-unit-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.out = self.root / "artifacts/engine/src/out/host_release"
        self.out.mkdir(parents=True)
        files = {
            "libflutter_linux_gtk.so": Path("/bin/true").read_bytes(),
            "icudtl.dat": b"test-icu", "flutter_linux/flutter_linux.h": b"test-header",
            "dart-sdk/version": engine.LOCK["dartVersion"].encode(),
            "dart-sdk/revision": engine.LOCK["dartRevision"].encode(),
            "dart-sdk/bin/dart": b"test-sdk", "gen_snapshot": b"test-snapshot",
            "dart-sdk/bin/dartaotruntime": b"test-runtime",
            "dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot": b"test-frontend",
            "gen/dart-pkg/sky_engine/pubspec.yaml": b"test-sky",
            "gen/const_finder.dart.snapshot": b"test-finder", "font-subset": b"test-font-subset",
            "native-test-fixtures/ubuntu-20.04/gschemas.compiled": b"test-schemas",
            "flutter_patched_sdk/platform_strong.dill": b"test-platform",
            "flutter_linux_unittests": b"test-native\0native-test-fixtures\0", "renderer-retirement": b"test-component",
            "args.gn": ('flutter_runtime_mode = "release"\ntarget_cpu = "x64"\ntarget_os = "linux"\nengine_version = "' + engine.LOCK["engineRevision"] + '"\nenable_lto = false\nis_debug = false\n').encode(),
        }
        for name, data in files.items():
            p = self.out / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(data)
        self.receipt = {"key": engine.key(), "mode": "release", "architecture": engine.LOCK["architecture"], "frameworkRevision": engine.LOCK["frameworkRevision"], "engineRevision": engine.LOCK["engineRevision"], "clang": engine.LOCK["clangRevision"], "sources": json.loads((engine.HERE / "reviewed-sources.json").read_text()), "componentSourceSHA256": engine.digest(engine.HERE / "tests/renderer-retirement-test.cc"), "elf": engine.elf_identity(self.out / "libflutter_linux_gtk.so"), "files": {n: hashlib.sha256(d).hexdigest() for n, d in files.items()}}
        self.write_receipt()
        symbols = self.root / 'symbols/release/libflutter_linux_gtk.so.debug'
        symbols.parent.mkdir(parents=True)
        shutil.copy2(self.out / 'libflutter_linux_gtk.so', symbols)
        self.receipt.update(schema=2, symbolsSHA256=engine.digest(symbols))
        self.write_receipt()

    def write_receipt(self):
        (self.out / "busymark-engine.json").write_text(json.dumps(self.receipt))

    def test_complete_selected_inputs_verify(self):
        self.assertEqual(engine.verify(self.root, "release")[0], self.out)

    def test_missing_mode_has_actionable_failure(self):
        with self.assertRaisesRegex(RuntimeError, "build --mode profile"):
            engine.verify(self.root, "profile")

    def test_wrong_or_missing_artifact_compiler_is_rejected(self):
        for compiler in ['', None, 'clang from another revision']:
            self.receipt['clang'] = compiler
            self.write_receipt()
            with self.subTest(compiler=compiler), self.assertRaisesRegex(RuntimeError, 'DEPS-pinned Clang'):
                engine.verify(self.root, 'release')

    def test_missing_symbols_are_an_incomplete_cache(self):
        (self.root / 'symbols/release/libflutter_linux_gtk.so.debug').unlink()
        with self.assertRaisesRegex(RuntimeError, 'symbols missing or mismatched'):
            engine.verify(self.root, 'release')

    def test_symbols_from_another_engine_are_rejected(self):
        symbols = self.root / 'symbols/release/libflutter_linux_gtk.so.debug'
        shutil.copy2('/bin/sleep', symbols)
        self.receipt['symbolsSHA256'] = engine.digest(symbols)
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, 'symbol build ID'):
            engine.verify(self.root, 'release')

    def test_corrupt_icu_is_rejected(self):
        (self.out / "icudtl.dat").write_bytes(b"different")
        with self.assertRaisesRegex(RuntimeError, "missing or mismatched"):
            engine.verify(self.root, "release")

    def test_incomplete_manifest_cannot_hide_missing_snapshot(self):
        del self.receipt["files"]["gen_snapshot"]
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, "snapshot compiler"):
            engine.verify(self.root, "release")

    def test_missing_native_test_schemas_are_rejected(self):
        del self.receipt['files']['native-test-fixtures/ubuntu-20.04/gschemas.compiled']
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, 'Incomplete artifact receipt'):
            engine.verify(self.root, 'release')

    def test_native_fixture_locator_rejects_stale_generated_source(self):
        built = self.root / 'build'
        generated = built / 'gen/flutter/shell/platform/linux/_fl__fl_flutter_linux_fixtures.cc'
        generated.parent.mkdir(parents=True)
        generated.write_text('const char* GetFixturesPath() {return "/another-checkout/assets";} \n')
        with self.assertRaisesRegex(RuntimeError, 'fixture locator'):
            engine.configure_native_test_fixtures(built)

    def test_absolute_native_test_locator_cannot_pass_as_a_portable_cache(self):
        p = self.out / 'flutter_linux_unittests'
        p.write_bytes(b'native-test-fixtures\0/old/gen/flutter/shell/platform/linux/assets\0')
        self.receipt['files']['flutter_linux_unittests'] = engine.digest(p)
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, 'fixture locator is not portable'):
            engine.verify(self.root, 'release')

    def test_claimed_release_with_profile_gn_is_rejected(self):
        p = self.out / "args.gn"
        p.write_text(p.read_text().replace('"release"', '"profile"'))
        self.receipt["files"]["args.gn"] = engine.digest(p)
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, "GN configuration"):
            engine.verify(self.root, "release")

    def test_changed_source_composition_is_rejected(self):
        self.receipt["sources"].pop(next(iter(self.receipt["sources"])))
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, "reviewed C6"):
            engine.verify(self.root, "release")

    def test_unsafe_manifest_path_is_rejected(self):
        self.receipt["files"]["../escape"] = "0" * 64
        self.write_receipt()
        with self.assertRaisesRegex(RuntimeError, "Unsafe"):
            engine.verify(self.root, "release")

    def test_official_cmake_selection_fails_before_sdk_use(self):
        p = subprocess.run([sys.executable, str(SOURCE), "check-cmake", "--mode", "Release", "--framework", str(self.root)], capture_output=True, text=True)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("python3 tools/flutter.py build linux --release", p.stderr)

    def test_rejected_clean_configure_does_not_poison_install_prefix(self):
        project, build = self.root / 'project', self.root / 'cmake-build'
        linux = project / 'linux'
        (linux / 'flutter/ephemeral').mkdir(parents=True)
        (linux / 'cmake').mkdir()
        shutil.copy2(engine.PROJECT / 'linux/CMakeLists.txt', linux / 'CMakeLists.txt')
        shutil.copy2(engine.PROJECT / 'linux/cmake/CorrectedFlutterEngine.cmake', linux / 'cmake')
        # Minimal generated Flutter subdirectory: the real production guard
        # must reject this official-engine selection before SDK/library use.
        (linux / 'flutter/CMakeLists.txt').write_text('')
        (linux / 'flutter/ephemeral/generated_config.cmake').write_text('')
        tools = project / 'tools/flutter_engine'
        tools.mkdir(parents=True)
        for name in ['engine.py', 'engine.lock.json']:
            shutil.copy2(engine.HERE / name, tools / name)
        for _ in range(2):
            result = subprocess.run(['cmake', '-S', str(linux), '-B', str(build),
                                     '-DCMAKE_BUILD_TYPE=Release',
                                     '-DPython3_EXECUTABLE=' + sys.executable], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('requires its corrected Linux engine', result.stderr)
            self.assertIn('CMAKE_INSTALL_PREFIX:PATH=' + str(build / 'bundle'),
                          (build / 'CMakeCache.txt').read_text())
        # A cache left by an older failed configure must fail before install,
        # rather than depending on the caller lacking system write permission.
        result = subprocess.run(['cmake', '-S', str(linux), '-B', str(build),
                                 '-DCMAKE_INSTALL_PREFIX=/usr/local'], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Refusing an install prefix outside the Flutter bundle', result.stderr)

    def test_missing_cache_never_invokes_path_flutter(self):
        marker = self.root / "unexpected-official"
        fake = self.root / "flutter"
        fake.write_text('#!/bin/sh\ntouch "' + str(marker) + '"\n')
        fake.chmod(0o755)
        env = os.environ.copy()
        env.update(BUSYMARK_ENGINE_CACHE=str(self.root / "empty"), PATH=str(self.root) + os.pathsep + env["PATH"])
        p = subprocess.run([sys.executable, str(SOURCE.parent.parent / "flutter.py"), "build", "linux"], env=env, capture_output=True, text=True)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("Private framework missing", p.stderr)
        self.assertFalse(marker.exists())

    def test_packaging_rejects_changed_code_even_with_valid_input_cache(self):
        bundle = self.root / "bundle"
        (bundle / "lib").mkdir(parents=True)
        (bundle / "data").mkdir()
        shutil.copy2("/bin/sleep", bundle / "lib/libflutter_linux_gtk.so")
        shutil.copy2(self.out / "icudtl.dat", bundle / "data/icudtl.dat")
        with self.assertRaisesRegex(RuntimeError, "Packaged engine code"):
            engine.check_bundle(self.root, "release", bundle, packaged=True)

    def test_snap_pull_excludes_private_engines_and_copied_build_state(self):
        recipe = (engine.PROJECT / 'snap/snapcraft.yaml').read_text()
        part = recipe.split('\n  busymark:\n', 1)[1]
        script = part.split('    override-pull: |\n', 1)[1].split('\n    build-snaps:', 1)[0]
        script = '\n'.join(line[6:] for line in script.splitlines())
        source, dest = self.root / 'project', self.root / 'parts/busymark/src'
        dest.mkdir(parents=True)
        for name in ['lib/main.dart', 'tools/flutter_engine/engine.lock.json',
                     '.build/flutter-engine/source/private', '.build/engine-release.tar.xz',
                     '.dart_tool/package_config.json', 'build/linux/bundle/stale',
                     'linux/flutter/ephemeral/stale', 'parts/nested/stale',
                     '.git/config', 'artifact.snap']:
            path = source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture')
        env = os.environ.copy()
        env.update(CRAFT_PROJECT_DIR=str(source), CRAFT_PART_SRC=str(dest))
        subprocess.run(['sh', '-ec', script], env=env, check=True)
        actual = {str(p.relative_to(dest)) for p in dest.rglob('*') if p.is_file()}
        self.assertEqual(actual, {'lib/main.dart', 'tools/flutter_engine/engine.lock.json'})
        self.assertTrue((source / '.build/engine-release.tar.xz').exists())

    def snap_resource_script(self):
        part = (engine.PROJECT / 'snap/snapcraft.yaml').read_text().split('\n  busymark:\n', 1)[1].split('\n  desktop-integration:', 1)[0]
        script = part[part.index('      # CMake installs the deterministic Typst font set'):]
        return '\n'.join(line[6:] for line in script.splitlines())

    def resource_fixture(self, root, different=False):
        for name, data in {
            'share/busymark/fonts/NotoSans-Regular.ttf': b'font',
            'usr/share/fonts/truetype/noto/NotoSans-Regular.ttf': b'different' if different else b'font',
            'usr/share/themes/Yaru/gtk.css': b'theme',
            'usr/share/icons/Yaru/icon.svg': b'icon',
        }.items():
            p = root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(data)

    def test_resource_aliases_are_owned_install_outputs_before_staging(self):
        install, prime = self.root / 'install', self.root / 'prime'
        prime.mkdir()
        self.resource_fixture(install)
        env = os.environ.copy()
        env.update(CRAFT_PART_INSTALL=str(install), CRAFT_PRIME=str(prime))
        subprocess.run(['sh', '-eu', '-c', self.snap_resource_script()], env=env, check=True)
        for link, leaf, data in [('share/busymark/fonts', 'NotoSans-Regular.ttf', b'font'),
                                 ('share/themes/Yaru', 'gtk.css', b'theme'),
                                 ('share/icons/Yaru', 'icon.svg', b'icon')]:
            self.assertTrue((install / link).is_symlink())
            self.assertFalse(os.readlink(install / link).startswith('/'))
            self.assertEqual((install / link / leaf).read_bytes(), data)
        self.assertEqual(list(prime.iterdir()), [])

    def test_resource_normalization_rejects_different_font_bytes(self):
        install = self.root / 'install'
        self.resource_fixture(install, different=True)
        env = os.environ.copy()
        env['CRAFT_PART_INSTALL'] = str(install)
        result = subprocess.run(['sh', '-eu', '-c', self.snap_resource_script()], env=env)
        self.assertNotEqual(result.returncode, 0)
        fonts = install / 'share/busymark/fonts'
        self.assertFalse(fonts.is_symlink())
        self.assertEqual((fonts / 'NotoSans-Regular.ttf').read_bytes(), b'font')


if __name__ == "__main__":
    unittest.main()

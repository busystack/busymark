import hashlib
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest

PATCH_ROOT = Path(__file__).parent / "native_patches/yaru_window_linux"
SPEC = importlib.util.spec_from_file_location("yaru_prepare", PATCH_ROOT / "prepare.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PrepareTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.source.mkdir()
        self.output = self.root / "generated"
        self.here = self.root / "patch"
        self.here.mkdir()
        (self.source / "example.cc").write_text("before\n")
        patch = "--- a/example.cc\n+++ b/example.cc\n@@ -1 +1 @@\n-before\n+after\n"
        (self.here / "retired-window.patch").write_text(patch)
        (self.here / "README.md").write_text("changes\n")
        lock = {"upstream": {"example.cc": hashlib.sha256(b"before\n").hexdigest()},
                "patchSha256": hashlib.sha256(patch.encode()).hexdigest()}
        (self.here / "source.lock.json").write_text(json.dumps(lock))
        self.old_file = MODULE.__file__
        MODULE.__file__ = str(self.here / "prepare.py")
        self.addCleanup(setattr, MODULE, "__file__", self.old_file)

    def test_repeated_prepare_never_changes_dependency_source(self):
        for _ in range(2):
            MODULE.prepare(self.source, self.output, build_root=self.root)
            self.assertEqual((self.output / "example.cc").read_text(), "after\n")
            self.assertEqual((self.source / "example.cc").read_text(), "before\n")

    def test_modified_input_fails_without_fallback(self):
        (self.source / "example.cc").write_text("unexpected\n")
        with self.assertRaisesRegex(RuntimeError, "Unexpected Yaru source"):
            MODULE.prepare(self.source, self.output, build_root=self.root)
        self.assertFalse(self.output.exists())

    def test_modified_patch_fails(self):
        (self.here / "retired-window.patch").write_text("changed\n")
        with self.assertRaisesRegex(RuntimeError, "does not match"):
            MODULE.prepare(self.source, self.output, build_root=self.root)

    def test_output_cannot_replace_cache(self):
        with self.assertRaisesRegex(RuntimeError, "outside"):
            MODULE.prepare(self.source, self.source / "generated", build_root=self.root)

    def test_redirected_output_is_rejected(self):
        self.output.mkdir()
        (self.output / "example.cc").symlink_to(self.source / "example.cc")
        with self.assertRaisesRegex(RuntimeError, "redirected"):
            MODULE.prepare(self.source, self.output, build_root=self.root)
        self.assertEqual((self.source / "example.cc").read_text(), "before\n")

    def metadata_redirect(self, name, hardlink):
        self.output.mkdir()
        (self.output / "example.cc").write_text("old generated output\n")
        target = self.output / name
        if hardlink:
            os.link(self.source / "example.cc", target)
        else:
            target.symlink_to(self.source / "example.cc")
        with self.assertRaisesRegex(RuntimeError, "redirected"):
            MODULE.prepare(self.source, self.output, build_root=self.root)
        self.assertEqual((self.source / "example.cc").read_text(), "before\n")
        self.assertEqual((self.output / "example.cc").read_text(), "old generated output\n")
        other = "BUSYMARK-CHANGES.md" if name == "retired-window.patch" else "retired-window.patch"
        self.assertFalse((self.output / other).exists())

    def test_notice_symlink_is_rejected_before_any_output_changes(self):
        self.metadata_redirect("BUSYMARK-CHANGES.md", False)

    def test_notice_hardlink_is_rejected_before_any_output_changes(self):
        self.metadata_redirect("BUSYMARK-CHANGES.md", True)

    def test_patch_symlink_is_rejected_before_any_output_changes(self):
        self.metadata_redirect("retired-window.patch", False)

    def test_patch_hardlink_is_rejected_before_any_output_changes(self):
        self.metadata_redirect("retired-window.patch", True)

    def test_redirected_ancestor_is_rejected_before_any_mutation(self):
        lock = json.loads((self.here / "source.lock.json").read_text())
        (self.source / "nested").mkdir()
        (self.source / "nested/other.cc").write_text("protected\n")
        lock["upstream"]["nested/other.cc"] = hashlib.sha256(b"protected\n").hexdigest()
        (self.here / "source.lock.json").write_text(json.dumps(lock))
        self.output.mkdir()
        (self.output / "example.cc").write_text("old\n")
        (self.output / "nested").symlink_to(self.source / "nested", target_is_directory=True)
        with self.assertRaisesRegex(RuntimeError, "redirected"):
            MODULE.prepare(self.source, self.output, build_root=self.root)
        self.assertEqual((self.output / "example.cc").read_text(), "old\n")
        self.assertEqual((self.source / "nested/other.cc").read_text(), "protected\n")

    def test_redirected_output_root_is_rejected(self):
        elsewhere = self.root / "elsewhere"
        elsewhere.mkdir()
        self.output.symlink_to(elsewhere, target_is_directory=True)
        with self.assertRaisesRegex(RuntimeError, "redirected"):
            MODULE.prepare(self.source, self.output, build_root=self.root)
        self.assertEqual(list(elsewhere.iterdir()), [])

    def test_output_outside_selected_build_root_is_rejected(self):
        build = self.root / "build"
        build.mkdir()
        with self.assertRaisesRegex(RuntimeError, "below build root"):
            MODULE.prepare(self.source, self.output, build_root=build)
        self.assertFalse(self.output.exists())

    def test_output_cannot_replace_selected_build_root(self):
        with self.assertRaisesRegex(RuntimeError, "replace the build root"):
            MODULE.prepare(self.source, self.root, build_root=self.root)
        self.assertEqual((self.source / "example.cc").read_text(), "before\n")

    def test_redirected_parent_is_rejected_before_any_output_changes(self):
        protected = self.root / "protected"
        protected.mkdir()
        sentinel = protected / "generated/example.cc"
        sentinel.parent.mkdir()
        sentinel.write_text("protected\n")
        parent = self.root / "redirected"
        parent.symlink_to(protected, target_is_directory=True)
        with self.assertRaisesRegex(RuntimeError, "redirected"):
            MODULE.prepare(self.source, parent / "generated", build_root=self.root)
        self.assertEqual(list(sentinel.parent.iterdir()), [sentinel])
        self.assertEqual(sentinel.read_text(), "protected\n")

    def test_explicit_symlinked_build_root_is_allowed(self):
        with tempfile.TemporaryDirectory() as external:
            selected = self.root / "selected-build"
            selected.symlink_to(external, target_is_directory=True)
            MODULE.prepare(self.source, selected / "generated", build_root=selected)
            self.assertEqual((Path(external) / "generated/example.cc").read_text(), "after\n")
            self.assertEqual((self.source / "example.cc").read_text(), "before\n")

    def test_non_directory_ancestor_is_rejected_before_any_output_changes(self):
        lock = json.loads((self.here / "source.lock.json").read_text())
        (self.source / "nested").mkdir()
        (self.source / "nested/other.cc").write_text("protected\n")
        lock["upstream"]["nested/other.cc"] = hashlib.sha256(b"protected\n").hexdigest()
        (self.here / "source.lock.json").write_text(json.dumps(lock))
        self.output.mkdir()
        (self.output / "example.cc").write_text("old\n")
        (self.output / "nested").write_text("unrelated\n")
        with self.assertRaisesRegex(RuntimeError, "non-directory"):
            MODULE.prepare(self.source, self.output, build_root=self.root)
        self.assertEqual((self.output / "example.cc").read_text(), "old\n")
        self.assertEqual((self.output / "nested").read_text(), "unrelated\n")

    def test_command_line_does_not_resolve_away_redirected_output_root(self):
        elsewhere = self.root / "elsewhere"
        elsewhere.mkdir()
        self.output.symlink_to(elsewhere, target_is_directory=True)
        helper = self.here / "prepare.py"
        helper.write_bytes((PATCH_ROOT / "prepare.py").read_bytes())
        result = subprocess.run([sys.executable, str(helper),
                                 str(self.source), str(self.output), "--build-root", str(self.root)], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("redirected", result.stderr)
        self.assertEqual(list(elsewhere.iterdir()), [])

    def configure(self, build):
        # Exercise the production CMake caller and helper together, using only
        # owned minimal sources. The plugin need not compile to validate paths.
        project = self.root / "project"
        linux = project / "linux"
        linux.mkdir(parents=True)
        patch = project / "tools/native_patches/yaru_window_linux"
        patch.mkdir(parents=True)
        for name in ["source.lock.json", "retired-window.patch", "README.md"]:
            (patch / name).write_bytes((self.here / name).read_bytes())
        (patch / "prepare.py").write_bytes((PATCH_ROOT / "prepare.py").read_bytes())
        lock = json.loads((patch / "source.lock.json").read_text())
        for name in ["linux/yaru_window.cc", "linux/yaru_window_linux_plugin.cc"]:
            source = self.source / name
            source.parent.mkdir(exist_ok=True)
            source.write_text("// Owned configure-only fixture\n")
            lock["upstream"][name] = hashlib.sha256(source.read_bytes()).hexdigest()
        (patch / "source.lock.json").write_text(json.dumps(lock))
        plugins = linux / "flutter/ephemeral/.plugin_symlinks"
        plugins.mkdir(parents=True)
        (plugins / "yaru_window_linux").symlink_to(self.source, target_is_directory=True)
        module = (PATCH_ROOT.parents[2] / "linux/cmake/YaruWindowLifetime.cmake")
        (linux / "dummy.cc").write_text("int owned_fixture;\n")
        (linux / "CMakeLists.txt").write_text(
            'cmake_minimum_required(VERSION 3.13)\n'
            'project(OwnedYaruControl LANGUAGES CXX)\n'
            'add_library(yaru_window_linux_plugin STATIC dummy.cc)\n'
            'set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")\n'
            f'include("{module.resolve()}")\n')
        return subprocess.run(["cmake", "-S", str(linux), "-B", str(build)],
                              capture_output=True, text=True)

    def test_cmake_rejects_redirected_generated_parent_before_writing(self):
        build = self.root / "build"
        build.mkdir()
        protected = self.root / "protected"
        sentinel = protected / "yaru_window_linux/example.cc"
        sentinel.parent.mkdir(parents=True)
        sentinel.write_text("protected\n")
        unrelated = build / "unrelated-output"
        unrelated.write_text("unchanged\n")
        (build / "patched-plugins").symlink_to(protected, target_is_directory=True)
        result = self.configure(build)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("redirected", result.stderr)
        self.assertEqual(sentinel.read_text(), "protected\n")
        self.assertEqual(list(sentinel.parent.iterdir()), [sentinel])
        self.assertEqual(unrelated.read_text(), "unchanged\n")
        self.assertEqual((self.source / "example.cc").read_text(), "before\n")

    def test_cmake_accepts_explicit_external_build_directory(self):
        with tempfile.TemporaryDirectory() as external:
            build = Path(external) / "build"
            result = self.configure(build)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(
                (build / "patched-plugins/yaru_window_linux/example.cc").read_text(),
                "after\n")
            self.assertEqual((self.source / "example.cc").read_text(), "before\n")


if __name__ == "__main__":
    unittest.main()

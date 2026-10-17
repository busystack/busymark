import hashlib
import importlib.util
import json
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
            MODULE.prepare(self.source, self.output)
            self.assertEqual((self.output / "example.cc").read_text(), "after\n")
            self.assertEqual((self.source / "example.cc").read_text(), "before\n")

    def test_modified_input_fails_without_fallback(self):
        (self.source / "example.cc").write_text("unexpected\n")
        with self.assertRaisesRegex(RuntimeError, "Unexpected Yaru source"):
            MODULE.prepare(self.source, self.output)
        self.assertFalse(self.output.exists())

    def test_modified_patch_fails(self):
        (self.here / "retired-window.patch").write_text("changed\n")
        with self.assertRaisesRegex(RuntimeError, "does not match"):
            MODULE.prepare(self.source, self.output)

    def test_output_cannot_replace_cache(self):
        with self.assertRaisesRegex(RuntimeError, "outside"):
            MODULE.prepare(self.source, self.source / "generated")

    def test_redirected_output_is_rejected(self):
        self.output.mkdir()
        (self.output / "example.cc").symlink_to(self.source / "example.cc")
        with self.assertRaisesRegex(RuntimeError, "redirected"):
            MODULE.prepare(self.source, self.output)
        self.assertEqual((self.source / "example.cc").read_text(), "before\n")


if __name__ == "__main__":
    unittest.main()

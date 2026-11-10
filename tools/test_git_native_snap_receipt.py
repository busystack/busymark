import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from git_native_build_receipt import payloads
from git_native_snap_receipt import installed, require_bundle, tree


class SnapReceiptTest(unittest.TestCase):
    def test_tree_binds_modes_and_symlinks_without_reading_external_targets(self):
        with tempfile.TemporaryDirectory() as temporary:
            parent = Path(temporary)
            root = parent / 'root'
            root.mkdir()
            outside = parent / 'outside'
            outside.write_bytes(b'not package content')
            (root / 'link').symlink_to(outside)
            binary = root / 'busymark'
            binary.write_bytes(b'unit fixture')
            binary.chmod(0o755)
            before = tree(root)
            outside.write_bytes(b'external change must not be read')
            self.assertEqual(tree(root), before)
            binary.chmod(0o700)
            self.assertNotEqual(tree(root), before)
            binary.chmod(0o755)
            binary.write_bytes(b'changed package content')
            self.assertNotEqual(tree(root), before)

    def test_every_qualified_bundle_file_must_be_present_and_unchanged(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / 'busymark'
            binary.write_bytes(b'unit fixture')
            asset = root / 'data' / 'font.ttf'
            asset.parent.mkdir()
            asset.write_bytes(b'unit font')
            compiled = {'payloads': payloads(binary)}
            require_bundle(compiled, binary)
            asset.write_bytes(b'changed')
            with self.assertRaisesRegex(RuntimeError, 'qualified Flutter bundle'):
                require_bundle(compiled, binary)
            asset.unlink()
            with self.assertRaisesRegex(RuntimeError, 'qualified Flutter bundle'):
                require_bundle(compiled, binary)

    def test_installed_request_rejects_a_relocated_or_unmounted_bundle(self):
        with tempfile.TemporaryDirectory() as temporary:
            binary = Path(temporary) / 'busymark'
            binary.write_bytes(b'unit fixture')
            with self.assertRaisesRegex(RuntimeError, 'actual installed BusyMark Snap mount'):
                installed({}, binary)
        candidate = Path('/snap/busymark/999999999/busymark')
        self.assertFalse(os.path.ismount(candidate.parent))
        with self.assertRaisesRegex(RuntimeError, 'actual installed BusyMark Snap mount'):
            installed({}, candidate)


if __name__ == '__main__':
    unittest.main()

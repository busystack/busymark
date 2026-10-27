"""Publisher-byte checks must reject modified runtime packages."""
import importlib.util
import io
from pathlib import Path
import tarfile
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    'published_package', Path(__file__).parent / 'visualization/verify_published_package.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PublishedPackageTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.package = self.root / 'installed'
        self.package.mkdir()
        self.archive = self.root / 'published.tgz'
        files = {'package.json': b'{"name":"fixture","version":"11.16.1"}',
                 'dist/runtime.mjs': b'export const result = "official";'}
        with tarfile.open(self.archive, 'w:gz') as archive:
            for name, content in files.items():
                info = tarfile.TarInfo('package/' + name)
                info.size = len(content)
                archive.addfile(info, io.BytesIO(content))
                target = self.package / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(content)

    def test_exact_published_bytes_are_accepted(self):
        MODULE.verify(self.archive, self.package)

    def test_same_version_with_replaced_runtime_is_rejected(self):
        (self.package / 'dist/runtime.mjs').write_text('export const result = "stub";')
        with self.assertRaises(ValueError):
            MODULE.verify(self.archive, self.package)

    def test_missing_and_extra_files_are_rejected(self):
        runtime = self.package / 'dist/runtime.mjs'
        runtime.unlink()
        with self.assertRaises(ValueError):
            MODULE.verify(self.archive, self.package)
        runtime.write_text('export const result = "official";')
        (self.package / 'extra.mjs').write_text('export const replacement = true;')
        with self.assertRaises(ValueError):
            MODULE.verify(self.archive, self.package)

    def test_symlink_substitution_is_rejected(self):
        runtime = self.package / 'dist/runtime.mjs'
        target = self.root / 'substitute'
        target.write_bytes(runtime.read_bytes())
        runtime.unlink()
        runtime.symlink_to(target)
        with self.assertRaises(ValueError):
            MODULE.verify(self.archive, self.package)


if __name__ == '__main__':
    unittest.main()

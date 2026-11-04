import tempfile
from pathlib import Path
import unittest
from tools.git_native_build_receipt import payloads, sources, verify


class NativeBuildReceiptTest(unittest.TestCase):
    def test_seal_rejects_changed_compiled_source_or_binary(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ['busymark', 'busystack_git_flutter', 'busystack_git']:
                (root / name / 'lib').mkdir(parents=True)
                (root / name / 'lib/source.dart').write_text('original source')
            binary = root / 'bundle/busymark'
            binary.parent.mkdir()
            binary.write_bytes(b'owned test payload')
            receipt = {'sealed': True, 'sources': sources(root), 'payloads': payloads(binary)}
            verify(receipt, binary, root)
            source = root / 'busystack_git_flutter/lib/source.dart'
            source.write_text('changed presentation')
            with self.assertRaisesRegex(RuntimeError, 'source changed'):
                verify(receipt, binary, root)
            source.write_text('original source')
            binary.write_bytes(b'changed owned test payload')
            with self.assertRaisesRegex(RuntimeError, 'Binary payload differs'):
                verify(receipt, binary, root)
            receipt['sealed'] = False
            with self.assertRaisesRegex(RuntimeError, 'Binary payload differs'):
                verify(receipt, binary, root)


if __name__ == '__main__':
    unittest.main()

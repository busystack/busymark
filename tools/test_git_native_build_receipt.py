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
            extras = [binary.parent/'lib/libnative.so', binary.parent/'data/flutter_assets/font.ttf']
            for extra in extras:
                extra.parent.mkdir(parents=True, exist_ok=True)
                extra.write_bytes(b'original native or font payload')
            receipt = {'sealed': True, 'sources': sources(root), 'payloads': payloads(binary)}
            for extra in extras:
                extra.write_bytes(b'changed native or font payload')
                with self.assertRaisesRegex(RuntimeError, 'Binary payload differs'):
                    verify(receipt, binary, root)
                extra.write_bytes(b'original native or font payload')
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

    def test_workspace_inside_build_still_binds_all_production_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / 'build' / 'isolated-workspace'
            for name in ['busymark', 'busystack_git_flutter', 'busystack_git']:
                (root/name/'lib').mkdir(parents=True)
                (root/name/'lib/source.dart').write_text('original source')
                (root/name/'pubspec.yaml').write_text('name: '+name)
            binary = root/'bundle/busymark'
            binary.parent.mkdir()
            binary.write_bytes(b'owned test payload')
            receipt = {'sealed': True, 'sources': sources(root), 'payloads': payloads(binary)}
            for name in ['busymark', 'busystack_git_flutter', 'busystack_git']:
                source = root/name/'lib/source.dart'
                source.write_text('changed production source')
                with self.assertRaisesRegex(RuntimeError, 'source changed'):
                    verify(receipt, binary, root)
                source.write_text('original source')
            verify(receipt, binary, root)

    def test_manifest_only_workspace_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root/'busymark').mkdir()
            (root/'busymark/pubspec.yaml').write_text('name: busymark')
            with self.assertRaisesRegex(RuntimeError, 'No production source'):
                sources(root)

    def test_busyfiles_receipt_binds_ui_daemon_and_ipc_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for folder in ['busyfiles/apps/busyfiles_ui/lib', 'busyfiles/apps/busyfilesd/bin',
                           'busyfiles/packages/busyfiles_ipc/lib', 'busystack_git_flutter/lib', 'busystack_git/lib']:
                path = root / folder
                path.mkdir(parents=True)
                (path / 'source.dart').write_text('original production source')
            binary = root / 'bundle/busyfiles'
            binary.parent.mkdir()
            binary.write_bytes(b'owned test payload')
            receipt = {'host': 'busyfiles', 'sealed': True,
                       'sources': sources(root, host='busyfiles'), 'payloads': payloads(binary)}
            verify(receipt, binary, root)
            tests = root/'busyfiles/apps/busyfiles_ui/test'
            tests.mkdir()
            (tests/'fixture.dart').write_text('test-only change')
            verify(receipt, binary, root)
            for source in ['busyfiles/apps/busyfilesd/bin/source.dart', 'busyfiles/packages/busyfiles_ipc/lib/source.dart']:
                file = root/source
                file.write_text('changed production source')
                with self.assertRaisesRegex(RuntimeError, 'busyfiles source changed'):
                    verify(receipt, binary, root)
                file.write_text('original production source')


if __name__ == '__main__':
    unittest.main()

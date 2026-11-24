from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parent))
from snap_product_smoke import file_identity, verify_installation


class SnapInstallationIdentityTest(unittest.TestCase):
    def test_parallel_namespace_path_uses_instance_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            runner = root / 'runner'
            engine = root / 'engine'
            runner.write_bytes(b'app')
            engine.write_bytes(b'engine')
            ordinary_runner = shutil.copyfile(runner, root / 'other-runner')
            ordinary_engine = shutil.copyfile(engine, root / 'other-engine')
            record = {
                'executable': '/snap/busymark/x1/busymark',
                'executableIdentity': file_identity(runner.stat()),
                'loadedEngine': {**file_identity(engine.stat()),
                                 'confinement': 'snap.busymark_close.busymark (enforce)'},
            }
            errors = []
            verify_installation(record, runner.stat(), engine.stat(), 'busymark_close', errors)
            self.assertEqual(errors, [])

            # The reported path and identical bytes cannot identify a mount.
            verify_installation(record, ordinary_runner.stat(), ordinary_engine.stat(),
                                'busymark', errors)
            self.assertEqual(errors, [
                'Running executable is not the installed instance payload',
                'Mapped engine is not from the installed instance',
                'Enforced BusyMark Snap label was not verified',
            ])

    def test_other_device_and_unobserved_process_fail(self):
        runner = Path(__file__).stat()
        identity = file_identity(runner)
        record = {'executableIdentity': {**identity, 'device': identity['device'] + 1}}
        errors = []
        verify_installation(record, runner, runner, 'busymark', errors)
        self.assertEqual(len(errors), 3)

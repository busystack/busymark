"""Shared portal controls: real owned bus/service, separate from GTK acceptance."""
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from portal_test_support import Channel, Fixture, SERVICE


class PortalSupportTest(unittest.TestCase):
    def test_protocol_preserves_order_and_request_boundary(self):
        source = io.BytesIO(b'{"event":"old"}\n{"event":"new"}\n')
        channel = Channel(source, io.BytesIO())
        # Buffered events avoid depending on a pipe's readiness in this unit.
        channel.buffer = source.read()
        self.assertEqual(channel.read(0)['event'], 'old')
        mark = channel.send({'action': 'request'})
        self.assertEqual(channel.until(lambda e: e['event'] == 'new', after=mark)['event'], 'new')

    def test_application_imports_support_without_upstream_driver(self):
        self.assertEqual(SERVICE.parent, Path(__file__).resolve().parent)
        path = SERVICE.with_name('test_portal_application.py')
        spec = importlib.util.spec_from_file_location('portal_application_control', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertIs(module.Fixture, Fixture)

    def test_archived_driver_keeps_protocol_checks_and_result_publication(self):
        path = SERVICE.parent.parent / 'docs/upstream/flutter/tests/run_portal_initialization.py'
        spec = importlib.util.spec_from_file_location('upstream_portal_control', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        # Driver plumbing only. No claim of executing the proposed engine.
        with tempfile.TemporaryDirectory() as directory, patch.object(module, 'Fixture') as factory:
            fixture = factory.return_value
            fixture.initialized.return_value = dict(clock12=True, dark=True, animations=False, contrast=True, scale=1.5)
            fixture.client_channel.until.return_value = dict(fixture.initialized.return_value, scale=2)
            fixture.progress.return_value = {'changes': 2}
            fixture.service.events = [{'event': 'request', 'member': 'Read'}] * 6
            fixture.cleanup.return_value = {'ok': True}
            output = Path(directory) / 'result'
            with patch.object(module.sys, 'argv', [str(path), '--probe', '/unused', '--output', str(output), '--cases', 'fast']):
                module.main()
            fixture.command.assert_called_once_with('change', namespace='org.gnome.desktop.interface', key='text-scaling-factor', type='d', value=2)
            fixture.close_client.assert_called_once()
            fixture.cleanup.assert_called_once_with(None)
            self.assertTrue((output / 'summary.json').exists())

    def test_owned_service_supplies_authority_and_reports_failures(self):
        for arguments, success in [([], True), (['--fail'], False)]:
            with self.subTest(arguments=arguments), tempfile.TemporaryDirectory(prefix='bmportal-test-') as directory:
                fixture = Fixture(Path(directory) / 'case', Path('/unused'), arguments)
                error = None
                try:
                    fixture.start_bus()
                    client = fixture.launch([
                        '/usr/bin/gdbus', 'call', '--address', fixture.address,
                        '--dest', 'org.freedesktop.portal.Desktop',
                        '--object-path', '/org/freedesktop/portal/desktop',
                        '--method', 'org.freedesktop.portal.Settings.Read',
                        'org.gnome.desktop.interface', 'text-scaling-factor',
                    ], 'reader')
                    output, _ = client.communicate(timeout=5)
                    self.assertEqual(client.returncode == 0, success)
                    if success:
                        self.assertIn(b'1.5', output)
                    # This is a service/protocol test, not a GUI client check.
                    fixture.client = client
                except Exception as failure:
                    error = repr(failure)
                    raise
                finally:
                    record = fixture.cleanup(error)
                    self.assertFalse(record['childObservationErrors'], record)
                    self.assertFalse(record['unresolvedSurvivors'], record)
                    self.assertFalse(record['cleanupErrors'], record)
                    self.assertFalse(record['cleanupOutcomes'], record)
                    for process in fixture.processes:
                        self.assertTrue(process.stdin.closed)
                        self.assertTrue(process.stdout.closed)


if __name__ == '__main__':
    unittest.main()

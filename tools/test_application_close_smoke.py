import json
import hashlib
import os
import subprocess
from pathlib import Path
import re
import sys
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch
from unittest.mock import Mock
from contextlib import redirect_stderr
import io
import ctypes as C

sys.path.insert(0, str(Path(__file__).parent))
from application_close_smoke import PENDING_HARNESS, Desktop, LoadedEngine, ObservationIncomplete, ProcessHandle, accepted, process_children, run_case, signal_owned, snap_command, snapshot_mapped_process


class LaunchLifetimeTest(unittest.TestCase):
    def test_pointer_injection_requires_an_explicitly_disposable_desktop(self):
        with patch('application_close_smoke.subprocess.Popen') as launch:
            with self.assertRaisesRegex(ValueError, 'explicitly disposable'):
                run_case(['/bin/true'], Path('/unused/case'), Path('/unused/profile'),
                         'window-controls', 1)
            launch.assert_not_called()

    def test_drag_rejects_missing_window_before_loading_input_extension(self):
        desktop = Desktop.__new__(Desktop)
        desktop.window = Mock(return_value=None)
        with patch('application_close_smoke.C.CDLL') as extension:
            with self.assertRaisesRegex(ObservationIncomplete, 'unavailable'):
                desktop.drag_window(123, {'x': 20, 'y': 20})
            extension.assert_not_called()

    def test_unexpected_drag_report_cannot_inject_pointer_input(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = '''
import json, pathlib, sys, time
pathlib.Path(sys.argv[1]).write_text(json.dumps({'phase': 'awaiting-window-drag',
                                              'windowDragPoint': {'x': 200, 'y': 20}}))
time.sleep(30)
'''
            with patch.object(Desktop, 'drag_window') as drag:
                record = run_case([sys.executable, '-c', source], root / 'case',
                                  root / 'profile', 'plain', 5)
                drag.assert_not_called()
            self.assertFalse(accepted(record), record)
            self.assertIn('Unexpected pointer-injection request', record['error'])
            self.assertFalse(record.get('unresolvedSurvivors'), record)

    def test_drag_rejects_nonfinite_coordinates_without_injecting_input(self):
        desktop = Desktop.__new__(Desktop)
        desktop.window = Mock(return_value=SimpleNamespace(get_xid=lambda: 7))
        with patch('application_close_smoke.C.CDLL') as extension:
            with self.assertRaisesRegex(ValueError, 'titlebar point'):
                desktop.drag_window(123, {'x': float('nan'), 'y': 20})
            extension.assert_not_called()

    def test_drag_releases_button_when_motion_fails(self):
        desktop = Desktop.__new__(Desktop)
        desktop.window = Mock(return_value=SimpleNamespace(get_xid=lambda: 7))
        desktop.x, desktop.display, desktop.root = Mock(), 1, 2
        def attributes(_display, _xid, pointer):
            pointer._obj.width, pointer._obj.height = 1000, 500
            return 1
        desktop.x.XGetWindowAttributes.side_effect = attributes
        desktop.x.XTranslateCoordinates.return_value = 1
        extension = Mock()
        extension.XTestFakeMotionEvent.side_effect = [1, RuntimeError('motion failed')]
        extension.XTestFakeButtonEvent.return_value = 1
        with patch('application_close_smoke.C.CDLL', return_value=extension), \
             patch('application_close_smoke.time.sleep'):
            with self.assertRaisesRegex(RuntimeError, 'motion failed'):
                desktop.drag_window(123, {'x': 200, 'y': 20})
        self.assertEqual([call.args[1:3] for call in extension.XTestFakeButtonEvent.call_args_list],
                         [(1, 1), (1, 0)])

    def run_failure(self, command, *, desktop=False, failure=None):
        import application_close_smoke as a
        with tempfile.TemporaryDirectory(prefix='bm-launch-lifetime-') as tmp:
            root = Path(tmp)
            tracker_instances = []
            class Tracker(a.ChildTracker):
                def __init__(self):
                    super().__init__()
                    self.closed = 0
                    tracker_instances.append(self)
                def close(self):
                    self.closed += 1
                    return super().close()
            observer = Mock()
            alias = Path('/tmp') / ('bm-close-' + root.name)
            original_open = Path.open
            def opened(path, *args, **kwargs):
                if failure == 'log' and path.name == 'application.log':
                    raise PermissionError('controlled log failure')
                if failure == 'report' and path.name == 'result.json':
                    raise PermissionError('controlled report failure')
                return original_open(path, *args, **kwargs)
            with patch.object(a, 'ChildTracker', Tracker), \
                 patch.object(a, 'Desktop', return_value=observer), \
                 patch.object(a.secrets, 'token_hex', return_value=root.name), \
                 patch.object(Path, 'open', opened), redirect_stderr(io.StringIO()) as errors:
                record = run_case(command(root), root / 'case', root / 'profile', 'plain',
                                  .5, audit_input=desktop, term_grace=.1, kill_grace=1)
            self.assertFalse(accepted(record), record)
            self.assertFalse(alias.is_symlink())
            self.assertFalse(record.get('unresolvedSurvivors'), record)
            self.assertEqual([x.closed for x in tracker_instances], [1])
            if desktop:
                observer.dispose.assert_called_once()
            if failure == 'report':
                self.assertIn('controlled report failure', record['reportingError'])
                self.assertIn('result publication failed', errors.getvalue())
            else:
                self.assertEqual(json.loads((root / 'case/result.json').read_text()), json.loads(json.dumps(record)))
            return record

    def test_real_absent_executable_closes_all_resources_and_reports_original_error(self):
        r = self.run_failure(lambda root: [str(root / 'absent')], desktop=True)
        self.assertEqual(r['errorType'], 'FileNotFoundError')
        self.assertEqual(r['failurePhase'], 'process creation')
        self.assertFalse(r['applicationStarted'])
        self.assertTrue(r['launchSkipped'])

    def test_launch_epoch_preserves_pre_observer_boundary_after_case_setup(self):
        with patch('application_close_smoke.time.monotonic_ns', side_effect=iter(range(10000))):
            r = self.run_failure(lambda root: [str(root / 'absent')])
        self.assertLess(r['caseSetup_ns'], r['launch_ns'])
        self.assertLess(r['launch_ns'], r['spawnRequest_ns'])

    def test_real_nonexecutable_file_reports_failed_creation(self):
        def command(root):
            p = root / 'not-executable'
            p.write_text('not executable')
            p.chmod(0o600)
            return [str(p)]
        r = self.run_failure(command)
        self.assertEqual(r['errorType'], 'PermissionError')
        self.assertFalse(r['applicationStarted'])

    def test_log_open_failure_still_closes_observers_and_alias(self):
        r = self.run_failure(lambda _: ['/bin/true'], desktop=True, failure='log')
        self.assertEqual(r['failurePhase'], 'log opening')
        self.assertFalse(r['applicationStarted'])

    def test_reporting_failure_is_explicit_and_preserves_original_failure(self):
        r = self.run_failure(lambda root: [str(root / 'absent')], failure='report')
        self.assertEqual(r['errorType'], 'FileNotFoundError')
        self.assertIn('absent', r['error'])

    def test_immediate_zero_exit_is_not_normal_application_close(self):
        r = self.run_failure(lambda _: ['/bin/true'])
        self.assertTrue(r['applicationStarted'])
        self.assertEqual(r['exitCode'], 0)
        self.assertIn('Missing normal-close', r['error'])

    def test_setup_failure_has_structured_record_without_launch(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            profile = root / 'profile'
            profile.write_text('not a directory')
            with patch('application_close_smoke.subprocess.Popen') as launch:
                r = run_case(['/bin/true'], root / 'case', profile, 'plain', 1)
            launch.assert_not_called()
            self.assertFalse(accepted(r))
            self.assertEqual(r['failurePhase'], 'setup')
            self.assertIsNone(r['launch_ns'])
            self.assertEqual(json.loads((root / 'case/result.json').read_text()), r)

    def test_partial_desktop_initialization_releases_its_connection(self):
        # Real Desktop constructor and acquisition order; only GI/Xlib are
        # controlled. Failure after XOpenDisplay must close the same pointer.
        import types
        x = Mock()
        x.XOpenDisplay.return_value = 123
        x.XDefaultRootWindow.side_effect = RuntimeError('controlled root failure')
        gi = types.ModuleType('gi')
        gi.require_version = Mock()
        repository = types.ModuleType('gi.repository')
        repository.Gdk = Mock()
        repository.GdkX11 = Mock()
        with patch.dict(sys.modules, {'gi': gi, 'gi.repository': repository}), \
             patch('application_close_smoke.C.CDLL', return_value=x):
            with self.assertRaisesRegex(RuntimeError, 'controlled root failure'):
                Desktop()
        x.XCloseDisplay.assert_called_once_with(123)

    def test_cleanup_error_does_not_replace_launch_failure(self):
        import application_close_smoke as a
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            base = a.ChildTracker.close
            def close(tracker):
                base(tracker)
                raise OSError('controlled close failure')
            with patch.object(a.ChildTracker, 'close', close):
                r = run_case([str(root / 'absent')], root / 'case', root / 'profile', 'plain', 1)
            self.assertEqual(r['errorType'], 'FileNotFoundError')
            self.assertEqual(r['cleanupErrors'][0]['stage'], 'tracker close')
            self.assertFalse(accepted(r))


class MappingObservationTest(unittest.TestCase):
    def test_detection_precedes_snapshot_io_and_legacy_stamp_follows_it(self):
        record, order = {}, []
        def read(path):
            self.assertEqual(record['mapDetected_ns'], 10)
            self.assertNotIn('mapped_ns', record)
            order.append('read')
            return 'controlled maps'
        def write(path, contents):
            self.assertEqual(contents, 'controlled maps')
            self.assertNotIn('mapped_ns', record)
            order.append('write')
        with patch('application_close_smoke.time.monotonic_ns', side_effect=[10, 20]), patch.object(Path, 'read_text', read), patch.object(Path, 'write_text', write):
            snapshot_mapped_process(123, Path('/owned-case'), record)
        self.assertEqual(record, {'mapDetected_ns': 10, 'mapped_ns': 20})
        self.assertEqual(order, ['read', 'write'])

    def test_snapshot_failure_does_not_publish_successful_legacy_stamp(self):
        record = {}
        with patch.object(Path, 'read_text', return_value='maps'), patch.object(Path, 'write_text', side_effect=OSError('snapshot failed')):
            with self.assertRaisesRegex(ObservationIncomplete, 'snapshot failed'):
                snapshot_mapped_process(123, Path('/owned-case'), record)
        self.assertIn('mapDetected_ns', record)
        self.assertNotIn('mapped_ns', record)

    def test_snapshot_keeps_both_endpoints(self):
        record = {}
        with patch.object(Path, 'read_text', return_value='maps'), patch.object(Path, 'write_text'):
            snapshot_mapped_process(123, Path('/owned-case'), record)
        self.assertLessEqual(record['mapDetected_ns'], record['mapped_ns'])


class LoadedEngineAcceptanceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = tempfile.TemporaryDirectory(prefix='bm-engine-elf-')
        cls.addClassCleanup(cls.fixture.cleanup)
        library = Path(cls.fixture.name) / 'official-library-control.so'
        subprocess.run(['clang', '-shared', '-fPIC', '-x', 'c', '-', '-o', str(library)],
                       input='int engine_identity_control(void) { return 1; }',
                       text=True, capture_output=True, check=True)
        cls.library_bytes = library.read_bytes()

    def test_invalid_expected_library_is_rejected(self):
        for data in [b'', b'not ELF', b'\x7fELFtruncated',
                     json.dumps({'oldIdentity': 'a' * 64}).encode()]:
            with self.subTest(data=data), tempfile.TemporaryDirectory() as temp:
                path = Path(temp) / 'invalid'
                path.write_bytes(data)
                with self.assertRaisesRegex(ObservationIncomplete, 'library.*invalid'):
                    LoadedEngine(path)
        with self.assertRaisesRegex(ObservationIncomplete, 'library.*invalid'):
            LoadedEngine('/no-such-engine-library')
        with tempfile.TemporaryDirectory() as temp:
            fifo = Path(temp) / 'not-a-library'
            os.mkfifo(fifo)
            for invalid in [Path(temp), fifo]:
                with self.subTest(path=invalid), self.assertRaises(ObservationIncomplete):
                    LoadedEngine(invalid)


    def test_expected_library_is_hashed(self):
        with tempfile.TemporaryDirectory() as temp:
            library = Path(temp) / 'libflutter_linux_gtk.so'
            library.write_bytes(self.library_bytes)
            probe = LoadedEngine(library)
            self.assertEqual(probe.expected, hashlib.sha256(library.read_bytes()).hexdigest())
            self.assertIsNone(probe.fd)

    def capture(self, root, expected=None, inode_delta=0):
        binary = root / "libflutter_linux_gtk.so"
        binary.write_bytes(self.library_bytes)
        expected_library = root / 'expected.so'
        expected_library.write_bytes(self.library_bytes + (b'different library' if expected else b''))
        probe = LoadedEngine(expected_library)
        st = binary.stat()
        maps = f'00001000-00002000 r-xp 00000000 {os.major(st.st_dev):x}:{os.minor(st.st_dev):x} {st.st_ino + inode_delta} {binary}\n'
        tracker = SimpleNamespace(root=os.getpid(), seen={os.getpid(): "owned"}, errors=[])
        original = ProcessHandle.read
        def read(proc, name):
            return maps.encode() if name == 'maps' else original(proc, name)
        with patch.object(ProcessHandle, 'read', read), patch.object(ProcessHandle, 'state', return_value={'status': 'running'}), patch('application_close_smoke.process_state', return_value={'status': 'running'}):
            probe.capture(tracker)
        return probe, tracker, binary

    def test_retired_root_is_rejected_before_reading_engine_maps(self):
        with tempfile.TemporaryDirectory() as temp:
            library = Path(temp) / 'libflutter_linux_gtk.so'
            library.write_bytes(self.library_bytes)
            probe = LoadedEngine(library)
            tracker = SimpleNamespace(root=os.getpid(), seen={os.getpid(): 'retired'}, errors=[])
            with patch.object(ProcessHandle, 'state', return_value={'status': 'reused'}), patch.object(ProcessHandle, 'read') as read:
                probe.capture(tracker)
            read.assert_not_called()
            self.assertIsNone(probe.fd)

    def test_pinned_mapping_is_hashed_and_closed_after_exit(self):
        with tempfile.TemporaryDirectory() as temp:
            probe, tracker, _ = self.capture(Path(temp))
            fd = probe.fd
            record = {'exitCode': 0}
            probe.finish(record, tracker.errors)
            self.assertEqual(record['loadedEngine']['sha256'], probe.expected)
            self.assertFalse(tracker.errors)
            with self.assertRaises(OSError):
                os.fstat(fd)

    def test_wrong_loaded_engine_keeps_failure_despite_zero_exit(self):
        with tempfile.TemporaryDirectory() as temp:
            probe, tracker, _ = self.capture(Path(temp), expected='0' * 64)
            record = {'exitCode': 0}
            probe.finish(record, tracker.errors)
            record['verificationIncomplete'] = tracker.errors
            self.assertFalse(accepted(record))
            self.assertIn('differs', tracker.errors[0])

    def test_mapped_inode_mismatch_is_incomplete(self):
        with tempfile.TemporaryDirectory() as temp:
            probe, tracker, _ = self.capture(Path(temp), inode_delta=1)
            self.assertIsNone(probe.fd)
            self.assertIn('inode/device', tracker.errors[0])

    def test_changed_file_after_capture_is_not_accepted(self):
        with tempfile.TemporaryDirectory() as temp:
            probe, tracker, binary = self.capture(Path(temp))
            binary.write_bytes(b"changed while mapped")
            record = {'exitCode': 0}
            probe.finish(record, tracker.errors)
            self.assertIn('changed after', tracker.errors[0])

    def test_missing_capture_is_incomplete(self):
        with tempfile.TemporaryDirectory() as temp:
            library = Path(temp) / 'engine.so'
            library.write_bytes(self.library_bytes)
            probe = LoadedEngine(library)
            errors = []
            probe.finish({'exitCode': 0}, errors)
            self.assertIn('incomplete', errors[0])


class NaturalExitAcceptanceTest(unittest.TestCase):
    def test_confined_fixture_keeps_optin_after_launcher_environment_reset(self):
        import application_close_smoke
        with tempfile.TemporaryDirectory(prefix='bm-close-snap-optin-') as temp:
            root = Path(temp)
            binary = root / 'busymark'
            binary.write_text('#!' + sys.executable + '''
import json,os,pathlib,sys
assert os.environ.get('BUSYMARK_RELEASE_SMOKE') == '1', 'smoke opt-in required'
report=pathlib.Path(sys.argv[1])
support=report.parent/'support'
support.mkdir()
(support/'recovery.json').write_text(json.dumps({'cleanShutdown':True}))
report.write_text(json.dumps({'phase':'close-requested','applicationSupport':str(support)}))
''')
            binary.chmod(0o755)

            def isolated_shell(instance, leaf, arguments, extra):
                command = snap_command(instance, leaf, arguments, extra)
                return ['env', 'SNAP=' + str(root), 'SNAP_USER_COMMON=' + str(root / 'common'), 'bash', '-c', command[-1]]

            # Execute the real post-confinement shell, replacing only the
            # privileged launcher. This tests run_case's environment reset;
            # it does not claim native-engine or confinement acceptance.
            with patch.object(application_close_smoke, 'snap_command', side_effect=isolated_shell), patch.object(Path, 'home', return_value=root):
                record = run_case([], root / 'case', root / 'profile', 'plain', 5, snap_instance='busymark_fixture')
            self.assertTrue(accepted(record), record)

    def test_snap_fixture_arguments_are_literal_and_profile_is_isolated(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            binary = root / 'busymark'
            binary.write_text('#!' + sys.executable + '\nimport json,os,sys,pathlib\npathlib.Path(os.environ["SNAP_USER_COMMON"],"argv.json").write_text(json.dumps({"argv":sys.argv[1:],"home":os.environ["HOME"]}))\n')
            binary.chmod(0o755)
            unwanted = root / 'unexpected-command'
            arguments = ['report with spaces.json', 'dirty-save', '$(touch ' + str(unwanted) + ')']
            command = snap_command('busymark_fixture', 'c-owned', arguments)
            env = os.environ.copy()
            env.update(SNAP=str(root), SNAP_USER_COMMON=str(root / 'common'))
            subprocess.run(['bash', '-c', command[-1]], env=env, check=True)
            actual = json.loads((root / 'common/argv.json').read_text())
            self.assertEqual(actual['argv'], arguments)
            self.assertEqual(actual['home'], str(root / 'common/c-owned/home'))
            self.assertFalse(unwanted.exists())

    def test_video_confirmation_samples_only_the_owned_window(self):
        class Pixels:
            def get_pixels(self):
                return bytes([255, 0, 0]) * (600 * 300)

            def get_rowstride(self):
                return 600 * 3

            def get_n_channels(self):
                return 3

        class Gdk:
            observed_window = None

            @classmethod
            def get_default_root_window(cls):
                raise AssertionError('Unrelated desktop pixels cannot confirm video')

            @classmethod
            def pixbuf_get_from_window(cls, window, *geometry):
                cls.observed_window = window
                return Pixels()

        class Window:
            def get_root_origin(self):
                return (100, 100)

        desktop = Desktop.__new__(Desktop)
        desktop.Gdk = Gdk
        owned_window = Window()
        self.assertIsNotNone(desktop.video_sample(owned_window))
        self.assertIs(Gdk.observed_window, owned_window)

    def test_controlled_pending_harness_preserves_production_content_policy(self):
        production = (Path(__file__).parent / 'visualization/harness.html').read_text()
        policy = r'http-equiv="Content-Security-Policy" content="([^"]+)"'
        self.assertEqual(re.search(policy, PENDING_HARNESS).group(1), re.search(policy, production).group(1))

    def run_inferior(self, suffix, timeout=5, plain=False):
        with tempfile.TemporaryDirectory(prefix="bm-close-unit-") as tmp:
            root = Path(tmp)
            source = (
                "import json,pathlib,sys,os,signal,time,resource,ctypes;"
                "resource.setrlimit(resource.RLIMIT_CORE,(0,0));"
                # Limit this deliberately crashing test inferior's core capture;
                # piped system crash handlers may ignore RLIMIT_CORE alone.
                "ctypes.CDLL(None).prctl(4,0,0,0,0);"
                "report=pathlib.Path(sys.argv[1]);"
                "support=report.parent/'support';support.mkdir();"
                "(support/'recovery.json').write_text(json.dumps({'cleanShutdown':True}));"
                "report.write_text(json.dumps({'phase':'close-requested',"
                "'applicationSupport':str(support)}));" + suffix
            )
            if plain:
                source = "import sys;" + suffix
            return run_case([sys.executable, "-c", source], root / "case", root / "profile", "plain", timeout, plain=plain, child_grace=.15, term_grace=.15, kill_grace=2)

    def test_natural_zero_exit_is_accepted(self):
        record = self.run_inferior("sys.exit(0)")
        self.assertTrue(accepted(record))
        self.assertLessEqual(record['launch_ns'], record['spawnRequest_ns'])
        self.assertLessEqual(record['spawnRequest_ns'], record['spawnReturned_ns'])
        self.assertLessEqual(record['spawnReturned_ns'], record['exitObserved_ns'])

    def test_zero_exit_without_an_owned_window_close_is_rejected(self):
        with patch('application_close_smoke.Desktop') as desktop:
            desktop.return_value.window.return_value = None
            record = self.run_inferior("sys.exit(0)", plain=True)
        self.assertEqual(record['exitCode'], 0)
        self.assertFalse(accepted(record))
        self.assertIn('owned-window close', record['error'])

    def test_shipping_close_checks_the_isolated_recovery_checkpoint(self):
        for clean in [True, False]:
            with self.subTest(clean=clean), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                closed = root / 'close-requested'
                source = '''
import json, os, pathlib, sys, time
support = pathlib.Path(os.environ['XDG_DATA_HOME']) / 'io.busystack.busymark'
support.mkdir(parents=True)
(support / 'recovery.json').write_text(json.dumps({'cleanShutdown': sys.argv[2] == 'True'}))
while not pathlib.Path(sys.argv[1]).exists():
    time.sleep(.01)
'''
                with patch('application_close_smoke.Desktop') as desktop:
                    desktop.return_value.close.side_effect = lambda _: closed.touch()
                    record = run_case([sys.executable, '-c', source, str(closed), str(clean)],
                                      root / 'case', root / 'profile', 'plain', 5, plain=True)
                self.assertEqual(record['exitCode'], 0, record)
                self.assertIs(record.get('durableCleanShutdown'), clean, record)
                self.assertEqual(accepted(record), clean, record)
                if not clean:
                    self.assertIn('Durable clean-shutdown checkpoint missing', record['error'])

    def test_fatal_signal_is_rejected_despite_success_checkpoint(self):
        for name in ["SIGABRT", "SIGSEGV"]:
            with self.subTest(signal=name):
                record = self.run_inferior(f"os.kill(os.getpid(),signal.{name})")
                self.assertLess(record["exitCode"], 0)
                self.assertFalse(accepted(record))

    def test_unavailable_child_enumeration_is_incomplete_not_empty(self):
        with patch('owned_processes.process_children', side_effect=ObservationIncomplete('children mechanism inaccessible')):
            record = self.run_inferior('sys.exit(0)')
        self.assertTrue(record['verificationIncomplete'])
        self.assertTrue(record['launchSkipped'])
        self.assertFalse(accepted(record))

    def test_missing_proc_mechanism_is_not_a_process_exit_race(self):
        with patch('owned_processes.process_state', return_value={'pid': os.getpid(), 'status': 'gone'}):
            record = self.run_inferior('sys.exit(0)')
        self.assertTrue(record['verificationIncomplete'])
        self.assertTrue(record['launchSkipped'])

    def test_already_exited_child_is_an_ordinary_observation_race(self):
        import subprocess
        child = subprocess.Popen([sys.executable, '-c', 'pass'])
        child.wait()
        self.assertEqual(process_children(child.pid), [])

    def test_empty_task_snapshot_rechecks_child_exit(self):
        for status in ['gone', 'reused', 'zombie']:
            with self.subTest(status=status), patch(
                'owned_processes.process_state',
                side_effect=[{'status': 'running'}, {'status': status}],
            ), patch('owned_processes.Path.iterdir', return_value=iter([])):
                self.assertEqual(process_children(123456, 'owned-start'), [])

    def test_empty_live_task_snapshot_remains_incomplete(self):
        with patch('owned_processes.process_state', return_value={'status': 'running'}), patch(
            'owned_processes.Path.iterdir', return_value=iter([])
        ), self.assertRaises(ObservationIncomplete):
            process_children(123456, 'owned-start')

    def test_empty_observer_task_snapshot_is_not_its_own_exit(self):
        with patch('owned_processes.process_state', side_effect=[{'status': 'running'}, {'status': 'gone'}]), patch(
            'owned_processes.Path.iterdir', return_value=iter([])
        ), self.assertRaises(ObservationIncomplete):
            process_children(os.getpid())

    def test_missing_observer_task_directory_is_not_its_own_exit(self):
        with patch('owned_processes.process_state', side_effect=[{'status': 'running'}, {'status': 'gone'}]), patch(
            'owned_processes.Path.iterdir', side_effect=FileNotFoundError('proc unavailable')
        ), self.assertRaises(ObservationIncomplete):
            process_children(os.getpid())

    def test_empty_task_snapshot_with_unavailable_final_state_is_incomplete(self):
        with patch('owned_processes.process_state', side_effect=[{'status': 'running'}, {'status': 'unavailable', 'error': 'access denied'}]), patch(
            'owned_processes.Path.iterdir', return_value=iter([])
        ), self.assertRaises(ObservationIncomplete):
            process_children(123456, 'owned-start')

    def test_failed_enumeration_after_launch_preserves_incomplete_failure(self):
        def inaccessible(pid, expected=None):
            if pid != os.getpid():
                raise ObservationIncomplete('live child task inaccessible')
            return process_children(pid, expected)
        with patch('owned_processes.process_children', side_effect=inaccessible):
            record = self.run_inferior('time.sleep(30)')
        self.assertTrue(record['verificationIncomplete'])
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(all(r['terminationVerified'] for r in record['cleanupOutcomes']))

    def orphan(self, ignores_term, leader_exits=False):
        return self.run_inferior("""
child = os.fork()
if child == 0:
    if IGNORE_TERM:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
    if LEADER_EXITS:
        import threading
        threading.Thread(target=lambda: time.sleep(30)).start()
    (report.parent / 'child-ready').write_text(str(os.getpid()))
    if LEADER_EXITS:
        ctypes.CDLL(None).pthread_exit(None)
    time.sleep(30)
    os._exit(0)
while not (report.parent / 'child-ready').exists():
    time.sleep(.001)
if LEADER_EXITS:
    while pathlib.Path(f'/proc/{child}/stat').read_text().rsplit(')', 1)[1].split()[0] != 'Z':
        time.sleep(.001)
os._exit(0)
""".replace('IGNORE_TERM', repr(ignores_term)).replace('LEADER_EXITS', repr(leader_exits)))

    def test_parent_exits_before_child_cleanup_waits_for_child(self):
        record = self.orphan(False)
        self.assertEqual(record['exitCode'], 0)
        self.assertTrue(record['survivingChildren'])
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(all(r['terminationVerified'] for r in record['cleanupOutcomes']))
        self.assertTrue(any(r.get('term') == 'sent' and 'kill' not in r for r in record['cleanupOutcomes']))

    def test_child_ignoring_term_is_killed_and_failure_is_preserved(self):
        record = self.orphan(True)
        self.assertEqual(record['exitCode'], 0)
        self.assertTrue(record['survivingChildren'])
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(any(r.get('term') == 'sent' and r.get('kill') == 'sent' and r['terminationVerified'] for r in record['cleanupOutcomes']))

    def test_zombie_leader_with_live_worker_is_waited_for_and_cleaned_up(self):
        record = self.orphan(True, leader_exits=True)
        self.assertEqual(record['exitCode'], 0)
        self.assertTrue(any(r.get('leaderState') == 'Z' and r['status'] == 'running' and r['threads'] > 1 for r in record['survivingChildren']))
        self.assertFalse(accepted(record))
        self.assertFalse(record['unresolvedSurvivors'])
        self.assertTrue(any(r.get('term') == 'sent' and r.get('kill') == 'sent' and r['terminationVerified'] for r in record['cleanupOutcomes']))

    def test_cohort_stops_when_survivor_verification_is_unresolved(self):
        import application_close_smoke
        with tempfile.TemporaryDirectory(prefix='bm-close-stop-') as tmp:
            output = str(Path(tmp) / 'evidence')
            record = {'exitCode': 0, 'unresolvedSurvivors': [{'pid': 123, 'status': 'unavailable'}]}
            with patch.object(sys, 'argv', ['close', '--output', output, '--cycles', '2', '--scenarios', 'plain', '--', 'unused']), patch.object(application_close_smoke, 'run_case', return_value=record) as run:
                self.assertEqual(application_close_smoke.main(), 1)
                self.assertEqual(run.call_count, 1)
            self.assertEqual(json.loads((Path(output) / 'summary.json').read_text())['failures'], 1)

    def test_cleanup_refuses_a_mismatched_process_identity(self):
        self.assertEqual(signal_owned(os.getpid(), 'not-this-process-start', 9), 'reused')

    def test_confined_fixture_reopen_uses_same_instance_and_profile(self):
        import application_close_smoke
        with tempfile.TemporaryDirectory(prefix='bm-close-snap-reopen-') as tmp:
            home = Path(tmp)
            root = home / 'snap/busymark_fixture/common/close'
            document = str(root.parent / 'document.md')
            records = [{'exitCode': 0, 'application': {'document': document}}, {'exitCode': 0}]
            args = ['close', '--output', str(root), '--scenarios', 'dirty-save',
                    '--snap-instance', 'busymark_fixture', '--snap-fixture',
                    '--expected-engine', str(home / 'libflutter_linux_gtk.so')]
            with patch.object(sys, 'argv', args), patch.object(Path, 'home', return_value=home), patch.object(application_close_smoke, 'run_case', side_effect=records) as run:
                self.assertEqual(application_close_smoke.main(), 0)
                self.assertEqual(run.call_count, 2)
                initial, reopened = run.call_args_list
                self.assertEqual(initial.args[7], 'busymark_fixture')
                self.assertEqual(reopened.kwargs['snap_instance'], initial.args[7])
                self.assertEqual(reopened.args[2], initial.args[2])
                self.assertEqual(reopened.args[3], 'reopen')
                self.assertEqual(reopened.kwargs['document'], Path(document))

    def test_hang_is_rejected_and_cleanup_is_explicit(self):
        record = self.run_inferior("time.sleep(30)", timeout=.3)
        self.assertIsNone(record["exitCode"])
        self.assertIn("deadline", record["error"])
        self.assertTrue(record["cleanupRequired"])
        self.assertFalse(accepted(record))


class OwnedInputIsolationTest(unittest.TestCase):
    def test_unavailable_desktop_is_recorded_before_launch_and_alias_is_removed(self):
        for error in [ModuleNotFoundError('No module named gi'),
                      RuntimeError('No authenticated X11 display')]:
            with self.subTest(error=type(error).__name__), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                with patch('application_close_smoke.Desktop', side_effect=error), \
                     patch('application_close_smoke.subprocess.Popen') as launch, \
                     patch('application_close_smoke.secrets.token_hex', return_value=root.name):
                    record = run_case([], root / 'case', root / 'profile',
                                      'plain', 1, plain=True)
                launch.assert_not_called()
                self.assertTrue(record['launchSkipped'])
                self.assertTrue(record['verificationIncomplete'])
                self.assertEqual(record['observationInterpreter'], sys.executable)
                if isinstance(error, ImportError):
                    self.assertIn('/usr/bin/python3', record['error'])
                self.assertFalse(accepted(record))
                self.assertFalse((Path('/tmp') / ('bm-close-' + root.name)).is_symlink())
                self.assertEqual(json.loads((root / 'case/result.json').read_text()), record)

    def test_unavailable_input_observation_is_incomplete(self):
        from application_close_smoke import check_input_isolation
        with self.assertRaises(ObservationIncomplete):
            check_input_isolation(dict(errors=['X selection failed'], keyPresses=0,
                                       keyReleases=0, activeSamples=0))

    def test_keyboard_interference_stays_failed_even_after_successful_cleanup(self):
        from application_close_smoke import check_input_isolation
        result = dict(errors=[], keyPresses=1, keyReleases=1, activeSamples=0)
        with self.assertRaisesRegex(RuntimeError, 'Unexpected keyboard') as error:
            check_input_isolation(result)
        self.assertFalse(accepted({'exitCode': 0, 'error': str(error.exception),
                                   'cleanupOutcomes': [{'terminationVerified': True}]}))

    def test_focus_acquisition_does_not_count_as_verified_isolation(self):
        from application_close_smoke import check_input_isolation
        with self.assertRaisesRegex(ObservationIncomplete, 'acquired keyboard focus'):
            check_input_isolation(dict(errors=[], keyPresses=0, keyReleases=0,
                                       activeSamples=1, focusSamples=1))

    def test_activation_is_distinct_from_core_keyboard_focus(self):
        from application_close_smoke import check_input_isolation
        with self.assertRaisesRegex(ObservationIncomplete, 'became active'):
            check_input_isolation(dict(errors=[], keyPresses=0, keyReleases=0,
                                       activeSamples=1, focusSamples=0))

    def test_normal_focus_audit_accepts_focus_without_unexpected_input(self):
        from application_close_smoke import check_owned_input
        check_owned_input(dict(errors=[], keyPresses=0, keyReleases=0,
                               activeSamples=1, focusSamples=1))

    def test_normal_focus_audit_still_rejects_input(self):
        from application_close_smoke import check_owned_input
        with self.assertRaisesRegex(RuntimeError, 'Unexpected keyboard'):
            check_owned_input(dict(errors=[], keyPresses=1, keyReleases=0,
                                   activeSamples=1, focusSamples=1))

    def test_missing_core_focus_observation_is_incomplete(self):
        from application_close_smoke import check_owned_input
        with self.assertRaisesRegex(ObservationIncomplete, 'focus observation missing'):
            check_owned_input(dict(errors=[], keyPresses=0, keyReleases=0,
                                   activeSamples=0))

    def test_only_owned_events_are_counted_without_key_payload_and_details_are_bounded(self):
        from application_close_smoke import OwnedInputAudit, InputEvent
        audit = OwnedInputAudit.__new__(OwnedInputAudit)
        audit.windows = {123}
        audit.events = []
        audit.key_presses = audit.key_releases = 0
        event = InputEvent()
        event.any.type, event.any.window = 2, 999
        audit.observe(event)
        self.assertEqual(audit.key_presses, 0)
        self.assertFalse(audit.events)
        event.any.window = 123
        for _ in range(100):
            audit.observe(event)
        self.assertEqual(audit.key_presses, 100)
        self.assertEqual(len(audit.events), 16)
        self.assertEqual(set(audit.events[0]), {'kind', 'synthetic', 'source', 'observed_ns'})

    def test_xi2_unavailable_is_incomplete_instead_of_core_only_success(self):
        from application_close_smoke import OwnedInputAudit
        audit = OwnedInputAudit.__new__(OwnedInputAudit)
        audit.display = None
        audit.x = SimpleNamespace(XQueryExtension=Mock(return_value=0))
        for failure in [OSError('libXi unavailable'), AttributeError('missing symbol')]:
            with self.subTest(failure=str(failure)), patch('application_close_smoke.C.CDLL', side_effect=failure):
                with self.assertRaises(ObservationIncomplete):
                    audit._prepare_xi2()
        with patch('application_close_smoke.C.CDLL', return_value=SimpleNamespace()):
            with self.assertRaisesRegex(ObservationIncomplete, 'requires XInput2'):
                audit._prepare_xi2()
        audit.x.XQueryExtension.return_value = 1
        with patch('application_close_smoke.C.CDLL', return_value=SimpleNamespace(XIQueryVersion=Mock(return_value=1))):
            with self.assertRaisesRegex(ObservationIncomplete, 'version 2'):
                audit._prepare_xi2()

    def query_retirement(self, *, destroyed, code=3, resource=123):
        from application_close_smoke import OwnedInputAudit, InputError
        audit = OwnedInputAudit.__new__(OwnedInputAudit)
        audit.display, audit.root_window, audit.xi_opcode = None, 123, 131
        audit.windows, audit.window_updates, audit.errors = {123}, [], []
        audit.retirement_races, audit.retired = [], False
        handler = None

        def set_handler(address):
            nonlocal handler
            previous, handler = handler, address
            return previous

        def query(*_):
            callback = C.CFUNCTYPE(C.c_int, C.c_void_p, C.POINTER(InputError))(handler.value)
            error = InputError(resource=resource, error_code=code, request_code=15)
            callback(None, C.byref(error))
            return 0

        def drain():
            if 123 in destroyed:
                audit.retired = True
                audit.windows.clear()
            return destroyed

        audit.x = SimpleNamespace(XSetErrorHandler=set_handler, XQueryTree=query,
                                  XSync=Mock())
        audit._drain_events = drain
        return audit

    def test_query_badwindow_requires_matching_owned_destroy_notification(self):
        for arguments in [dict(destroyed=set()), dict(destroyed={123}, code=10),
                          dict(destroyed={123}, resource=999)]:
            with self.subTest(arguments=arguments):
                audit = self.query_retirement(**arguments)
                with self.assertRaises(ObservationIncomplete):
                    audit._refresh_windows()
                self.assertFalse(audit.retirement_races)

    def test_query_badwindow_after_observed_retirement_is_recorded(self):
        audit = self.query_retirement(destroyed={123})
        audit._refresh_windows()
        self.assertTrue(audit.retired)
        self.assertFalse(audit.windows)
        self.assertFalse(audit.errors)
        self.assertEqual(audit.retirement_races[0]['resource'], 123)

    def xi_event(self, xid=123, kind=2):
        from application_close_smoke import OwnedInputAudit, InputEvent, InputCookie, DeviceKeyPrefix
        audit = OwnedInputAudit.__new__(OwnedInputAudit)
        audit.windows, audit.events, audit.errors = {123}, [], []
        audit.key_presses = audit.key_releases = 0
        audit.xi_opcode, audit.display = 131, None
        audit.x = SimpleNamespace(XGetEventData=Mock(return_value=1), XFreeEventData=Mock())
        event = InputEvent()
        cookie = C.cast(C.byref(event), C.POINTER(InputCookie)).contents
        cookie.type, cookie.extension, cookie.evtype = 35, 131, kind
        data = DeviceKeyPrefix()
        data.event, data.evtype = xid, kind
        cookie.data = C.addressof(data)
        return audit, event, cookie, data

    def test_xi2_owned_keys_are_counted_without_payload_and_cookie_is_freed(self):
        for kind in [2, 3]:
            with self.subTest(kind=kind):
                audit, event, cookie, data = self.xi_event(kind=kind)
                audit.observe(event)
                self.assertEqual((audit.key_presses, audit.key_releases), (1, 0) if kind == 2 else (0, 1))
                self.assertEqual(audit.events[0]['source'], 'XI2')
                self.assertEqual(set(audit.events[0]), {'kind', 'synthetic', 'source', 'observed_ns'})
                audit.x.XFreeEventData.assert_called_once()

    def test_xi2_does_not_observe_unowned_windows_or_other_extension_events(self):
        audit, event, cookie, data = self.xi_event(xid=999)
        audit.observe(event)
        self.assertEqual(audit.key_presses, 0)
        audit.x.XFreeEventData.assert_called_once()
        audit.x.XGetEventData.reset_mock()
        cookie.extension = 999
        audit.observe(event)
        cookie.extension, cookie.evtype = 131, 6
        audit.observe(event)
        audit.x.XGetEventData.assert_not_called()

    def test_missing_xi2_event_data_makes_verification_incomplete(self):
        from application_close_smoke import check_owned_input
        for available in [True, False]:
            with self.subTest(available=available):
                audit, event, cookie, data = self.xi_event()
                if available:
                    cookie.data = None
                else:
                    audit.x.XGetEventData.return_value = 0
                audit.observe(event)
                with self.assertRaises(ObservationIncomplete):
                    check_owned_input(dict(errors=audit.errors))
                self.assertEqual(audit.x.XFreeEventData.call_count, int(available))

    def test_close_does_not_send_a_request_after_unexpected_input(self):
        desktop = Desktop.__new__(Desktop)
        desktop.input_audit = SimpleNamespace(result=lambda: dict(
            errors=[], keyPresses=1, keyReleases=0, activeSamples=0))
        with self.assertRaisesRegex(RuntimeError, 'Unexpected keyboard'):
            desktop.close(SimpleNamespace(get_xid=lambda: 123))



if __name__ == "__main__":
    unittest.main()

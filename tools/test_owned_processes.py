"""Ownership admission and anchored snapshot controls; never use unrelated PIDs."""
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parent))
import owned_processes as owned


def stat_line(pid, parent, birth, state='S', threads=1):
    fields = ['0'] * 22
    fields[0], fields[1], fields[17], fields[19] = state, str(parent), str(threads), birth
    return f'{pid} (owned fixture) ' + ' '.join(fields)


class OwnedProcessTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.proc = self.root / 'proc'
        self.proc.mkdir()
        self.output = self.root / 'capture'
        self.output.mkdir()
        original_open = os.open

        def fixture_open(name, *args, **kwargs):
            # Relative reads use a real dirfd. Only replace the initial proc
            # lookup, so the mid-read replacement exercises actual fd anchoring.
            if str(name).startswith('/proc/'):
                name = self.proc / Path(name).name
            return original_open(name, *args, **kwargs)

        self.open_patch = patch.object(owned.os, 'open', fixture_open)
        self.open_patch.start()
        self.addCleanup(self.open_patch.stop)

    def process(self, pid, parent, birth, text='owned bytes'):
        root = self.proc / str(pid)
        root.mkdir()
        (root / 'stat').write_text(stat_line(pid, parent, birth))
        for field in ['maps', 'cmdline']:
            (root / field).write_text(text)
        (root / 'exe').symlink_to('/owned/fixture')
        task = root / 'task' / str(pid)
        task.mkdir(parents=True)
        for field in ['status', 'wchan', 'syscall']:
            (task / field).write_text(text)
        return root

    def test_first_admission_rejects_replacement_with_unrelated_parent(self):
        self.process(200, 999, 'unrelated-new-birth')
        tracker = owned.ChildTracker.__new__(owned.ChildTracker)
        tracker.root, tracker.seen = 100, {100: 'owned-root'}
        tracker.admitted_by, tracker.errors, tracker.unidentified = {}, [], {}
        tracker.engine = tracker.input_audit = None

        def children(pid, expected=None):
            return [200] if pid == 100 else []

        with patch.object(owned, 'process_children', children), patch.object(
            owned, 'process_state', return_value={'pid': 100, 'identity': 'owned-root', 'status': 'running'}
        ), patch.object(owned, 'signal_owned') as send:
            tracker.scan()
        self.assertNotIn(200, tracker.seen)
        self.assertIn('Rejected unowned birth', str(tracker.errors))
        send.assert_not_called()

    def test_accepts_child_of_still_matching_parent(self):
        self.process(200, 100, 'child')
        with patch.object(owned, 'process_state', return_value={'status': 'running'}) as parent:
            state = owned.admit_child(200, 100, 'owned-root')
        parent.assert_called_once_with(100, 'owned-root')
        self.assertEqual(state['identity'], 'child')

    def test_reaped_dead_task_never_acquires_admission_or_signal_authority(self):
        for index, (state, threads) in enumerate([('X', 0), ('X', 1), ('Z', 0)]):
            pid = 200 + index
            proc = self.process(pid, 0, 'retired')
            (proc / 'stat').write_text(stat_line(pid, 0, 'retired', state, threads))
            tracker = owned.ChildTracker.__new__(owned.ChildTracker)
            tracker.root, tracker.seen = 100, {100: 'root'}
            tracker.admitted_by, tracker.errors, tracker.unidentified = {}, [], {}
            tracker.engine = tracker.input_audit = None
            with patch.object(owned, 'process_children', side_effect=lambda parent, expected=None: [pid] if parent == 100 else []), patch.object(
                owned, 'process_state', return_value={'pid': 100, 'identity': 'root', 'status': 'running'}
            ), patch.object(owned, 'signal_owned') as send:
                tracker.scan()
            self.assertNotIn(pid, tracker.seen)
            self.assertFalse(tracker.errors)
            send.assert_not_called()

    def test_dead_leader_does_not_hide_other_live_threads_or_identity_reuse(self):
        proc = self.process(200, 0, 'replacement')
        (proc / 'stat').write_text(stat_line(200, 0, 'replacement', 'X', 2))
        with self.assertRaises(owned.ObservationIncomplete):
            owned.admit_child(200, 100, 'root')
        (proc / 'stat').write_text(stat_line(200, 0, 'replacement', 'X', 0))
        with owned.ProcessHandle(200) as handle:
            self.assertEqual(handle.state('previous')['status'], 'reused')

    def test_child_retiring_during_parent_verification_is_not_an_ancestry_failure(self):
        proc = self.process(200, 100, 'child')
        def reap(*args):
            (proc / 'stat').write_text(stat_line(200, 0, 'child', 'X', 0))
            return {'status': 'running'}
        with patch.object(owned, 'process_state', side_effect=reap):
            self.assertEqual(owned.admit_child(200, 100, 'root')['status'], 'gone')

    def test_seen_pid_replacement_from_child_list_is_not_silently_lost(self):
        tracker = owned.ChildTracker.__new__(owned.ChildTracker)
        tracker.root, tracker.seen = 100, {100: 'root', 200: 'retired-child'}
        tracker.admitted_by, tracker.errors, tracker.unidentified = {}, [], {}
        tracker.engine = tracker.input_audit = None
        def children(pid, expected=None):
            return [200] if pid == 100 else []
        def state(pid, expected=None):
            return {'pid': pid, 'identity': expected, 'status': 'running' if pid == 100 else 'reused'}
        with patch.object(owned, 'process_children', children), patch.object(owned, 'process_state', state):
            tracker.scan()
        self.assertIn('new ownership is unverified', str(tracker.errors))
        self.assertEqual(tracker.seen[200], 'retired-child')

    def test_parent_reuse_cannot_authorize_new_child(self):
        self.process(200, 100, 'replacement')
        with patch.object(owned, 'process_state', return_value={'status': 'reused'}):
            with self.assertRaises(owned.ObservationIncomplete):
                owned.admit_child(200, 100, 'old-root')

    def test_orphan_adoption_during_parent_exit_is_accepted(self):
        proc = self.process(200, 100, 'owned-child')

        def parent_exits(*args):
            (proc / 'stat').write_text(stat_line(200, os.getpid(), 'owned-child'))
            return {'status': 'gone'}

        with patch.object(owned, 'process_state', side_effect=parent_exits):
            self.assertEqual(owned.admit_child(200, 100, 'owned-root')['identity'], 'owned-child')

    def test_already_adopted_child_is_accepted(self):
        self.process(200, os.getpid(), 'owned-child')
        self.assertEqual(owned.admit_child(200, 100, 'exited-parent')['identity'], 'owned-child')

    def test_snapshot_rejects_stale_birth_without_reading_payload(self):
        self.process(200, 999, 'replacement', 'unrelated bytes')
        original_read = owned.ProcessHandle.read

        def read(handle, name):
            self.assertEqual(name, 'stat', 'payload read before identity validation')
            return original_read(handle, name)

        with patch.object(owned.ProcessHandle, 'read', read):
            result = owned.snapshot_owned(200, 'original', self.output)
        self.assertEqual(result['status'], 'reused')
        self.assertEqual(list(self.output.iterdir()), [])

    def test_snapshot_stays_on_same_birth_across_pid_replacement(self):
        proc = self.process(200, 100, 'original')
        original_read = owned.ProcessHandle.read
        replaced = False

        def read(handle, name):
            nonlocal replaced
            data = original_read(handle, name)
            if name == 'stat' and not replaced:
                replaced = True
                proc.rename(self.proc / 'retired')
                self.process(200, 999, 'replacement', 'unrelated bytes')
            return data

        with patch.object(owned.ProcessHandle, 'read', read):
            result = owned.snapshot_owned(200, 'original', self.output)
        self.assertEqual(result['status'], 'running')
        self.assertEqual((self.output / '200-maps').read_text(), 'owned bytes')
        self.assertNotIn('unrelated bytes', ''.join(p.read_text() for p in self.output.iterdir()))

    def test_missing_snapshot_is_exit_race_but_inaccessible_is_incomplete(self):
        self.assertEqual(owned.snapshot_owned(200, 'gone', self.output)['status'], 'gone')
        with patch.object(owned.ProcessHandle, '__init__', side_effect=PermissionError('inaccessible proc')):
            result = owned.snapshot_owned(200, 'owned', self.output)
        self.assertEqual(result['status'], 'unavailable')

    def test_matching_live_unreadable_snapshot_is_incomplete(self):
        self.process(200, 100, 'original')
        original_read = owned.ProcessHandle.read

        def read(handle, name):
            if name == 'maps':
                raise PermissionError('unreadable live maps')
            return original_read(handle, name)

        with patch.object(owned.ProcessHandle, 'read', read):
            result = owned.snapshot_owned(200, 'original', self.output)
        self.assertEqual(result['status'], 'unavailable')
        self.assertIn('maps', str(result['fieldErrors']))

    def test_snapshot_publication_failure_is_not_classified_as_exit(self):
        self.process(200, 100, 'original')
        with self.assertRaisesRegex(owned.ObservationIncomplete, 'publication'):
            owned.snapshot_owned(200, 'original', self.output / 'missing')


if __name__ == '__main__':
    unittest.main()

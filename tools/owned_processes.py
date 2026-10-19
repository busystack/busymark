"""Linux owned-process observation shared by application and fixture supervisors.

One dedicated observer/subreaper per case; no pre-existing or concurrent
unrelated children. Unknown ownership fails verification and is never signalled.
"""
import ctypes as C
import os
from pathlib import Path
import signal
import time


class ObservationIncomplete(RuntimeError):
    pass


def _parse_state(pid, text, expected=None):
    fields = text.rsplit(')', 1)[1].split()
    stamp, state = fields[19], fields[0]
    threads = int(fields[17])
    # /proc/PID/stat describes the thread-group leader. WebKit can leave
    # that leader a zombie while another thread is still running; waitpid
    # cannot reap the process yet. Keep observing/waiting for that group.
    finished = state == 'Z' and threads == 1
    if expected is not None and stamp != expected:
        status = 'reused'
    elif (state == 'X' and threads in (0, 1)) or (state == 'Z' and threads == 0):
        # An anchored stat read can race release_task: state can still be Z
        # when the last thread is gone and parent is already 0. A dead group
        # grants no admission/signal authority, regardless of its old ancestry.
        status = 'gone'
    else:
        status = 'zombie' if finished else 'running'
    result = {'pid': pid, 'identity': stamp, 'status': status, 'parent': int(fields[1])}
    if state in ('Z', 'X') and status == 'running':
        result.update(leaderState=state, threads=threads)
    return result


def process_state(pid, expected=None):
    try:
        return _parse_state(pid, Path(f'/proc/{pid}/stat').read_text(), expected)
    except (FileNotFoundError, ProcessLookupError):
        return {'pid': pid, 'status': 'gone'}
    except (OSError, IndexError, ValueError) as error:
        return {'pid': pid, 'status': 'unavailable', 'error': str(error)}


class ProcessHandle:
    """Anchor proc reads to one birth. An old proc fd cannot follow PID reuse.

    Fields read through this handle are fixed procfs names, never
    application-provided paths.
    """
    def __init__(self, pid):
        self.pid = pid
        self.fd = os.open(f'/proc/{pid}', os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC | os.O_NOFOLLOW)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        os.close(self.fd)

    def read(self, name):
        fd = os.open(name, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW, dir_fd=self.fd)
        with os.fdopen(fd, 'rb') as stream:
            return stream.read()

    def state(self, expected=None):
        try:
            return _parse_state(self.pid, self.read('stat').decode(), expected)
        except (FileNotFoundError, ProcessLookupError):
            return {'pid': self.pid, 'status': 'gone'}
        except (OSError, IndexError, ValueError) as error:
            return {'pid': self.pid, 'status': 'unavailable', 'error': str(error)}


def admit_child(pid, parent, parent_identity):
    """Prove current ancestry before recording a previously unseen birth.

    The child list contains PID numbers, not identities. A replacement whose
    parent is unrelated must never acquire cleanup authority. An orphan may
    legitimately have moved to this dedicated subreaper since enumeration.
    Recheck the anchored child after checking its parent's identity.
    """
    try:
        with ProcessHandle(pid) as child:
            state = child.state()
            if state['status'] in ('gone', 'unavailable'):
                return state
            actual_parent = state['parent']
            if actual_parent == os.getpid():
                pass  # Dedicated observer is alive and cannot have been reused.
            elif actual_parent == parent:
                owner = process_state(parent, parent_identity)
                if owner['status'] != 'running':
                    state = child.state(state['identity'])
                    if state['status'] in ('gone', 'reused'):
                        return state
                    if state.get('parent') != os.getpid():
                        raise ObservationIncomplete(f'Cannot verify parent {parent} of child {pid}: {owner}')
            else:
                raise ObservationIncomplete(f'Rejected unowned birth {pid}: parent {actual_parent}, enumerated by {parent}')
            final = child.state(state['identity'])
            if final['status'] in ('running', 'zombie') and final['parent'] not in (actual_parent, os.getpid()):
                raise ObservationIncomplete(f'Child {pid} changed ancestry during admission: {final}')
            return final
    except (FileNotFoundError, ProcessLookupError):
        return {'pid': pid, 'status': 'gone'}
    except OSError as error:
        raise ObservationIncomplete(f'Cannot anchor child {pid}: {error}') from error


def identity(pid):
    return process_state(pid).get('identity')


def live(pid, expected):
    return process_state(pid, expected)['status'] == 'running'


def process_children(pid, expected=None):
    """ENOENT after process/thread exit is a race; a live unreadable task is not."""
    state = process_state(pid, expected)
    if pid == os.getpid() and state['status'] != 'running':
        raise ObservationIncomplete(f'/proc observation mechanism unavailable: {state}')
    if state['status'] in ('gone', 'reused', 'zombie'):
        return []
    if state['status'] == 'unavailable':
        raise ObservationIncomplete(f'Cannot identify process {pid}: {state}')
    task = Path(f'/proc/{pid}/task')
    try:
        threads = list(task.iterdir())
        if not threads:
            # Exit can empty the task directory after the initial state read.
            # Recheck identity/state, as for ENOENT, rather than calling that
            # ordinary race an unavailable observation mechanism. Our own
            # running observer cannot have exited while executing this check.
            final_state = process_state(pid, expected)
            if pid != os.getpid() and final_state['status'] in ('gone', 'reused', 'zombie'):
                return []
            raise ObservationIncomplete(f'No observable tasks for process {pid}: initial={state}, final={final_state}')
    except OSError as error:
        if pid != os.getpid() and process_state(pid, expected)['status'] in ('gone', 'reused', 'zombie'):
            return []
        raise ObservationIncomplete(f'Cannot enumerate tasks for {pid}: {error}') from error
    children = []
    for thread in threads:
        try:
            children.extend(map(int, (thread / 'children').read_text().split()))
        except OSError as error:
            if process_state(pid, expected)['status'] in ('gone', 'reused', 'zombie'):
                continue
            if isinstance(error, FileNotFoundError) and not thread.exists():
                continue  # This particular thread exited during the snapshot.
            raise ObservationIncomplete(f'Cannot enumerate {thread}/children: {error}') from error
    return children


class ChildTracker:
    """A dedicated observer adopts orphan descendants, including new sessions.

    Linux subreaper state changes only this observer. No other child may exist
    at entry, so children adopted after the application starts belong to this
    case. This closes the parent-exits-between-polls observation gap.
    """
    def __init__(self):
        if process_children(os.getpid()):
            raise ObservationIncomplete('Observer already has children; ownership would be ambiguous')
        self.libc = C.CDLL(None, use_errno=True)
        previous = C.c_int()
        if self.libc.prctl(37, C.byref(previous), 0, 0, 0) != 0:
            raise ObservationIncomplete(f'PR_GET_CHILD_SUBREAPER unavailable: errno {C.get_errno()}')
        self.previous = previous.value
        self.seen = {}
        self.admitted_by = {}
        self.root = None
        self.errors = []
        self.unidentified = {}
        self.engine = None
        self.input_audit = None
        # Allocate Python state before acquiring the process-wide resource.
        # There must be no fallible initialization after setting subreaper.
        if self.libc.prctl(36, 1, 0, 0, 0) != 0:
            raise ObservationIncomplete(f'PR_SET_CHILD_SUBREAPER unavailable: errno {C.get_errno()}')

    def scan(self):
        pending = [(self.root, None, None)] if self.root in self.seen else []
        # A successful read here discovers descendants even if their parent
        # exited before its first snapshot or a helper started a new session.
        try:
            pending.extend((pid, os.getpid(), None) for pid in process_children(os.getpid()))
        except ObservationIncomplete as error:
            self.errors.append(str(error))
        visited = set()
        while pending:
            pid, parent, parent_identity = pending.pop()
            if pid in visited:
                continue
            visited.add(pid)
            try:
                state = (process_state(pid, self.seen[pid]) if pid in self.seen
                         else admit_child(pid, parent, parent_identity))
            except ObservationIncomplete as error:
                self.errors.append(str(error))
                continue  # No ownership proof, therefore no cleanup authority.
            if state['status'] == 'unavailable':
                self.errors.append(str(state))
                self.unidentified[pid] = state
                continue
            if state['status'] in ('gone', 'reused'):
                if state['status'] == 'reused' and parent is not None:
                    self.errors.append(f'Child PID {pid} reused during this case; new ownership is unverified')
                continue
            self.unidentified.pop(pid, None)
            if pid not in self.seen:
                self.seen[pid] = state['identity']
                self.admitted_by[pid] = {'enumeratedBy': parent, 'enumeratedIdentity': parent_identity,
                                        'verifiedParent': state['parent'],
                                        'adoptedByObserver': state['parent'] == os.getpid()}
            if state['status'] == 'zombie':
                if pid != self.root:
                    try:
                        os.waitpid(pid, os.WNOHANG)
                    except ChildProcessError:
                        pass
                continue
            try:
                pending.extend((child, pid, self.seen[pid]) for child in process_children(pid, self.seen[pid]))
            except ObservationIncomplete as error:
                self.errors.append(str(error))
        self.errors = list(dict.fromkeys(self.errors))
        if self.engine is not None:
            self.engine.capture(self)
        if self.input_audit is not None:
            self.input_audit.poll()

    def outstanding(self, children_only=False):
        self.scan()
        for pid in list(self.unidentified):
            if process_state(pid)['status'] == 'gone':
                self.unidentified.pop(pid)
        outstanding = [state for state in self.unidentified.values() if state['pid'] != self.root or not children_only]
        for pid, stamp in self.seen.items():
            if children_only and pid == self.root:
                continue
            state = process_state(pid, stamp)
            if state['status'] in ('running', 'unavailable'):
                outstanding.append(state)
        return outstanding

    def close(self):
        if self.libc.prctl(36, self.previous, 0, 0, 0) != 0:
            self.errors.append(f'Could not restore observer subreaper state: errno {C.get_errno()}')


def signal_owned(pid, stamp, number):
    """Pin the process before the final identity check; never signal a reused PID."""
    try:
        if hasattr(os, 'pidfd_open'):
            fd = os.pidfd_open(pid, 0)
        else:
            libc = C.CDLL(None, use_errno=True)
            fd = libc.pidfd_open(pid, 0)
            if fd < 0:
                raise OSError(C.get_errno(), os.strerror(C.get_errno()))
    except ProcessLookupError:
        return 'gone'
    except (OSError, AttributeError) as error:
        return f'unavailable: {error}'
    try:
        state = process_state(pid, stamp)
        if state['status'] != 'running':
            return state['status']
        if hasattr(signal, 'pidfd_send_signal'):
            signal.pidfd_send_signal(fd, number)
        else:
            libc = C.CDLL(None, use_errno=True)
            if libc.pidfd_send_signal(fd, number, None, 0) != 0:
                raise OSError(C.get_errno(), os.strerror(C.get_errno()))
        return 'sent'
    except ProcessLookupError:
        return 'gone'
    except (OSError, AttributeError) as error:
        return f'unavailable: {error}'
    finally:
        os.close(fd)


def cleanup_owned(tracker, term_grace, kill_grace):
    outcomes = {}
    for number, grace, key in [(signal.SIGTERM, term_grace, 'term'), (signal.SIGKILL, kill_grace, 'kill')]:
        deadline = time.monotonic() + grace
        while True:
            pending = tracker.outstanding()
            for state in pending:
                pid = state['pid']
                item = outcomes.setdefault(pid, {'pid': pid, 'identity': tracker.seen.get(pid)})
                if key not in item:
                    item[key] = signal_owned(pid, tracker.seen[pid], number) if pid in tracker.seen else 'unavailable: no verified process identity'
            if not pending or time.monotonic() >= deadline:
                break
            time.sleep(.02)
    unresolved = tracker.outstanding()
    for pid, item in outcomes.items():
        item['final'] = process_state(pid, tracker.seen.get(pid))
        item['terminationVerified'] = item['final']['status'] in ('gone', 'zombie', 'reused')
    return list(outcomes.values()), unresolved

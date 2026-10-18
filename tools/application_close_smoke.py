#!/usr/bin/env python3
"""Natural-exit acceptance for a shipping app or window_close_smoke.dart bundle.

The caller supplies a real/private desktop. Profiles are always disposable.
No successful path calls terminate(), kill(), Dart exit(), or gtk_main_quit().
"""
import argparse
import ctypes as C
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import signal
import secrets
import re
import shlex
import subprocess
import sys
import time


class ObservationIncomplete(RuntimeError):
    pass


@contextmanager
def observation_span(event, name):
    """Optional in-memory diagnostic hook; the caller owns bounded buffering.

    Wall/CPU timestamps describe observer work, never application completion.
    Ordinary acceptance does not install a callback or collect these events.
    """
    if event is None:
        yield
        return
    def emit(phase):
        event({'name': name, 'phase': phase, 'monotonic_ns': time.monotonic_ns(),
               'threadCPU_ns': time.thread_time_ns()})
    emit('begin')
    try:
        yield
    finally:
        emit('end')


def snapshot_mapped_process(pid, folder, record, event=None):
    # Keep the historical mapped_ns endpoint after snapshot publication, but
    # expose detection before observer I/O. Neither timestamp is presentation.
    record['mapDetected_ns'] = time.monotonic_ns()
    try:
        with observation_span(event, 'mapped-process-maps-read'):
            maps = Path(f'/proc/{pid}/maps').read_text()
        with observation_span(event, 'mapped-process-maps-write'):
            (folder / 'maps').write_text(maps)
    except OSError as error:
        raise ObservationIncomplete('Owned mapped-process snapshot failed: ' + str(error)) from error
    record['mapped_ns'] = time.monotonic_ns()


class LoadedEngine:
    """Pin the owned process's mapped engine; hash after exit, outside timing."""
    def __init__(self, manifest):
        try:
            path = Path(manifest)
            with path.open('rb') as stream:
                elf = stream.read(4) == b'\x7fELF'
                stream.seek(0)
                if elf:
                    self.receipt = {}
                    self.expected = hashlib.file_digest(stream, 'sha256').hexdigest()
                else:
                    # Read historical evidence without requiring production
                    # build receipts. Current tests supply an official .so.
                    self.receipt = json.load(stream)
                    self.expected = self.receipt.get('packagedEngineSHA256', self.receipt['files']['libflutter_linux_gtk.so'])
        except (OSError, ValueError, KeyError, TypeError) as error:
            raise ObservationIncomplete('Engine receipt unavailable or invalid: ' + str(error)) from error
        if not isinstance(self.expected, str) or not re.fullmatch(r'[0-9a-f]{64}', self.expected):
            raise ObservationIncomplete('Invalid expected engine SHA256')
        self.fd = None
        self.path = None
        self.stat = None

    def capture(self, tracker):
        if self.fd is not None or tracker.root not in tracker.seen:
            return
        pid = tracker.root
        found = False
        try:
            rows = [line.split(None, 5) for line in Path(f'/proc/{pid}/maps').read_text().splitlines()]
            rows = [r for r in rows if len(r) == 6 and r[5].endswith('/libflutter_linux_gtk.so')]
            if not rows:
                return  # exec/loader phase; final acceptance still requires capture.
            found = True
            paths = {r[5] for r in rows}
            if len(paths) != 1:
                raise ObservationIncomplete('Multiple Flutter engines mapped')
            self.path = rows[0][5]
            fd = os.open(f'/proc/{pid}/root' + self.path, os.O_RDONLY | os.O_CLOEXEC)
            try:
                stat = os.fstat(fd)
                major, minor = (int(x, 16) for x in rows[0][3].split(':'))
                if stat.st_ino != int(rows[0][4]) or stat.st_dev != os.makedev(major, minor):
                    raise ObservationIncomplete('Engine descriptor does not match the mapped inode/device')
                if process_state(pid, tracker.seen[pid])['status'] != 'running':
                    return
                confinement = Path(f'/proc/{pid}/attr/current').read_text().strip()
                self.fd, self.stat, self.confinement = fd, stat, confinement
                fd = None
            finally:
                if fd is not None:
                    os.close(fd)
        except (OSError, ValueError, ObservationIncomplete) as error:
            if found and process_state(pid, tracker.seen[pid])['status'] == 'running':
                tracker.errors.append('Loaded-engine observation: ' + str(error))

    def finish(self, record, errors):
        if self.fd is None:
            errors.append('Loaded Flutter engine was not observed; selection verification incomplete')
            return
        try:
            h = hashlib.sha256()
            with os.fdopen(os.dup(self.fd), 'rb') as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    h.update(block)
            current = os.fstat(self.fd)
            if (current.st_size, current.st_mtime_ns, current.st_ctime_ns) != (self.stat.st_size, self.stat.st_mtime_ns, self.stat.st_ctime_ns):
                errors.append('Engine file changed after its mapping was captured')
            actual = h.hexdigest()
            record['loadedEngine'] = {'path': self.path, 'sha256': actual, 'expectedSHA256': self.expected, 'inode': self.stat.st_ino, 'device': self.stat.st_dev, 'mode': self.receipt.get('mode'), 'key': self.receipt.get('key'), 'confinement': self.confinement}
            if actual != self.expected:
                errors.append('Actual loaded engine differs from the expected official artifact')
        except OSError as error:
            errors.append('Loaded-engine hashing incomplete: ' + str(error))
        finally:
            os.close(self.fd)
            self.fd = None


# Test-only harness: preserve the production policy, but withhold its ready
# event. This exercises closing a live engine during native initialization
# independently of how quickly the production harness loads on this machine.
# It is deliberate readiness injection, not a reproduction of a WebKit stall.
PENDING_HARNESS = '''<!doctype html>
<html><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src busymark-render: 'self' 'wasm-unsafe-eval' 'unsafe-eval'; style-src 'unsafe-inline'; img-src data: blob:; font-src data:; connect-src 'none'; object-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'">
</head><body></body></html>
'''


def process_state(pid, expected=None):
    try:
        fields = Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()
        stamp, state = fields[19], fields[0]
        threads = int(fields[17])
        # /proc/PID/stat describes the thread-group leader. WebKit can leave
        # that leader a zombie while another thread is still running; waitpid
        # cannot reap the process yet. Keep observing/waiting for that group.
        finished = state == 'Z' and threads == 1
        status = 'reused' if expected is not None and stamp != expected else 'zombie' if finished else 'running'
        result = {'pid': pid, 'identity': stamp, 'status': status}
        if state == 'Z' and not finished:
            result.update(leaderState=state, threads=threads)
        return result
    except (FileNotFoundError, ProcessLookupError):
        return {'pid': pid, 'status': 'gone'}
    except (OSError, IndexError, ValueError) as error:
        return {'pid': pid, 'status': 'unavailable', 'error': str(error)}


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


def snap_command(instance, leaf, arguments, extra_environment=None):
    script = 'profile="$SNAP_USER_COMMON/' + leaf + '"; mkdir -p "$profile"/{home,config,data,state,cache,tmp}; exec env HOME="$profile/home" XDG_CONFIG_HOME="$profile/config" XDG_DATA_HOME="$profile/data" XDG_STATE_HOME="$profile/state" XDG_CACHE_HOME="$profile/cache" TMPDIR="$profile/tmp" BUSYMARK_SPELLING_INSTALL_ROOT="$profile/data/spelling" GST_REGISTRY="$profile/cache/gstreamer-registry.bin" '
    if extra_environment:
        script += shlex.join([k + '=' + v for k, v in extra_environment.items()]) + ' '
    script += '"$SNAP/busymark" ' + shlex.join(arguments)
    return ['snap', 'run', '--shell', instance, '-c', script]


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
        pending = [self.root] if self.root in self.seen else []
        # A successful read here discovers descendants even if their parent
        # exited before its first snapshot or a helper started a new session.
        try:
            pending.extend(process_children(os.getpid()))
        except ObservationIncomplete as error:
            self.errors.append(str(error))
        visited = set()
        while pending:
            pid = pending.pop()
            if pid in visited:
                continue
            visited.add(pid)
            state = process_state(pid, self.seen.get(pid))
            if state['status'] == 'unavailable':
                self.errors.append(str(state))
                self.unidentified[pid] = state
                continue
            if state['status'] in ('gone', 'reused'):
                continue
            self.unidentified.pop(pid, None)
            self.seen.setdefault(pid, state['identity'])
            if state['status'] == 'zombie':
                if pid != self.root:
                    try:
                        os.waitpid(pid, os.WNOHANG)
                    except ChildProcessError:
                        pass
                continue
            try:
                pending.extend(process_children(pid, self.seen[pid]))
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


class WindowAttributes(C.Structure):
    _fields_ = [(name, C.c_int) for name in ["x", "y", "width", "height", "border_width", "depth"]] + [
        ("visual", C.c_void_p), ("root", C.c_ulong),
        *[(name, C.c_int) for name in ["klass", "bit_gravity", "win_gravity", "backing_store"]],
        ("backing_planes", C.c_ulong), ("backing_pixel", C.c_ulong), ("save_under", C.c_int),
        ("colormap", C.c_ulong), ("map_installed", C.c_int), ("map_state", C.c_int),
        ("all_event_masks", C.c_long), ("your_event_mask", C.c_long), ("do_not_propagate_mask", C.c_long),
        ("override_redirect", C.c_int), ("screen", C.c_void_p),
    ]


class InputHints(C.Structure):
    _fields_ = [('flags', C.c_long), ('input', C.c_int), ('initial_state', C.c_int),
                ('icon_pixmap', C.c_ulong), ('icon_window', C.c_ulong),
                ('icon_x', C.c_int), ('icon_y', C.c_int), ('icon_mask', C.c_ulong),
                ('window_group', C.c_ulong)]


class AnyEvent(C.Structure):
    # Do not inspect key codes, characters, coordinates or unrelated windows.
    _fields_ = [('type', C.c_int), ('serial', C.c_ulong), ('send_event', C.c_int),
                ('display', C.c_void_p), ('window', C.c_ulong)]


class InputEvent(C.Union):
    _fields_ = [('any', AnyEvent), ('pad', C.c_long * 24)]


class WindowLifecycleEvent(C.Structure):
    # Create/Destroy/Map/Reparent notifications share event/parent then window.
    _fields_ = AnyEvent._fields_ + [('child', C.c_ulong)]


class InputCookie(C.Structure):
    _fields_ = AnyEvent._fields_[:-1] + [
        ('extension', C.c_int), ('evtype', C.c_int),
        ('cookie', C.c_uint), ('data', C.c_void_p),
    ]


class DeviceKeyPrefix(C.Structure):
    # Only inspect event type/window. Never inspect the key detail or values.
    _fields_ = AnyEvent._fields_[:-1] + [
        ('extension', C.c_int), ('evtype', C.c_int), ('time', C.c_ulong),
        ('deviceid', C.c_int), ('sourceid', C.c_int), ('unused_detail', C.c_int),
        ('root', C.c_ulong), ('event', C.c_ulong), ('child', C.c_ulong),
    ]


class DeviceEventMask(C.Structure):
    _fields_ = [('deviceid', C.c_int), ('mask_len', C.c_int),
                ('mask', C.POINTER(C.c_ubyte))]


class InputError(C.Structure):
    _fields_ = [('type', C.c_int), ('display', C.c_void_p),
                ('resource', C.c_ulong), ('serial', C.c_ulong),
                ('error_code', C.c_ubyte), ('request_code', C.c_ubyte),
                ('minor_code', C.c_ubyte)]


class OwnedInputAudit:
    """Observe event counts only in the identified app's own window subtree.

    Select core and XI2 keys on this observer's separate X connection. GTK
    consumes XI2 keys, which a core-only selection can miss. No root/raw input
    listener, input grab, key values, or replacement application handler.
    """
    def __init__(self, desktop, window):
        self.desktop = desktop
        self.x = desktop.x
        self.display = desktop.display
        self.windows = set()
        self.root_window = window.get_xid()
        self.window_updates = []
        self.refresh_required = False
        self.retired = False
        self.events = []
        self.key_presses = self.key_releases = self.activeSamples = self.samples = 0
        self.focusSamples = 0
        self.errors = []
        x = self.x
        x.XSelectInput.argtypes = [C.c_void_p, C.c_ulong, C.c_long]
        x.XPending.argtypes = [C.c_void_p]
        x.XPending.restype = C.c_int
        x.XNextEvent.argtypes = [C.c_void_p, C.POINTER(InputEvent)]
        x.XSync.argtypes = [C.c_void_p, C.c_int]
        x.XSetErrorHandler.argtypes = [C.c_void_p]
        x.XSetErrorHandler.restype = C.c_void_p
        x.XGetInputFocus.argtypes = [C.c_void_p, C.POINTER(C.c_ulong), C.POINTER(C.c_int)]
        self._prepare_xi2()
        self._refresh_windows()

    def _refresh_windows(self):
        """Track later-realized children without selecting root/raw input.

        Lifecycle delivery is polled: report the refresh times rather than
        implying observation of input before a new window was selected.
        """
        x = self.x
        handler_type = C.CFUNCTYPE(C.c_int, C.c_void_p, C.POINTER(InputError))

        def error(_display, event):
            self.errors.append({'code': event.contents.error_code,
                                'request': event.contents.request_code})
            return 0

        handler = handler_type(error)
        previous = x.XSetErrorHandler(C.cast(handler, C.c_void_p))
        try:
            bits = (C.c_ubyte * 1)((1 << 2) | (1 << 3))
            mask = DeviceEventMask(1, 1, bits)  # XIAllMasterDevices; keys only.
            pending, current = [self.root_window], set()
            while pending:
                xid = pending.pop()
                if xid in current:
                    continue
                if len(current) >= 1024:
                    raise ObservationIncomplete('Owned input window bound exceeded')
                current.add(xid)
                if xid not in self.windows:
                    x.XSelectInput(self.display, xid, (1 << 0) | (1 << 1) | (1 << 21) | (1 << 19) | (1 << 17))
                    if self.xi.XISelectEvents(self.display, xid, C.byref(mask), 1) != 0:
                        raise ObservationIncomplete('Owned XInput2 window selection failed')
                root, parent, count = C.c_ulong(), C.c_ulong(), C.c_uint()
                children = C.POINTER(C.c_ulong)()
                if x.XQueryTree(self.display, xid, C.byref(root), C.byref(parent), C.byref(children), C.byref(count)):
                    pending.extend(children[:count.value])
                    if children:
                        x.XFree(children)
                else:
                    raise ObservationIncomplete('Owned window subtree enumeration failed')
            x.XSync(self.display, 0)
            if current != self.windows and len(self.window_updates) < 64:
                self.window_updates.append({'observed_ns': time.monotonic_ns(),
                                            'added': len(current - self.windows),
                                            'removed': len(self.windows - current)})
            self.windows = current
            self.refresh_required = False
        finally:
            x.XSetErrorHandler(previous)
        if self.errors:
            raise ObservationIncomplete('Owned input observation unavailable: ' + repr(self.errors))

    def _prepare_xi2(self):
        x = self.x
        try:
            self.xi = C.CDLL('libXi.so.6')
            opcode, first, error_base = C.c_int(), C.c_int(), C.c_int()
            x.XQueryExtension.argtypes = [C.c_void_p, C.c_char_p, C.POINTER(C.c_int), C.POINTER(C.c_int), C.POINTER(C.c_int)]
            if not x.XQueryExtension(self.display, b'XInputExtension', C.byref(opcode), C.byref(first), C.byref(error_base)):
                raise ObservationIncomplete('Owned keyboard observation requires XInput2')
            self.xi_opcode = opcode.value
            self.xi.XIQueryVersion.argtypes = [C.c_void_p, C.POINTER(C.c_int), C.POINTER(C.c_int)]
            major, minor = C.c_int(2), C.c_int(0)
            if self.xi.XIQueryVersion(self.display, C.byref(major), C.byref(minor)) != 0 or major.value < 2:
                raise ObservationIncomplete('XInput2 version 2 keyboard observation unavailable')
            self.xi.XISelectEvents.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(DeviceEventMask), C.c_int]
            x.XGetEventData.argtypes = [C.c_void_p, C.POINTER(InputCookie)]
            x.XFreeEventData.argtypes = [C.c_void_p, C.POINTER(InputCookie)]
        except (OSError, AttributeError) as failure:
            raise ObservationIncomplete('Owned XInput2 keyboard observation unavailable: ' + str(failure)) from failure

    def poll(self):
        self.samples += 1
        desktop = self.desktop
        # Drain structure notifications first, so focus queries include a FlView
        # realized after the initial top-level was found. A destroyed root must
        # not be queried again during normal process exit.
        drained = 0
        while self.x.XPending(self.display):
            drained += 1
            if drained > 4096:
                if 'Owned event queue overflow' not in self.errors:
                    self.errors.append('Owned event queue overflow')
                break
            event = InputEvent()
            self.x.XNextEvent(self.display, C.byref(event))
            self.observe(event)
        if self.refresh_required and not self.retired:
            self._refresh_windows()
        atom, form, count, remaining = C.c_ulong(), C.c_int(), C.c_ulong(), C.c_ulong()
        data = C.POINTER(C.c_ubyte)()
        self.x.XGetWindowProperty(self.display, desktop.root,
                                 desktop.atom('_NET_ACTIVE_WINDOW'), 0, 1, 0, 0,
                                 C.byref(atom), C.byref(form), C.byref(count),
                                 C.byref(remaining), C.byref(data))
        active = C.cast(data, C.POINTER(C.c_ulong))[0] if count.value and form.value == 32 else None
        if data:
            self.x.XFree(data)
        if active in self.windows:
            self.activeSamples += 1
        focused, revert = C.c_ulong(), C.c_int()
        if not self.x.XGetInputFocus(self.display, C.byref(focused), C.byref(revert)):
            if 'XGetInputFocus failed' not in self.errors:
                self.errors.append('XGetInputFocus failed')
        elif focused.value in self.windows:
            self.focusSamples += 1

    def observe(self, event):
        if event.any.type == 35:  # GenericEvent, not a core XAnyEvent window.
            cookie = C.cast(C.byref(event), C.POINTER(InputCookie)).contents
            if cookie.extension != self.xi_opcode or cookie.evtype not in (2, 3):
                return
            if not self.x.XGetEventData(self.display, C.byref(cookie)):
                self.errors.append('Owned XInput2 key-event data unavailable')
                return
            try:
                if not cookie.data:
                    self.errors.append('Owned XInput2 key-event data missing')
                    return
                key = C.cast(cookie.data, C.POINTER(DeviceKeyPrefix)).contents
                if key.event not in self.windows:
                    return
                self._key(key.evtype, bool(key.send_event), 'XI2')
            finally:
                self.x.XFreeEventData(self.display, C.byref(cookie))
            return
        if event.any.window not in self.windows:
            return
        if event.any.type in (16, 17, 19, 21):
            lifecycle = C.cast(C.byref(event), C.POINTER(WindowLifecycleEvent)).contents
            if event.any.type == 17 and lifecycle.child == self.root_window:
                self.retired = True
                self.windows.clear()
            self.refresh_required = True
            return
        if event.any.type in (2, 3):
            self._key(event.any.type, bool(event.any.send_event), 'core')
            return
        kinds = {9: 'focus-in', 10: 'focus-out'}
        if event.any.type in kinds and len(self.events) < 16:
            self.events.append({'kind': kinds[event.any.type],
                                'synthetic': bool(event.any.send_event),
                                'observed_ns': time.monotonic_ns()})

    def _key(self, kind, synthetic, source):
        if kind == 2:
            self.key_presses += 1
        if kind == 3:
            self.key_releases += 1
        if len(self.events) < 16:
            self.events.append({'kind': 'key-press' if kind == 2 else 'key-release',
                                'synthetic': synthetic, 'source': source,
                                'observed_ns': time.monotonic_ns()})

    def result(self):
        self.poll()
        return {'keyPresses': self.key_presses, 'keyReleases': self.key_releases,
                'activeSamples': self.activeSamples, 'focusSamples': self.focusSamples,
                'samples': self.samples,
                'events': self.events, 'errors': self.errors,
                'windowUpdates': self.window_updates,
                'rootWindow': self.root_window,
                'windowTracking': 'Owned subtree lifecycle notifications; newly realized children selected when polled. Input before a child subscription cannot be reconstructed.',
                'keyboardMechanism': 'owned-window XInput2 and core events',
                'scope': 'Identified owned X11 window subtree only; no key values, text, global input or unrelated window identities.'}


class Desktop:
    def __init__(self):
        import gi
        gi.require_version("Gdk", "3.0")
        gi.require_version("GdkX11", "3.0")
        from gi.repository import Gdk, GdkX11
        self.Gdk, self.GdkX11 = Gdk, GdkX11
        self.x = C.CDLL("libX11.so.6")
        x = self.x
        x.XOpenDisplay.restype = C.c_void_p
        self.display = None
        x.XDefaultRootWindow.argtypes = [C.c_void_p]
        x.XDefaultRootWindow.restype = C.c_ulong
        x.XInternAtom.argtypes = [C.c_void_p, C.c_char_p, C.c_int]
        x.XInternAtom.restype = C.c_ulong
        x.XGetWindowProperty.argtypes = [C.c_void_p, C.c_ulong, C.c_ulong, C.c_long, C.c_long, C.c_int, C.c_ulong, C.POINTER(C.c_ulong), C.POINTER(C.c_int), C.POINTER(C.c_ulong), C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ubyte))]
        x.XQueryTree.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong), C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ulong)), C.POINTER(C.c_uint)]
        x.XGetWindowAttributes.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(WindowAttributes)]
        x.XFree.argtypes = [C.c_void_p]
        x.XFlush.argtypes = [C.c_void_p]
        x.XCloseDisplay.argtypes = [C.c_void_p]
        self.display = x.XOpenDisplay(None)
        if not self.display:
            raise RuntimeError("An authenticated X11 desktop is required")
        try:
            self.root = x.XDefaultRootWindow(self.display)
        except BaseException:
            self.dispose()
            raise

    def dispose(self):
        display, self.display = self.display, None
        if display:
            self.x.XCloseDisplay(display)

    def atom(self, name):
        return self.x.XInternAtom(self.display, name.encode(), 0)

    def window(self, pid, require_mapped=True, require_normal=False):
        pending = [self.root]
        while pending:
            xid = pending.pop()
            a, f, n, remaining = C.c_ulong(), C.c_int(), C.c_ulong(), C.c_ulong()
            data = C.POINTER(C.c_ubyte)()
            self.x.XGetWindowProperty(self.display, xid, self.atom("_NET_WM_PID"), 0, 1, 0, 0, C.byref(a), C.byref(f), C.byref(n), C.byref(remaining), C.byref(data))
            owner = C.cast(data, C.POINTER(C.c_ulong))[0] if n.value and f.value == 32 else None
            if data:
                self.x.XFree(data)
            if owner == pid:
                normal = True
                if require_normal:
                    data = C.POINTER(C.c_ubyte)()
                    self.x.XGetWindowProperty(self.display, xid, self.atom('_NET_WM_WINDOW_TYPE'), 0, 32, 0, 0, C.byref(a), C.byref(f), C.byref(n), C.byref(remaining), C.byref(data))
                    normal = bool(n.value and f.value == 32 and self.atom('_NET_WM_WINDOW_TYPE_NORMAL') in C.cast(data, C.POINTER(C.c_ulong))[:n.value])
                    if data:
                        self.x.XFree(data)
                w = self.GdkX11.X11Window.foreign_new_for_display(self.Gdk.Display.get_default(), xid)
                attributes = WindowAttributes()
                if normal and w and self.x.XGetWindowAttributes(self.display, xid, C.byref(attributes)) and (not require_mapped or attributes.map_state == 2):
                    return w
            root, parent, count = C.c_ulong(), C.c_ulong(), C.c_uint()
            children = C.POINTER(C.c_ulong)()
            if self.x.XQueryTree(self.display, xid, C.byref(root), C.byref(parent), C.byref(children), C.byref(count)):
                pending.extend(children[:count.value])
                if children:
                    self.x.XFree(children)
        return None

    def isolate_input(self, pid):
        """Keep only this benchmark window passive; never change global focus."""
        return self._observe_input(pid, passive=True)

    def audit_input(self, pid):
        """Observe owned input without changing normal focus or window hints."""
        return self._observe_input(pid, passive=False)

    def _observe_input(self, pid, passive):
        # GTK's hidden application leader also has _NET_WM_PID. It is not the
        # future content window and cannot establish coverage of its siblings.
        window = self.window(pid, require_mapped=False, require_normal=True)
        if window is None:
            return None
        attrs = WindowAttributes()
        if not self.x.XGetWindowAttributes(self.display, window.get_xid(), C.byref(attrs)) or attrs.map_state == 2:
            raise ObservationIncomplete('Owned input observation was not established before window mapping')
        self.x.XGetWMHints.argtypes = [C.c_void_p, C.c_ulong]
        self.x.XGetWMHints.restype = C.POINTER(InputHints)
        self.x.XSetWMHints.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(InputHints)]
        if passive:
            original = self.x.XGetWMHints(self.display, window.get_xid())
            hints = InputHints()
            if original:
                C.memmove(C.byref(hints), original, C.sizeof(hints))
                self.x.XFree(original)
            hints.flags |= 1  # ICCCM InputHint; retain all existing icon/state hints.
            hints.input = 0
            self.x.XSetWMHints(self.display, window.get_xid(), C.byref(hints))
        watch = OwnedInputAudit(self, window)
        if not self.x.XGetWindowAttributes(self.display, window.get_xid(), C.byref(attrs)) or attrs.map_state == 2:
            raise ObservationIncomplete('Window mapped before owned input observation was confirmed')
        watch.applied_ns = time.monotonic_ns()
        self.input_audit = watch
        self.passive_input = passive
        return watch

    def close(self, w):
        audit = getattr(self, 'input_audit', None)
        if audit is not None:
            check_owned_input(audit.result(), require_passive=getattr(self, 'passive_input', True))
        class Data(C.Union):
            _fields_ = [("l", C.c_long * 5)]
        class Message(C.Structure):
            _fields_ = [("type", C.c_int), ("serial", C.c_ulong), ("send_event", C.c_int), ("display", C.c_void_p), ("window", C.c_ulong), ("message_type", C.c_ulong), ("format", C.c_int), ("data", Data)]
        class Event(C.Union):
            _fields_ = [("client", Message), ("pad", C.c_long * 24)]
        self.x.XSendEvent.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_long, C.POINTER(Event)]
        e = Event()
        e.client.type, e.client.display, e.client.window = 33, self.display, w.get_xid()
        e.client.message_type, e.client.format = self.atom("WM_PROTOCOLS"), 32
        e.client.data.l[0] = self.atom("WM_DELETE_WINDOW")
        if not self.x.XSendEvent(self.display, w.get_xid(), 0, 0, C.byref(e)):
            raise RuntimeError("Owned window rejected close request")
        self.x.XFlush(self.display)

    def video_sample(self, w):
        # Root-window pixels can belong to an unrelated overlapping window.
        # Confirm decoded changes within this identified application drawable.
        p = self.Gdk.pixbuf_get_from_window(w, 210, 210, 600, 300)
        if p is None:
            return None
        pixels, stride, channels = p.get_pixels(), p.get_rowstride(), p.get_n_channels()
        samples = [pixels[y * stride + x * channels:y * stride + x * channels + 3] for y in range(0, 300, 8) for x in range(0, 600, 8)]
        saturated = sum(max(v) - min(v) > 80 for v in samples)
        return hashlib.sha256(b"".join(samples)).hexdigest() if saturated > len(samples) // 4 else None


def check_input_isolation(result):
    check_owned_input(result, require_passive=True)


def check_owned_input(result, require_passive=False):
    if result['errors']:
        raise ObservationIncomplete('Owned input observation incomplete: ' + repr(result['errors']))
    if result['keyPresses'] or result['keyReleases']:
        raise RuntimeError('Unexpected keyboard input reached the owned benchmark window')
    if 'focusSamples' not in result:
        raise ObservationIncomplete('Core keyboard focus observation missing')
    if require_passive and result['focusSamples']:
        raise ObservationIncomplete('Benchmark window acquired keyboard focus despite passive input hint')
    if require_passive and result['activeSamples']:
        raise ObservationIncomplete('Benchmark window became active despite passive input hint; activation is distinct from core keyboard focus')


def accepted(record):
    return record.get("exitCode") == 0 and not record.get("error") and not record.get("survivingChildren") and not record.get("cleanupRequired") and not record.get("verificationIncomplete") and not record.get("unresolvedSurvivors") and not record.get('cleanupErrors') and not record.get('reportingError')


def seed_local_settings(profile, source):
    """Seed only a synthetic local-settings fixture in an isolated profile."""
    directory = Path(profile).resolve()
    for leaf in ['config', 'dconf']:
        directory /= leaf
        if directory.is_symlink():
            raise RuntimeError('Refusing a symlink in the isolated DConf fixture path')
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    destination = directory / 'user'
    if destination.is_symlink():
        raise RuntimeError('Refusing a symlink for the isolated DConf fixture')
    contents = Path(source).read_bytes()
    try:
        fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    except FileExistsError:
        if destination.read_bytes() != contents:
            raise RuntimeError('Refusing to replace a changed isolated DConf fixture')
        return
    with os.fdopen(fd, 'wb') as stream:
        stream.write(contents)


def run_case(command, folder, profile, scenario, timeout, plain=False, video=None, snap_instance=None, document=None, child_grace=5, term_grace=2, kill_grace=3, engine_manifest=None, isolate_input=False, audit_input=False, observer_event=None, settings_schema_dir=None, portal_bus_address=None, settings_backend="memory", local_settings_db=None):
    if isolate_input and audit_input:
        raise ValueError('Select passive isolation or normal-focus input audit')
    if isolate_input and not plain:
        raise ValueError('Input isolation applies only to plain startup observation')
    record = {"launch_ns": time.monotonic_ns(), "scenario": scenario,
              "command": command, "plainShippingExecutable": plain,
              "observationInterpreter": sys.executable, "exitCode": None,
              "applicationStarted": False}
    tracker = desktop = process = log = probe = temporary_alias = alias_identity = None
    phase = 'setup'
    def cleanup_error(stage, error):
        record.setdefault('cleanupErrors', []).append({'stage': stage, 'error': repr(error)})
    try:
        folder.mkdir()  # Never overwrite an earlier case or result.
        environment = os.environ.copy()
        for key, name in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"), ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("TMPDIR", "tmp")]:
            p = profile / name
            p.mkdir(parents=True, exist_ok=True)
            environment[key] = str(p)
        # Unix-domain socket paths must not inherit a long evidence-directory name.
        temporary_alias = Path('/tmp') / ('bm-close-' + secrets.token_hex(8))
        temporary_alias.symlink_to(profile / 'tmp', target_is_directory=True)
        alias_identity = temporary_alias.lstat()
        environment['TMPDIR'] = str(temporary_alias)
        environment["BUSYMARK_RELEASE_SMOKE"] = "1"
        environment["BUSYMARK_SPELLING_INSTALL_ROOT"] = str(profile / "data/spelling")
        environment["GST_REGISTRY"] = str(profile / "cache/gstreamer-registry.bin")
        if scenario == 'pending-initialization' and not plain:
            assets = profile / 'pending-initialization-assets'
            assets.mkdir(exist_ok=True)
            (assets / 'harness.html').write_text(PENDING_HARNESS)
            environment['BUSYMARK_VISUALIZATION_ASSETS'] = str(assets)
        if not plain:
            environment['BUSYMARK_NATIVE_TRACE'] = '1'
        if settings_schema_dir is not None:
            environment["GSETTINGS_SCHEMA_DIR"] = str(Path(settings_schema_dir).resolve())
            environment["GSETTINGS_BACKEND"] = settings_backend
        if portal_bus_address is not None:
            environment["DBUS_SESSION_BUS_ADDRESS"] = portal_bus_address
        application_profile = profile
        if snap_instance:
            # snap-confine needs the real account home. The application gets an
            # isolated profile only after the normal confined launcher has run.
            environment = os.environ.copy()
            leaf = 'c-' + hashlib.sha256(str(profile).encode()).hexdigest()[:12]
            application_profile = Path.home() / 'snap' / snap_instance / 'common' / leaf
        report = folder / "application.json"
        arguments = [] if plain else [str(report), scenario] + ([str(video)] if scenario == "video" else [str(document)] if scenario == 'reopen' else [])
        if snap_instance:
            extra = {}
            if not plain:
                # The real account HOME is restored for snap-confine above, so
                # transfer the fixture opt-in only after entering confinement.
                extra['BUSYMARK_RELEASE_SMOKE'] = '1'
                extra['BUSYMARK_NATIVE_TRACE'] = '1'
            if portal_bus_address is not None:
                extra["DBUS_SESSION_BUS_ADDRESS"] = portal_bus_address
            if settings_schema_dir is not None:
                extra['GSETTINGS_SCHEMA_DIR'] = str(Path(settings_schema_dir).resolve())
                extra['GSETTINGS_BACKEND'] = settings_backend
            if scenario == 'pending-initialization' and not plain:
                extra['BUSYMARK_VISUALIZATION_ASSETS'] = str(profile / 'pending-initialization-assets')
            command = snap_command(snap_instance, leaf, arguments, extra)
            arguments = []

        record['command'] = command + arguments
        if scenario == 'pending-initialization' and not plain:
            record['controlledPendingHarness'] = True
        phase = 'observer initialization'
        if local_settings_db is not None:
            seed_local_settings(application_profile, local_settings_db)
        probe = LoadedEngine(engine_manifest) if engine_manifest is not None else None
        tracker = ChildTracker()
        tracker.engine = probe
        desktop = Desktop() if plain or scenario == "video" or audit_input else None
        phase = 'log opening'
        log = (folder / 'application.log').open('x')
        phase = 'process creation'
        record['spawnRequest_ns'] = time.monotonic_ns()
        record['launchAttempted'] = True
        process = subprocess.Popen(record['command'], env=environment, stdout=log,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        record['applicationStarted'] = True
        record['spawnReturned_ns'] = time.monotonic_ns()
        record['pid'] = process.pid
        tracker.root = process.pid
        stamp = identity(process.pid)
        if stamp is not None:
            tracker.seen[process.pid] = stamp
        else:
            tracker.errors.append('Application identity unavailable after launch')
        phase = 'application observation'
        deadline = time.monotonic() + timeout
        close_sent, first_video = False, None
        while process.poll() is None and time.monotonic() < deadline:
            with observation_span(observer_event, 'child-and-input-scan'):
                tracker.scan()
            if tracker.errors:
                raise ObservationIncomplete("Child observation is incomplete")
            if (isolate_input or audit_input) and tracker.input_audit is None:
                observe = desktop.isolate_input if isolate_input else desktop.audit_input
                with observation_span(observer_event, 'input-observation-setup'):
                    tracker.input_audit = observe(process.pid)
            if plain and not close_sent:
                with observation_span(observer_event, 'owned-window-query'):
                    w = desktop.window(process.pid)
                if w:
                    if tracker.input_audit is not None and tracker.input_audit.root_window != w.get_xid():
                        raise ObservationIncomplete('Input audit is attached to a different owned window')
                    # BusyMark maps its top-level only after FlView first-frame.
                    snapshot_mapped_process(process.pid, folder, record, observer_event)
                    if snap_instance:
                        confinement = Path(f"/proc/{process.pid}/attr/current").read_text().strip()
                        record['confinement'] = confinement
                        if f'snap.{snap_instance}.busymark' not in confinement or '(enforce)' not in confinement:
                            raise RuntimeError('Expected genuine strict Snap confinement')
                    if isolate_input and tracker.input_audit is None:
                        raise ObservationIncomplete('No owned pre-map input observation')
                    with observation_span(observer_event, 'owned-content-probe-and-close'):
                        desktop.close(w)
                    record["closeRequestSent_ns"] = time.monotonic_ns()
                    close_sent = True
            if report.exists():
                try:
                    status = json.loads(report.read_text())
                except json.JSONDecodeError:
                    status = {}
                if status.get("phase") == "failed":
                    raise RuntimeError(status.get("error", "Application probe failed"))
                if status.get("phase") == "awaiting-video":
                    w = desktop.window(process.pid)
                    sample = desktop.video_sample(w) if w else None
                    if sample and first_video and sample != first_video:
                        Path(str(report) + ".video-confirmed").touch()
                        record["decodedChangingVideoObserved"] = True
                    if sample:
                        first_video = sample
            time.sleep(.05)
        if process.poll() is None:
            raise TimeoutError("Natural application exit deadline expired")
        record["exitCode"] = process.returncode
        record["exitObserved_ns"] = time.monotonic_ns()
        if plain and not close_sent:
            raise RuntimeError("Process exited before a verified owned-window close request")
        if isolate_input or audit_input:
            if tracker.input_audit is None:
                raise ObservationIncomplete('No owned input observation')
            record['ownedInput'] = tracker.input_audit.result()
            check_owned_input(record['ownedInput'], require_passive=isolate_input)
        log.flush()
        application_log = (folder / 'application.log').read_text(errors='replace')
        record['messengerCleanupWarnings'] = application_log.count('Attempted to set message handler on an FlBinaryMessenger without an engine')
        for failure in ['Failed to shutdown Flutter engine']:
            if failure in application_log:
                raise RuntimeError(failure)
        if scenario == 'pending-initialization' and 'visualization-shutdown initPending=1' not in application_log:
            raise RuntimeError('Initialization finished before native shutdown; pending-initialization boundary was not exercised')
        if plain:
            recovery = application_profile / 'data/io.busystack.busymark/recovery.json'
            if recovery.exists():
                clean_shutdown = json.loads(recovery.read_text())['cleanShutdown']
                record['durableCleanShutdown'] = clean_shutdown
                if not clean_shutdown:
                    raise RuntimeError('Durable clean-shutdown checkpoint missing')
        if not plain:
            status = json.loads(report.read_text()) if report.exists() else {}
            record["application"] = status
            if status.get("phase") != "close-requested":
                raise RuntimeError("Missing normal-close application checkpoint")
            if status.get("document") and status.get("expectedText") is not None:
                if Path(status["document"]).read_text() != status["expectedText"]:
                    raise RuntimeError("Save/discard produced incorrect document content")
            recovery = Path(status["applicationSupport"]) / "recovery.json"
            if not json.loads(recovery.read_text())["cleanShutdown"]:
                raise RuntimeError("Durable clean-shutdown checkpoint missing")
        child_deadline = time.monotonic() + child_grace
        while tracker.outstanding(children_only=True) and time.monotonic() < child_deadline:
            time.sleep(.02)
        record["survivingChildren"] = tracker.outstanding(children_only=True)

    except BaseException as error:
        record['failurePhase'] = phase
        record['errorType'] = type(error).__name__
        record['error'] = f'{phase.capitalize()} failed ({type(error).__name__}): {error}'
        if isinstance(error, ImportError):
            record['error'] += '; use /usr/bin/python3 with system PyGObject/GdkX11'
        if process is None:
            record['launchSkipped'] = True
        if isinstance(error, ObservationIncomplete) or phase == 'observer initialization' or not isinstance(error, Exception):
            record.setdefault('verificationIncomplete', []).append(str(error))
        if process is not None:
            record['exitCode'] = process.poll()
    finally:
        if tracker is not None:
            # Classify before cleanup. A successful cleanup cannot turn any
            # failed launch, fatal exit, hang or incomplete observation into a pass.
            try:
                pending = tracker.outstanding()
                if pending:
                    record['cleanupRequired'] = pending
                record['observedIdentities'] = dict(tracker.seen)
                record['cleanupOutcomes'], record['unresolvedSurvivors'] = cleanup_owned(tracker, term_grace, kill_grace)
            except BaseException as error:
                cleanup_error('owned processes', error)
                record['unresolvedSurvivors'] = [{'status': 'unavailable', 'error': repr(error)}]
            if process is not None:
                try:
                    if process.poll() is not None:
                        process.wait()
                except BaseException as error:
                    cleanup_error('process reap', error)
            if (isolate_input or audit_input) and tracker.input_audit is not None:
                try:
                    record['ownedInput'] = tracker.input_audit.result()
                    record['inputAuditEstablished_ns'] = tracker.input_audit.applied_ns
                    record['inputObservationMode'] = 'passive-hint' if isolate_input else 'normal-focus-audit'
                    if isolate_input:
                        record['inputHintApplied_ns'] = tracker.input_audit.applied_ns
                except BaseException as error:
                    cleanup_error('input audit', error)
            try:
                tracker.close()
            except BaseException as error:
                cleanup_error('tracker close', error)
            if tracker.errors:
                record.setdefault('verificationIncomplete', []).extend(tracker.errors)
        if probe is not None:
            try:
                errors = []
                probe.finish(record, errors)
                if snap_instance and record.get('loadedEngine', {}).get('confinement') != f'snap.{snap_instance}.busymark (enforce)':
                    errors.append('Expected genuine strict Snap confinement for the mapped engine')
                if errors:
                    record.setdefault('verificationIncomplete', []).extend(errors)
            except BaseException as error:
                cleanup_error('engine observation', error)
        if desktop is not None:
            try:
                desktop.dispose()
            except BaseException as error:
                cleanup_error('desktop close', error)
        if log is not None:
            try:
                log.close()
            except BaseException as error:
                cleanup_error('log close', error)
        if alias_identity is not None:
            try:
                current = temporary_alias.lstat()
                if (current.st_dev, current.st_ino) != (alias_identity.st_dev, alias_identity.st_ino):
                    raise RuntimeError('Temporary alias identity changed; refusing to unlink')
                temporary_alias.unlink()
            except BaseException as error:
                cleanup_error('temporary alias', error)
        try:
            with (folder / 'result.json').open('x') as output:
                output.write(json.dumps(record, indent=2))
        except BaseException as error:
            record['reportingError'] = repr(error)
            record.setdefault('error', 'Close observer result publication failed')
            print(f'Close observer result publication failed for {folder}: {error!r}; original failure: {record.get("error")}', file=sys.stderr, flush=True)
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cycles", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--fresh-profile", action="store_true", help="Use a new isolated application and graphics cache for each case, retaining it for its reopen check")
    parser.add_argument("--isolate-input", action="store_true", help="Plain X11 startup only: apply an owned pre-map passive input hint and reject focus/key interference; never record key values")
    parser.add_argument("--audit-input", action="store_true", help="Observe owned X11 key-event counts without changing normal focus/window hints; unexpected input or incomplete observation fails")
    parser.add_argument("--plain", action="store_true", help="Test the unmodified shipping executable using WM_DELETE_WINDOW")
    parser.add_argument("--snap-instance", help="Owned disposable parallel instance, e.g. busymark_close")
    parser.add_argument("--snap-fixture", action="store_true", help="The disposable instance contains the compiled window_close_smoke target; require output in its common directory")
    parser.add_argument("--settings-backend", choices=["memory", "dconf"], default="memory")
    parser.add_argument("--local-settings-db", type=Path, help="Offline compiled DConf fixture copied only into the isolated profile")
    parser.add_argument("--portal-bus-address", help="Owned isolated bus used only after the normal confined launcher")
    parser.add_argument("--settings-schema-dir", type=Path, help="Controlled portal fixture local schema directory (memory backend)")
    parser.add_argument("--scenarios", nargs="+", choices=["plain", "visualization", "video", "pending-initialization", "dirty-save", "dirty-discard", "dirty-cancel", "portal-settings"], default=["plain", "visualization", "pending-initialization", "dirty-save", "dirty-discard", "dirty-cancel"])
    parser.add_argument("--video", type=Path)
    parser.add_argument("--expected-engine", "--engine-manifest", dest='engine_manifest', type=Path, help="Optional test-only expected engine .so (or historical evidence JSON); hash actual mapped file after exit")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if (args.portal_bus_address or args.settings_schema_dir or args.local_settings_db or args.settings_backend != "memory") and (
            args.plain or args.scenarios != ['portal-settings']):
        parser.error('Controlled portal inputs require only the portal-settings fixture')
    if args.video:
        args.video = args.video.resolve()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if args.snap_instance:
        if not re.fullmatch(r'busymark_[a-z0-9]{1,10}', args.snap_instance) or command:
            parser.error('An explicitly named disposable parallel Snap instance is required, without a command')
        if args.snap_fixture:
            if args.plain or not args.engine_manifest:
                parser.error('A confined compiled fixture requires --engine-manifest and cannot use --plain')
        else:
            args.plain = True
    elif args.snap_fixture:
        parser.error('--snap-fixture requires an explicitly named disposable --snap-instance')
    if (not command and not args.snap_instance) or args.cycles < 1 or ("video" in args.scenarios and not args.video):
        parser.error("Command, positive cycle count and requested video fixture are required")
    if args.isolate_input and not args.plain:
        parser.error('Input isolation requires a plain startup case, not an interaction fixture')
    if args.isolate_input and args.audit_input:
        parser.error('Select --audit-input or --isolate-input, not both')
    root = args.output.resolve()
    if args.snap_fixture and not root.is_relative_to((Path.home() / 'snap' / args.snap_instance / 'common').resolve()):
        parser.error('Confined fixture output must be inside the disposable instance common directory')
    root.mkdir(parents=True)  # Never overwrite previous evidence.
    records = []
    scenarios = ["plain"] if args.plain else args.scenarios
    for cycle in range(args.cycles):
        for scenario in scenarios:
            profile = root / "profiles" / f"{cycle}-{scenario}" if args.fresh_profile else root / "profile"
            record = run_case(command, root / f"{cycle}-{scenario}", profile, scenario, args.timeout, args.plain, args.video, args.snap_instance, engine_manifest=args.engine_manifest, isolate_input=args.isolate_input, audit_input=args.audit_input, settings_schema_dir=args.settings_schema_dir, portal_bus_address=args.portal_bus_address, settings_backend=args.settings_backend, local_settings_db=args.local_settings_db)
            records.append(record)
            print(json.dumps({"cycle": cycle, "scenario": scenario, "exitCode": record.get("exitCode"), "accepted": accepted(record), "error": record.get("error")}), flush=True)
            if record.get('unresolvedSurvivors') or record.get('verificationIncomplete'):
                break
            document = record.get('application', {}).get('document')
            if not args.plain and document and accepted(record):
                reopened = run_case(command, root / f'{cycle}-{scenario}-reopen', profile, 'reopen', args.timeout, snap_instance=args.snap_instance, document=Path(document), engine_manifest=args.engine_manifest, audit_input=args.audit_input, settings_schema_dir=args.settings_schema_dir, portal_bus_address=args.portal_bus_address, settings_backend=args.settings_backend, local_settings_db=args.local_settings_db)
                records.append(reopened)
                print(json.dumps({'cycle': cycle, 'scenario': scenario + '-reopen', 'exitCode': reopened.get('exitCode'), 'accepted': accepted(reopened), 'error': reopened.get('error')}), flush=True)
                if reopened.get('unresolvedSurvivors') or reopened.get('verificationIncomplete'):
                    break
        if records[-1].get('unresolvedSurvivors') or records[-1].get('verificationIncomplete'):
            break
    summary = {"runs": len(records), "failures": sum(not accepted(r) for r in records), "records": records}
    (root / "summary.json").write_text(json.dumps(summary, indent=2))
    return 1 if summary["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())

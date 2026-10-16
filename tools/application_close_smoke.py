#!/usr/bin/env python3
"""Natural-exit acceptance for a shipping app or window_close_smoke.dart bundle.

The caller supplies a real/private desktop. Profiles are always disposable.
No successful path calls terminate(), kill(), Dart exit(), or gtk_main_quit().
"""
import argparse
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import signal
import secrets
import re
import subprocess
import time


class ObservationIncomplete(RuntimeError):
    pass


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
            raise ObservationIncomplete(f'No observable tasks for live process {pid}')
    except OSError as error:
        if process_state(pid, expected)['status'] in ('gone', 'reused', 'zombie'):
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
        if self.libc.prctl(36, 1, 0, 0, 0) != 0:
            raise ObservationIncomplete(f'PR_SET_CHILD_SUBREAPER unavailable: errno {C.get_errno()}')
        self.seen = {}
        self.root = None
        self.errors = []
        self.unidentified = {}

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
        self.display = x.XOpenDisplay(None)
        if not self.display:
            raise RuntimeError("An authenticated X11 desktop is required")
        x.XDefaultRootWindow.argtypes = [C.c_void_p]
        x.XDefaultRootWindow.restype = C.c_ulong
        self.root = x.XDefaultRootWindow(self.display)
        x.XInternAtom.argtypes = [C.c_void_p, C.c_char_p, C.c_int]
        x.XInternAtom.restype = C.c_ulong
        x.XGetWindowProperty.argtypes = [C.c_void_p, C.c_ulong, C.c_ulong, C.c_long, C.c_long, C.c_int, C.c_ulong, C.POINTER(C.c_ulong), C.POINTER(C.c_int), C.POINTER(C.c_ulong), C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ubyte))]
        x.XQueryTree.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong), C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ulong)), C.POINTER(C.c_uint)]
        x.XGetWindowAttributes.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(WindowAttributes)]
        x.XFree.argtypes = [C.c_void_p]
        x.XFlush.argtypes = [C.c_void_p]
        x.XCloseDisplay.argtypes = [C.c_void_p]

    def dispose(self):
        self.x.XCloseDisplay(self.display)

    def atom(self, name):
        return self.x.XInternAtom(self.display, name.encode(), 0)

    def window(self, pid):
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
                w = self.GdkX11.X11Window.foreign_new_for_display(self.Gdk.Display.get_default(), xid)
                attributes = WindowAttributes()
                if w and self.x.XGetWindowAttributes(self.display, xid, C.byref(attributes)) and attributes.map_state == 2:
                    return w
            root, parent, count = C.c_ulong(), C.c_ulong(), C.c_uint()
            children = C.POINTER(C.c_ulong)()
            if self.x.XQueryTree(self.display, xid, C.byref(root), C.byref(parent), C.byref(children), C.byref(count)):
                pending.extend(children[:count.value])
                if children:
                    self.x.XFree(children)
        return None

    def close(self, w):
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
        ox, oy = w.get_root_origin()
        p = self.Gdk.pixbuf_get_from_window(self.Gdk.get_default_root_window(), ox + 210, oy + 210, 600, 300)
        if p is None:
            return None
        pixels, stride, channels = p.get_pixels(), p.get_rowstride(), p.get_n_channels()
        samples = [pixels[y * stride + x * channels:y * stride + x * channels + 3] for y in range(0, 300, 8) for x in range(0, 600, 8)]
        saturated = sum(max(v) - min(v) > 80 for v in samples)
        return hashlib.sha256(b"".join(samples)).hexdigest() if saturated > len(samples) // 4 else None


def accepted(record):
    return record.get("exitCode") == 0 and not record.get("error") and not record.get("survivingChildren") and not record.get("cleanupRequired") and not record.get("verificationIncomplete") and not record.get("unresolvedSurvivors")


def run_case(command, folder, profile, scenario, timeout, plain=False, video=None, snap_instance=None, document=None, child_grace=5, term_grace=2, kill_grace=3):
    folder.mkdir()
    environment = os.environ.copy()
    for key, name in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"), ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("TMPDIR", "tmp")]:
        p = profile / name
        p.mkdir(parents=True, exist_ok=True)
        environment[key] = str(p)
    # Unix-domain socket paths must not inherit a long evidence-directory name.
    temporary_alias = Path('/tmp') / ('bm-close-' + secrets.token_hex(8))
    temporary_alias.symlink_to(profile / 'tmp', target_is_directory=True)
    environment['TMPDIR'] = str(temporary_alias)
    environment["BUSYMARK_RELEASE_SMOKE"] = "1"
    environment["BUSYMARK_SPELLING_INSTALL_ROOT"] = str(profile / "data/spelling")
    environment["GST_REGISTRY"] = str(profile / "cache/gstreamer-registry.bin")
    if not plain:
        environment['BUSYMARK_NATIVE_TRACE'] = '1'
    application_profile = profile
    if snap_instance:
        # snap-confine needs the real account home. The application gets an
        # isolated profile only after the normal confined launcher has run.
        environment = os.environ.copy()
        leaf = 'c-' + hashlib.sha256(str(profile).encode()).hexdigest()[:12]
        application_profile = Path.home() / 'snap' / snap_instance / 'common' / leaf
        script = 'profile="$SNAP_USER_COMMON/' + leaf + '"; mkdir -p "$profile"/{home,config,data,state,cache,tmp}; exec env HOME="$profile/home" XDG_CONFIG_HOME="$profile/config" XDG_DATA_HOME="$profile/data" XDG_STATE_HOME="$profile/state" XDG_CACHE_HOME="$profile/cache" TMPDIR="$profile/tmp" BUSYMARK_SPELLING_INSTALL_ROOT="$profile/data/spelling" GST_REGISTRY="$profile/cache/gstreamer-registry.bin" "$SNAP/busymark"'
        command = ['snap', 'run', '--shell', snap_instance, '-c', script]
    report = folder / "application.json"
    arguments = [] if plain else [str(report), scenario] + ([str(video)] if scenario == "video" else [str(document)] if scenario == 'reopen' else [])
    record = {"launch_ns": time.monotonic_ns(), "scenario": scenario, "command": command + arguments, "plainShippingExecutable": plain}
    try:
        tracker = ChildTracker()
    except ObservationIncomplete as error:
        record.update(error=str(error), verificationIncomplete=[str(error)], exitCode=None, launchSkipped=True)
        temporary_alias.unlink()
        (folder / 'result.json').write_text(json.dumps(record, indent=2))
        return record
    seen = tracker.seen
    desktop = Desktop() if plain or scenario == "video" else None
    with (folder / "application.log").open("w") as log:
        process = subprocess.Popen(record["command"], env=environment, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        record["pid"] = process.pid
        tracker.root = process.pid
        stamp = identity(process.pid)
        if stamp is not None:
            seen[process.pid] = stamp
        deadline = time.monotonic() + timeout
        close_sent, first_video = False, None
        try:
            while process.poll() is None and time.monotonic() < deadline:
                tracker.scan()
                if tracker.errors:
                    raise ObservationIncomplete("Child observation is incomplete")
                if plain and not close_sent:
                    w = desktop.window(process.pid)
                    if w:
                        # BusyMark maps its top-level only after FlView first-frame.
                        (folder / "maps").write_text(Path(f"/proc/{process.pid}/maps").read_text())
                        record["mapped_ns"] = time.monotonic_ns()
                        if snap_instance:
                            confinement = Path(f"/proc/{process.pid}/attr/current").read_text().strip()
                            record['confinement'] = confinement
                            if f'snap.{snap_instance}.busymark' not in confinement or '(enforce)' not in confinement:
                                raise RuntimeError('Expected genuine strict Snap confinement')
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

        except Exception as error:
            record["error"] = str(error)
            record["exitCode"] = process.poll()
        finally:
            # Classify before cleanup. A successful cleanup never changes a
            # failed natural exit, hang, incomplete observation or child leak.
            pending = tracker.outstanding()
            if pending:
                record["cleanupRequired"] = pending
            record['observedIdentities'] = tracker.seen
            record['cleanupOutcomes'], record['unresolvedSurvivors'] = cleanup_owned(tracker, term_grace, kill_grace)
            if process.poll() is not None:
                process.wait()
            tracker.close()
            if tracker.errors:
                record['verificationIncomplete'] = tracker.errors
            (folder / "result.json").write_text(json.dumps(record, indent=2))

    temporary_alias.unlink()
    if desktop is not None:
        desktop.dispose()
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cycles", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--fresh-profile", action="store_true", help="Use a new isolated application and graphics cache for each case, retaining it for its reopen check")
    parser.add_argument("--plain", action="store_true", help="Test the unmodified shipping executable using WM_DELETE_WINDOW")
    parser.add_argument("--snap-instance", help="Owned disposable parallel instance, e.g. busymark_close; ordinary closure only")
    parser.add_argument("--scenarios", nargs="+", choices=["plain", "visualization", "video", "pending-initialization", "dirty-save", "dirty-discard", "dirty-cancel"], default=["plain", "visualization", "pending-initialization", "dirty-save", "dirty-discard", "dirty-cancel"])
    parser.add_argument("--video", type=Path)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.video:
        args.video = args.video.resolve()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if args.snap_instance:
        if not re.fullmatch(r'busymark_[a-z0-9]{1,10}', args.snap_instance) or command:
            parser.error('An explicitly named disposable parallel Snap instance is required, without a command')
        args.plain = True
    if (not command and not args.snap_instance) or args.cycles < 1 or ("video" in args.scenarios and not args.video):
        parser.error("Command, positive cycle count and requested video fixture are required")
    root = args.output.resolve()
    root.mkdir(parents=True)  # Never overwrite previous evidence.
    records = []
    scenarios = ["plain"] if args.plain else args.scenarios
    for cycle in range(args.cycles):
        for scenario in scenarios:
            profile = root / "profiles" / f"{cycle}-{scenario}" if args.fresh_profile else root / "profile"
            record = run_case(command, root / f"{cycle}-{scenario}", profile, scenario, args.timeout, args.plain, args.video, args.snap_instance)
            records.append(record)
            print(json.dumps({"cycle": cycle, "scenario": scenario, "exitCode": record.get("exitCode"), "accepted": accepted(record), "error": record.get("error")}), flush=True)
            if record.get('unresolvedSurvivors') or record.get('verificationIncomplete'):
                break
            document = record.get('application', {}).get('document')
            if not args.plain and document and accepted(record):
                reopened = run_case(command, root / f'{cycle}-{scenario}-reopen', profile, 'reopen', args.timeout, document=Path(document))
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

#!/usr/bin/env python3
"""Natural-exit acceptance for a shipping app or window_close_smoke.dart bundle.

The caller supplies a real/private desktop. Profiles are always disposable.
No successful path calls terminate(), kill(), Dart exit(), or gtk_main_quit().
"""
import argparse
import ctypes as C
import hashlib
import json
import math
import os
from pathlib import Path
import stat
import secrets
import re
import shlex
import subprocess
import sys
import time


import owned_processes as owned


class LoadedEngine:
    """Verify the mapped engine through a descriptor retained until process exit."""
    def __init__(self, library):
        try:
            with os.fdopen(os.open(library, os.O_RDONLY | os.O_CLOEXEC | os.O_NONBLOCK), 'rb') as stream:
                if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
                    raise ValueError('Expected a regular ELF shared library')
                header = stream.read(64)
                if (len(header) < 52 or header[:4] != b'\x7fELF'
                        or header[4] not in (1, 2) or header[5] not in (1, 2)
                        or header[6] != 1 or (header[4] == 2 and len(header) < 64)):
                    raise ValueError('Expected an ELF shared library')
                byteorder = 'little' if header[5] == 1 else 'big'
                if (int.from_bytes(header[16:18], byteorder) != 3
                        or int.from_bytes(header[20:24], byteorder) != 1):
                    raise ValueError('Expected an ELF shared library')
                stream.seek(0)
                self.expected = hashlib.file_digest(stream, 'sha256').hexdigest()
        except (OSError, ValueError, TypeError) as error:
            raise owned.ObservationIncomplete('Expected engine library unavailable or invalid: ' + str(error)) from error
        self.fd = None
        self.path = None
        self.stat = None

    def capture(self, tracker):
        if self.fd is not None or tracker.root not in tracker.seen:
            return
        pid = tracker.root
        found = False
        try:
            with owned.ProcessHandle(pid) as proc:
                if proc.state(tracker.seen[pid])['status'] != 'running':
                    return
                rows = [line.split(None, 5) for line in proc.read('maps').decode().splitlines()]
                rows = [r for r in rows if len(r) == 6 and r[5].endswith('/libflutter_linux_gtk.so')]
                if not rows:
                    return  # exec/loader phase; final acceptance still requires capture.
                found = True
                paths = {r[5] for r in rows}
                if len(paths) != 1:
                    raise owned.ObservationIncomplete('Multiple Flutter engines mapped')
                self.path = rows[0][5]
                fd = os.open('root' + self.path, os.O_RDONLY | os.O_CLOEXEC, dir_fd=proc.fd)
                try:
                    stat = os.fstat(fd)
                    major, minor = (int(x, 16) for x in rows[0][3].split(':'))
                    if stat.st_ino != int(rows[0][4]) or stat.st_dev != os.makedev(major, minor):
                        raise owned.ObservationIncomplete('Engine descriptor does not match the mapped inode/device')
                    if proc.state(tracker.seen[pid])['status'] != 'running':
                        return
                    confinement = proc.read('attr/current').decode().strip()
                    self.fd, self.stat, self.confinement = fd, stat, confinement
                    fd = None
                finally:
                    if fd is not None:
                        os.close(fd)
        except (OSError, ValueError, owned.ObservationIncomplete) as error:
            if found and owned.process_state(pid, tracker.seen[pid])['status'] == 'running':
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
            record['loadedEngine'] = {'path': self.path, 'sha256': actual, 'expectedSHA256': self.expected, 'inode': self.stat.st_ino, 'device': self.stat.st_dev, 'confinement': self.confinement}
            if actual != self.expected:
                errors.append('Actual loaded engine differs from the expected artifact')
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


def snap_command(instance, leaf, arguments, extra_environment=None):
    script = 'profile="$SNAP_USER_COMMON/' + leaf + '"; mkdir -p "$profile"/{home,config,data,state,cache,tmp}; exec env HOME="$profile/home" XDG_CONFIG_HOME="$profile/config" XDG_DATA_HOME="$profile/data" XDG_STATE_HOME="$profile/state" XDG_CACHE_HOME="$profile/cache" TMPDIR="$profile/tmp" BUSYMARK_SPELLING_INSTALL_ROOT="$profile/data/spelling" GST_REGISTRY="$profile/cache/gstreamer-registry.bin" '
    if extra_environment:
        script += shlex.join([k + '=' + v for k, v in extra_environment.items()]) + ' '
    script += '"$SNAP/busymark" ' + shlex.join(arguments)
    return ['snap', 'run', '--shell', instance, '-c', script]


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

    def drag_window(self, pid, point):
        """Exercise the titlebar gesture on an explicitly disposable desktop."""
        window = self.window(pid, require_normal=True)
        if window is None:
            raise owned.ObservationIncomplete('Owned drag window is unavailable')
        xid = window.get_xid()
        x, y = point.get('x'), point.get('y')
        if any(type(v) not in (int, float) or not math.isfinite(v) for v in (x, y)):
            raise ValueError('Invalid owned titlebar point')
        attrs = WindowAttributes()
        if not self.x.XGetWindowAttributes(self.display, xid, C.byref(attrs)) or not (
                0 < x < attrs.width - 120 and 0 < y < attrs.height - 30):
            raise owned.ObservationIncomplete('Titlebar point is outside the owned drawable')
        self.x.XTranslateCoordinates.argtypes = [C.c_void_p, C.c_ulong, C.c_ulong,
                                                C.c_int, C.c_int, C.POINTER(C.c_int),
                                                C.POINTER(C.c_int), C.POINTER(C.c_ulong)]
        def origin():
            current_window = self.window(pid, require_normal=True)
            if current_window is None or current_window.get_xid() != xid:
                raise owned.ObservationIncomplete('Owned drag window changed')
            px, py, child = C.c_int(), C.c_int(), C.c_ulong()
            if not self.x.XTranslateCoordinates(self.display, xid, self.root, 0, 0,
                                               C.byref(px), C.byref(py), C.byref(child)):
                raise owned.ObservationIncomplete('Owned window origin is unavailable')
            return px.value, py.value
        start = origin()
        xtest = C.CDLL('libXtst.so.6')
        xtest.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
        xtest.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
        def motion(dx, dy):
            origin()  # Revalidate ownership before each injected event.
            if not xtest.XTestFakeMotionEvent(self.display, 0, int(start[0] + x + dx),
                                              int(start[1] + y + dy), 0):
                raise owned.ObservationIncomplete('Disposable desktop rejected pointer motion')
            self.x.XFlush(self.display)
        motion(0, 0)
        pressed = False
        try:
            if not xtest.XTestFakeButtonEvent(self.display, 1, 1, 0):
                raise owned.ObservationIncomplete('Disposable desktop rejected pointer press')
            pressed = True
            self.x.XFlush(self.display)
            for step in range(1, 21):
                # Pace real input so GTK/Flutter can recognize the pan before
                # the next motion. This is a functional probe, not a latency test.
                time.sleep(.05)
                motion(step * 5, step)
                current = origin()
                delta = [current[0] - start[0], current[1] - start[1]]
                if max(abs(v) for v in delta) >= 8:
                    return delta
            raise RuntimeError('Titlebar drag did not move the owned window')
        finally:
            if pressed:
                if not xtest.XTestFakeButtonEvent(self.display, 1, 0, 0):
                    raise owned.ObservationIncomplete('Disposable pointer release failed')
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


def accepted(record):
    return record.get("exitCode") == 0 and not record.get("error") and not record.get("survivingChildren") and not record.get("cleanupRequired") and not record.get("verificationIncomplete") and not record.get("unresolvedSurvivors") and not record.get('cleanupErrors') and not record.get('reportingError')


def run_case(command, folder, profile, scenario, timeout, plain=False, video=None, snap_instance=None, document=None, child_grace=5, term_grace=2, kill_grace=3, expected_engine=None, disposable_display=False):
    if scenario == 'window-controls' and not disposable_display:
        raise ValueError('Window drag requires an explicitly disposable desktop')
    record = {"scenario": scenario,
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
            if scenario == 'pending-initialization' and not plain:
                extra['BUSYMARK_VISUALIZATION_ASSETS'] = str(profile / 'pending-initialization-assets')
            command = snap_command(snap_instance, leaf, arguments, extra)
            arguments = []

        record['command'] = command + arguments
        if scenario == 'pending-initialization' and not plain:
            record['controlledPendingHarness'] = True
        phase = 'observer initialization'
        probe = LoadedEngine(expected_engine) if expected_engine is not None else None
        tracker = owned.ChildTracker()
        desktop = Desktop() if plain or scenario in ('video', 'window-controls') else None
        phase = 'log opening'
        log = (folder / 'application.log').open('x')
        phase = 'process creation'

        record['launchAttempted'] = True
        process = subprocess.Popen(record['command'], env=environment, stdout=log,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        record['applicationStarted'] = True

        record['pid'] = process.pid
        tracker.root = process.pid
        stamp = owned.identity(process.pid)
        if stamp is not None:
            tracker.seen[process.pid] = stamp
        else:
            tracker.errors.append('Application identity unavailable after launch')
        phase = 'application observation'
        deadline = time.monotonic() + timeout
        close_sent, first_video = False, None
        while process.poll() is None and time.monotonic() < deadline:
            tracker.scan()
            if probe is not None:
                probe.capture(tracker)
            if tracker.errors:
                raise owned.ObservationIncomplete("Child observation is incomplete")
            if plain and not close_sent:
                w = desktop.window(process.pid)
                if w:
                    if snap_instance:
                        confinement = Path(f"/proc/{process.pid}/attr/current").read_text().strip()
                        record['confinement'] = confinement
                        if f'snap.{snap_instance}.busymark' not in confinement or '(enforce)' not in confinement:
                            raise RuntimeError('Expected genuine strict Snap confinement')
                    desktop.close(w)

                    close_sent = True
            if report.exists():
                try:
                    status = json.loads(report.read_text())
                except json.JSONDecodeError:
                    status = {}
                if status.get("phase") == "failed":
                    raise RuntimeError(status.get("error", "Application probe failed"))
                if status.get('phase') == 'awaiting-window-drag' and 'nativeDragDelta' not in record:
                    if scenario != 'window-controls' or not disposable_display:
                        raise RuntimeError('Unexpected pointer-injection request')
                    record['nativeDragDelta'] = desktop.drag_window(process.pid, status['windowDragPoint'])
                    Path(str(report) + '.drag-confirmed').touch()
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

    except BaseException as error:
        record['failurePhase'] = phase
        record['errorType'] = type(error).__name__
        record['error'] = f'{phase.capitalize()} failed ({type(error).__name__}): {error}'
        if isinstance(error, ImportError):
            record['error'] += '; use /usr/bin/python3 with system PyGObject/GdkX11'
        if process is None:
            record['launchSkipped'] = True
        if isinstance(error, owned.ObservationIncomplete) or phase == 'observer initialization' or not isinstance(error, Exception):
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
                record['admittedAncestry'] = dict(tracker.admitted_by)
                record['cleanupOutcomes'], record['unresolvedSurvivors'] = owned.cleanup_owned(tracker, term_grace, kill_grace)
            except BaseException as error:
                cleanup_error('owned processes', error)
                record['unresolvedSurvivors'] = [{'status': 'unavailable', 'error': repr(error)}]
            if process is not None:
                try:
                    if process.poll() is not None:
                        process.wait()
                except BaseException as error:
                    cleanup_error('process reap', error)
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
    parser.add_argument("--plain", action="store_true", help="Test the unmodified shipping executable using WM_DELETE_WINDOW")
    parser.add_argument("--snap-instance", help="Owned disposable parallel instance, e.g. busymark_close")
    parser.add_argument("--snap-fixture", action="store_true", help="The disposable instance contains the compiled window_close_smoke target; require output in its common directory")
    parser.add_argument('--disposable-display', action='store_true', help='The caller owns the whole desktop; required for pointer injection in window-controls')
    parser.add_argument("--scenarios", nargs="+", choices=["plain", "visualization", "video", "pending-initialization", "dirty-save", "dirty-discard", "dirty-cancel", "window-controls"], default=["plain", "visualization", "pending-initialization", "dirty-save", "dirty-discard", "dirty-cancel"])
    parser.add_argument("--video", type=Path)
    parser.add_argument("--expected-engine", type=Path, help="Expected official engine ELF library; hash the actual mapped file after exit")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if 'window-controls' in args.scenarios and not args.disposable_display:
        parser.error('window-controls requires --disposable-display and a window manager')
    if args.video:
        args.video = args.video.resolve()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if args.snap_instance:
        if not re.fullmatch(r'busymark_[a-z0-9]{1,10}', args.snap_instance) or command:
            parser.error('An explicitly named disposable parallel Snap instance is required, without a command')
        if args.snap_fixture:
            if args.plain or not args.expected_engine:
                parser.error('A confined compiled fixture requires --expected-engine and cannot use --plain')
        else:
            args.plain = True
    elif args.snap_fixture:
        parser.error('--snap-fixture requires an explicitly named disposable --snap-instance')
    if (not command and not args.snap_instance) or args.cycles < 1 or ("video" in args.scenarios and not args.video):
        parser.error("Command, positive cycle count and requested video fixture are required")
    root = args.output.resolve()
    if args.snap_fixture and not root.is_relative_to((Path.home() / 'snap' / args.snap_instance / 'common').resolve()):
        parser.error('Confined fixture output must be inside the disposable instance common directory')
    root.mkdir(parents=True)  # Never overwrite previous evidence.
    records = []
    scenarios = ["plain"] if args.plain else args.scenarios
    for cycle in range(args.cycles):
        for scenario in scenarios:
            profile = root / "profiles" / f"{cycle}-{scenario}" if args.fresh_profile else root / "profile"
            record = run_case(command, root / f"{cycle}-{scenario}", profile, scenario, args.timeout, args.plain, args.video, args.snap_instance, expected_engine=args.expected_engine, disposable_display=args.disposable_display)
            records.append(record)
            print(json.dumps({"cycle": cycle, "scenario": scenario, "exitCode": record.get("exitCode"), "accepted": accepted(record), "error": record.get("error")}), flush=True)
            if record.get('unresolvedSurvivors') or record.get('verificationIncomplete'):
                break
            document = record.get('application', {}).get('document')
            if not args.plain and document and accepted(record):
                reopened = run_case(command, root / f'{cycle}-{scenario}-reopen', profile, 'reopen', args.timeout, snap_instance=args.snap_instance, document=Path(document), expected_engine=args.expected_engine)
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

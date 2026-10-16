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


def identity(pid):
    try:
        return Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[19]
    except (OSError, IndexError):
        return None


def live(pid, expected):
    try:
        return identity(pid) == expected and Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[0] != "Z"
    except OSError:
        return False


def descendants(root, seen):
    pending = [root]
    while pending:
        pid = pending.pop()
        stamp = identity(pid)
        if stamp is None:
            continue
        seen[pid] = stamp
        try:
            for thread in Path(f"/proc/{pid}/task").iterdir():
                pending.extend(map(int, (thread / "children").read_text().split()))
        except OSError:
            pass


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
    return record.get("exitCode") == 0 and not record.get("error") and not record.get("survivingChildren") and not record.get("cleanupRequired")


def run_case(command, folder, profile, scenario, timeout, plain=False, video=None, snap_instance=None, document=None):
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
    seen = {}
    desktop = Desktop() if plain or scenario == "video" else None
    with (folder / "application.log").open("w") as log:
        process = subprocess.Popen(record["command"], env=environment, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        record["pid"] = process.pid
        seen[process.pid] = identity(process.pid)
        deadline = time.monotonic() + timeout
        close_sent, first_video = False, None
        try:
            while process.poll() is None and time.monotonic() < deadline:
                descendants(process.pid, seen)
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
            child_deadline = time.monotonic() + 5
            while any(live(p, stamp) for p, stamp in seen.items() if p != process.pid) and time.monotonic() < child_deadline:
                time.sleep(.05)
            record["survivingChildren"] = [p for p, stamp in seen.items() if p != process.pid and live(p, stamp)]
        except Exception as error:
            record["error"] = str(error)
            record["exitCode"] = process.poll()
        finally:
            # Failure cleanup is recorded before signaling only identified children.
            owned = [p for p, stamp in seen.items() if live(p, stamp)]
            if owned:
                record["cleanupRequired"] = owned
            (folder / "result.json").write_text(json.dumps(record, indent=2))
            for p in owned:
                try:
                    os.kill(p, signal.SIGTERM)
                except ProcessLookupError:
                    pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                for p in owned:
                    if live(p, seen[p]):
                        os.kill(p, signal.SIGKILL)
                process.wait(timeout=5)
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
            document = record.get('application', {}).get('document')
            if not args.plain and document and accepted(record):
                reopened = run_case(command, root / f'{cycle}-{scenario}-reopen', profile, 'reopen', args.timeout, document=Path(document))
                records.append(reopened)
                print(json.dumps({'cycle': cycle, 'scenario': scenario + '-reopen', 'exitCode': reopened.get('exitCode'), 'accepted': accepted(reopened), 'error': reopened.get('error')}), flush=True)
    summary = {"runs": len(records), "failures": sum(not accepted(r) for r in records), "records": records}
    (root / "summary.json").write_text(json.dumps(summary, indent=2))
    return 1 if summary["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())

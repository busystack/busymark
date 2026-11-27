#!/usr/bin/python3
"""Measure an ordinary BusyMark audio player in an isolated Pulse desktop."""
import argparse
import json
import math
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import time
import wave

from owned_processes import ChildTracker, cleanup_owned, identity


def run(*args, timeout=12, check=True, **kwargs):
    return subprocess.run(args, check=check, capture_output=True, timeout=timeout, **kwargs)


def until(predicate, seconds, description):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if result := predicate():
            return result
        time.sleep(0.15)
    raise TimeoutError(description)


def pulse_devices(name):
    return json.loads(run('pactl', '-f', 'json', 'list', name).stdout)


def samples(path):
    with wave.open(str(path)) as recording:
        channels = recording.getnchannels()
        rate = recording.getframerate()
        if recording.getsampwidth() != 2:
            raise ValueError('The measured wave is not signed 16-bit PCM')
        data = recording.readframes(recording.getnframes())
    return rate, [frame[0] for frame in struct.iter_unpack('<h', data)][::channels]


def measure(path, tone=False):
    rate, values = samples(path)
    if tone:
        # Exclude only the test recorder's startup. The middle second must
        # contain the known tone and a meaningful signal from the owned sink.
        values = values[rate // 3: rate // 3 + rate]
        if len(values) < rate:
            raise ValueError('The monitor did not capture a complete interval')
    if not values:
        raise ValueError('The decoder returned no samples')
    rms = math.sqrt(sum(x * x for x in values) / len(values))
    result = {'rms': round(rms, 2), 'frames': len(values), 'sampleRate': rate,
              'nonzero': sum(x != 0 for x in values)}
    if tone:
        crossings = sum(a < 0 <= b for a, b in zip(values, values[1:]))
        if not 100 <= rms <= 10000 or not 430 <= crossings <= 450:
            raise ValueError(f'Unexpected monitor signal: RMS={rms:.2f}, Hz={crossings}')
        result['frequencyHz'] = crossings
    return result


def write_report(path, report):
    path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report), flush=True)
    return 0 if report['ok'] else 1


class DesktopApp:
    """Run one ordinary launcher and watch only its identity and descendants."""

    def __init__(self, command, root, sink, backend, installed, report, environment=None,
                 desktop_service=None):
        self.command, self.root = command, root
        self.sink, self.backend, self.installed = sink, backend, installed
        self.report = report
        self.environment = dict(os.environ if environment is None else environment, PULSE_SINK=sink)
        self.environment.pop('BUSYMARK_RELEASE_SMOKE', None)
        self.environment.pop('GI_TYPELIB_PATH', None)
        for variable in ('BUSYMARK_INPUT_DISPLAY', 'BUSYMARK_INPUT_XAUTHORITY', 'BUSYMARK_INPUT_WINDOW'):
            self.environment.pop(variable, None)
        self.process = None
        self.tracker = ChildTracker(desktop_server=desktop_service)
        self.pid = None
        self.window_id = None

    def __enter__(self):
        return self

    def __exit__(self, *_):
        try:
            self.report['survivorsBeforeCleanup'] = self.tracker.outstanding()
            self.report['cleanup'], self.report['unresolvedSurvivors'] = cleanup_owned(self.tracker, 1, 2)
        finally:
            self.tracker.close()
            if self.tracker.errors:
                self.report['ownershipErrors'] = self.tracker.errors
            if self.process is not None:
                self.report.setdefault('exitCode', self.process.poll())
        return False

    def _observe(self):
        current = self.tracker.outstanding()
        if self.tracker.errors:
            raise RuntimeError('; '.join(self.tracker.errors))
        return current

    def _access(self, pid, operation, label, seconds, role=None, optional=False):
        arguments = [] if role is None else ['--role', role]
        result = run(sys.executable, str(Path(__file__).with_name('desktop_accessibility.py')),
                     str(pid), operation, label, str(seconds), *arguments,
                     timeout=seconds + 5, check=False)
        if optional:
            return result.returncode == 0
        if result.returncode:
            raise RuntimeError(f'AT-SPI {operation} failed for {label!r}')
        with (self.root / 'accessibility.log').open('ab') as log:
            log.write(result.stdout)
        return result.stdout.decode().strip()

    def accessibility(self, operation, label='', seconds=5, role=None, optional=False):
        self._observe()
        if identity(self.pid) != self.tracker.seen[self.pid]:
            raise RuntimeError('BusyMark exited before the requested accessibility action')
        return self._access(self.pid, operation, label, seconds, role=role, optional=optional)

    def __find_window(self):
        if self.process.poll() is not None:
            raise RuntimeError('BusyMark exited before mapping its window')
        for entry in self._observe():
            pid = entry['pid']
            if entry['status'] != 'running':
                continue
            if self.backend == 'wayland':
                if self._access(pid, 'present', '', 0, optional=True):
                    return pid, None
            else:
                result = run('xdotool', 'search', '--onlyvisible', '--pid', str(pid), check=False)
                if result.returncode == 0:
                    return pid, result.stdout.decode().splitlines()[0]
        return None

    def launch(self, source):
        with (self.root / 'application.log').open('ab') as log:
            self.process = subprocess.Popen([*self.command, str(source)], env=self.environment,
                                            stdin=subprocess.DEVNULL, stdout=log,
                                            stderr=subprocess.STDOUT)
        self.tracker.root = self.process.pid
        stamp = identity(self.process.pid)
        if stamp is None:
            raise RuntimeError('BusyMark did not remain running')
        self.tracker.seen[self.process.pid] = stamp
        self.pid, self.window_id = until(self.__find_window, 55, 'BusyMark window never became visible')
        if self.installed:
            proc = Path(f'/proc/{self.pid}')
            confinement = (proc / 'attr/current').read_text().strip()
            executable = (proc / 'exe').resolve(strict=True)
            if (confinement != 'snap.busymark.busymark (enforce)'
                    or executable.parent.parent != Path('/snap/busymark')
                    or executable.name != 'busymark'):
                raise RuntimeError('The owned window is not the ordinary strict BusyMark application')
            self.report.update(confinement=confinement, executable=str(executable))
        if self.window_id is not None:
            run('xdotool', 'windowactivate', '--sync', self.window_id)

    def streams(self):
        self._observe()
        owners = {str(pid) for pid in self.tracker.seen}
        return [stream for stream in pulse_devices('sink-inputs')
                if stream['properties'].get('application.process.id') in owners]

    def playing(self):
        return any(not stream['corked'] for stream in self.streams())

    def record(self, output, seconds):
        # Capture the sink monitor on the test host. The product only plays.
        run('ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error',
            '-f', 'pulse', '-i', f'{self.sink}.monitor', '-t', str(seconds),
            '-ac', '1', '-c:a', 'pcm_s16le', str(output), timeout=seconds + 8)

    def _send_input(self, *args, **kwargs):
        environment = dict(os.environ)
        window = self.window_id
        if self.backend == 'wayland':
            # Inject into the dedicated nested compositor's X11 window. Its
            # seat forwards these as genuine Wayland events to the app.
            environment['DISPLAY'] = os.environ['BUSYMARK_INPUT_DISPLAY']
            environment['XAUTHORITY'] = os.environ['BUSYMARK_INPUT_XAUTHORITY']
            window = os.environ['BUSYMARK_INPUT_WINDOW']
        if not window:
            raise RuntimeError('No disposable input window was verified')
        run('xdotool', 'windowactivate', '--sync', window, env=environment)
        run('xdotool', *args, env=environment, **kwargs)

    def key(self, *keys):
        self._send_input('key', *keys)

    def type(self, text):
        self._send_input('type', '--clearmodifiers', '--delay', '30', '--file', '/dev/stdin', input=text.encode())

    def palette(self, label):
        self.key('ctrl+shift+p')
        self.accessibility('wait', 'Search actions…')
        self.type(label)
        self.key('Return')
        self.accessibility('wait', label)

    def menu(self, label):
        self.accessibility('click', 'Main menu')
        self.accessibility('click', label, role='menu item')

    def focus_wayland_seat(self):
        # The sole native client opens a synthetic document without links.
        # A real pointer event gives its surface the compositor's seat.
        window = os.environ['BUSYMARK_INPUT_WINDOW']
        self.accessibility('wait', 'Main menu')
        self._send_input('mousemove', '--window', window, '600', '425', 'click', '1')

    def close(self):
        # Use the actual titlebar action on both backends, including Wayland.
        self.report['closeTarget'] = self.accessibility('click', 'Close')
        self.report['exitCode'] = self.process.wait(timeout=20)
        self.report['naturalExit'] = self.report['exitCode'] == 0
        self.report['noPlaybackAfterClose'] = not self.streams()


def healthy_exit(report):
    return (not report.get('error') and report.get('naturalExit') is True
            and report.get('noPlaybackAfterClose') is True
            and not report.get('survivorsBeforeCleanup') and not report.get('unresolvedSurvivors')
            and not report.get('ownershipErrors'))


def validate_desktop(backend, sink):
    display = 'DISPLAY' if backend == 'x11' else 'WAYLAND_DISPLAY'
    if os.environ.get('GDK_BACKEND') != backend or not os.environ.get(display):
        raise ValueError('Run in the matching disposable desktop session')
    if backend == 'wayland' and os.environ.get('DISPLAY'):
        raise ValueError('Wayland must have no X11 display fallback')
    if not re.fullmatch(r'[A-Za-z0-9_]+', sink):
        raise ValueError('Specify the test-owned PulseAudio sink name')
    if pulse_devices('sink-inputs'):
        raise ValueError('The test requires an isolated audio session with no existing streams')
    if not any(source['name'] == f'{sink}.monitor' for source in pulse_devices('sources')):
        raise ValueError('The test-owned monitor is unavailable')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--sink', required=True)
    parser.add_argument('--backend', choices=['x11', 'wayland'], required=True)
    parser.add_argument('--mode', choices=['editor', 'preview'], required=True)
    parser.add_argument('--installed', action='store_true',
                        help='Use the current profile of the disposable strict instance')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command:
        parser.error('Specify the application launcher')
    validate_desktop(args.backend, args.sink)
    args.output.mkdir()
    root = args.output.resolve()
    document = root / 'probe.md'
    authored = ('# Audio playback probe\n\n'
                '<audio controls preload="none">\n'
                '<source src="missing.ogg" type="audio/ogg">\n'
                '<source src="tone.wav" type="audio/wav">\n'
                '</audio>\n\n<audio autoplay src="tone.wav"></audio>\n')
    document.write_text(authored, encoding='utf-8')
    run('ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error',
        '-f', 'lavfi', '-i', 'sine=frequency=440:duration=30:sample_rate=48000',
        '-c:a', 'pcm_s16le', str(root / 'tone.wav'))
    environment = dict(os.environ)
    if not args.installed:
        for name in ['config', 'data', 'cache']:
            target = root / name
            target.mkdir()
            environment[f'XDG_{name.upper()}_HOME'] = str(target)
        profile = root / 'data' / 'io.busystack.busymark'
        profile.mkdir()
        (profile / 'settings.json').write_text(json.dumps({
            'documentViewMode': args.mode, 'autoSave': False,
            'reopenPreviousWorkspaceOnStartup': False,
        }), encoding='utf-8')
    report = {'mode': args.mode, 'backend': args.backend, 'installed': args.installed}
    try:
        with DesktopApp(command, root, args.sink, args.backend, args.installed, report, environment) as app:
            app.launch(document)
            app.accessibility('wait', 'Play')
            time.sleep(5)
            if app.streams():
                raise RuntimeError('The document opened an audio stream before playback')
            report['didNotAutoplay'] = True
            app.accessibility('click', 'Play')
            until(app.playing, 18, 'Ordered fallback did not open a running audio stream')
            report['played'] = True
            monitor = root / 'monitor.wav'
            app.record(monitor, 2)
            report['monitor'] = measure(monitor, tone=True)
            app.accessibility('click', 'Pause')
            until(lambda: not app.playing(), 6, 'Pause left an audible stream')
            report['paused'] = True
            app.accessibility('click', 'Play')
            until(app.playing, 8, 'Resume did not restart the paused stream')
            report['resumed'] = True
            app.close()
            report['sourcePreserved'] = document.read_text(encoding='utf-8') == authored
    except Exception as error:
        report['error'] = repr(error)
    report['ok'] = healthy_exit(report) and report.get('sourcePreserved') is True
    return write_report(root / 'report.json', report)


if __name__ == '__main__':
    raise SystemExit(main())

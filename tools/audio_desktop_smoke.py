#!/usr/bin/python3
"""Observe a BusyMark audio element in an isolated X11 desktop and Pulse sink."""
import argparse
import json
import math
import os
from pathlib import Path
import re
import struct
import subprocess
import time
import wave

from owned_processes import ChildTracker, cleanup_owned, identity


def run(*args, timeout=12):
    return subprocess.run(args, check=True, capture_output=True, timeout=timeout).stdout


def until(predicate, seconds, description):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if result := predicate():
            return result
        time.sleep(0.15)
    raise TimeoutError(description)


def sink_inputs():
    return json.loads(run('pactl', '-f', 'json', 'list', 'sink-inputs'))


def measured_tone(path):
    with wave.open(str(path)) as recording:
        channels = recording.getnchannels()
        rate = recording.getframerate()
        data = recording.readframes(recording.getnframes())
    samples = [frame[0] for frame in struct.iter_unpack('<h', data)][::channels]
    # Ignore only the test recorder's settling boundaries. The observed
    # middle second must contain the known tone, with a meaningful signal.
    values = samples[rate // 3: rate // 3 + rate]
    if len(values) < rate:
        raise ValueError('The monitor did not capture a complete interval')
    rms = math.sqrt(sum(x * x for x in values) / rate)
    crossings = sum(a < 0 <= b for a, b in zip(values, values[1:]))
    if not 100 <= rms <= 10000 or not 430 <= crossings <= 450:
        raise ValueError(f'Unexpected monitor signal: RMS={rms:.2f}, Hz={crossings}')
    return {'rms': round(rms, 2), 'frequencyHz': crossings, 'frames': len(samples),
            'sampleRate': rate}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--sink', required=True)
    parser.add_argument('--mode', choices=['editor', 'preview'], required=True)
    parser.add_argument('--play', nargs=2, type=int, metavar=('X', 'Y'), required=True,
                        help='Play-button offset from the disposable app window')
    parser.add_argument('--installed', action='store_true',
                        help='Use the current profile of the disposable strict instance')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command or os.environ.get('GDK_BACKEND') != 'x11' or not os.environ.get('DISPLAY'):
        parser.error('Run in a disposable X11 desktop with GDK_BACKEND=x11')
    if not re.fullmatch(r'[A-Za-z0-9_]+', args.sink):
        parser.error('Specify the test-owned PulseAudio sink name')
    if sink_inputs():
        parser.error('The test requires an isolated audio session with no existing streams')
    if f'{args.sink}.monitor' not in run('pactl', 'list', 'short', 'sources').decode():
        parser.error('The test-owned monitor is unavailable')
    args.output.mkdir()
    root = args.output.resolve()
    source = root / 'probe.md'
    source.write_text(
        '# Audio playback probe\n\n'
        '<audio controls preload="none" aria-label="Test tone">\n'
        '<source src="missing.ogg" type="audio/ogg">\n'
        '<source src="tone.wav" type="audio/wav">\n'
        '</audio>\n\n<audio autoplay src="tone.wav"></audio>\n',
        encoding='utf-8',
    )
    run('ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error',
        '-f', 'lavfi', '-i', 'sine=frequency=440:duration=45:sample_rate=48000',
        '-c:a', 'pcm_s16le', str(root / 'tone.wav'))
    environment = dict(os.environ, PULSE_SINK=args.sink)
    if not args.installed:
        for name in ['config', 'data', 'cache']:
            target = root / name
            target.mkdir()
            environment[f'XDG_{name.upper()}_HOME'] = str(target)
        settings = root / 'data' / 'io.busystack.busymark'
        settings.mkdir()
        (settings / 'settings.json').write_text(json.dumps({
            'documentViewMode': args.mode,
            'autoSave': False,
            'reopenPreviousWorkspaceOnStartup': False,
        }), encoding='utf-8')
    report = {'mode': args.mode, 'backend': 'x11', 'installed': args.installed}
    tracker = ChildTracker()
    application = None
    try:
        with (root / 'application.log').open('wb') as log:
            application = subprocess.Popen([*command, str(source)], env=environment,
                                           stdin=subprocess.DEVNULL, stdout=log,
                                           stderr=subprocess.STDOUT)
        tracker.root = application.pid
        stamp = identity(application.pid)
        if stamp is None:
            raise RuntimeError('BusyMark did not remain running')
        tracker.seen[application.pid] = stamp

        def owned_streams():
            tracker.outstanding()
            if tracker.errors:
                raise RuntimeError('; '.join(tracker.errors))
            return [
                stream for stream in sink_inputs()
                if stream['properties'].get('application.process.id') in
                {str(pid) for pid in tracker.seen}
            ]

        def native_window():
            if application.poll() is not None:
                raise RuntimeError('BusyMark exited before mapping its window')
            tracker.outstanding()
            for pid in tracker.seen:
                found = subprocess.run(('xdotool', 'search', '--onlyvisible', '--pid', str(pid)),
                                       capture_output=True, timeout=5, check=False)
                if found.returncode == 0:
                    return found.stdout.decode().splitlines()[0]
            return None

        window = until(native_window, 55, 'BusyMark window never became visible')
        run('xdotool', 'windowactivate', '--sync', window)
        time.sleep(5)
        if owned_streams():
            raise RuntimeError('The document opened an audio stream before playback')
        report['didNotAutoplay'] = True

        def click():
            run('xdotool', 'mousemove', '--window', window, *map(str, args.play), 'click', '1')

        def playing():
            return any(not stream['corked'] for stream in owned_streams())

        click()
        until(playing, 18, 'Application did not open a running audio stream')
        report['played'] = True
        run('ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error',
            '-f', 'pulse', '-i', f'{args.sink}.monitor', '-t', '2',
            '-c:a', 'pcm_s16le', str(root / 'monitor.wav'))
        report['monitor'] = measured_tone(root / 'monitor.wav')
        click()
        until(lambda: not playing(), 6, 'Pause left an audible stream')
        report['paused'] = True
        click()
        until(playing, 8, 'Resume did not restart the paused stream')
        report['resumed'] = True
        run('xdotool', 'key', 'alt+F4')
        report['exitCode'] = application.wait(timeout=20)
        report['naturalExit'] = report['exitCode'] == 0
        report['noPlaybackAfterClose'] = not owned_streams()
    except Exception as error:
        report['error'] = str(error)
    finally:
        remaining = tracker.outstanding()
        report['survivorsBeforeCleanup'] = remaining
        report['cleanup'], report['unresolvedSurvivors'] = cleanup_owned(tracker, 1, 2)
        tracker.close()
        if application is not None and application.poll() is not None:
            report.setdefault('exitCode', application.wait())
        report['ok'] = (not report.get('error') and not remaining
                        and not report['unresolvedSurvivors']
                        and report.get('naturalExit') is True
                        and report.get('noPlaybackAfterClose') is True)
        (root / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(report), flush=True)
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())

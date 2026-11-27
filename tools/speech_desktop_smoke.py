#!/usr/bin/python3
"""Verify offline speech and cancellation through an ordinary strict Snap launch."""
import argparse
from html.parser import HTMLParser
import hashlib
from pathlib import Path
from urllib.parse import unquote, urlsplit

from audio_desktop_smoke import (
    DesktopApp, healthy_exit, measure, run, until, validate_desktop, write_report,
)
from owned_processes import ProcessHandle, process_state


NARRATION = ('Maya Chen counted forty-two pages in the notebook. She folded the last page '
             'carefully before taking the notebook across the footbridge.')


class AudioElements(HTMLParser):
    def __init__(self):
        super().__init__()
        self.elements = []

    def handle_starttag(self, tag, attributes):
        if tag == 'audio':
            self.elements.append(dict(attributes))


def installed_audio(document):
    elements = AudioElements()
    elements.feed(document.read_text(encoding='utf-8'))
    if not elements.elements:
        return None
    if len(elements.elements) != 1:
        raise ValueError('Generating once did not insert exactly one audio element')
    attributes = elements.elements[0]
    src = urlsplit(attributes.get('src', ''))
    if ('controls' not in attributes or attributes.get('preload') != 'none'
            or src.scheme or src.netloc or not src.path or src.path.startswith('/')):
        raise ValueError('Generated audio markup is not portable HTML')
    attached = (document.parent / unquote(src.path)).resolve(strict=True)
    if not attached.is_relative_to(document.parent) or attached.suffix != '.wav':
        raise ValueError('Generation published audio outside its fixture or without WAV output')
    return attached


def assert_offline():
    connections = run('snap', 'connections', 'busymark').stdout.decode().splitlines()
    if not any(line.split()[:3] == ['network', 'busymark:network', '-'] for line in connections):
        raise RuntimeError('Offline speech requires the test Snap network plug disconnected')


def speech_temps():
    result = run('snap', 'run', '--shell', 'busymark', '-c',
                 'find "${TMPDIR:-/tmp}" -maxdepth 1 -type d -name "busymark-speech-*" -print')
    return set(result.stdout.decode().splitlines())


def observe_piper_worker(app):
    children = app.tracker.outstanding(children_only=True)
    for state in children:
        try:
            with ProcessHandle(state['pid']) as process:
                if process.state(state['identity'])['status'] != 'running':
                    continue
                args = process.read('cmdline').split(b'\0')
                if len(args) >= 4 and b'PiperVoice.load' in args[-3] and args[-2].endswith(b'.onnx'):
                    return state
        except (FileNotFoundError, ProcessLookupError):
            continue
    return None


def verify_signal(path):
    signal = measure(path)
    if signal['rms'] < 100 or signal['nonzero'] < 8000:
        raise ValueError('The speech signal is absent or unusable')
    with path.open('rb') as audio:
        signal['sha256'] = hashlib.file_digest(audio, 'sha256').hexdigest()
    return signal


def open_operation(app, label):
    if app.backend == 'x11' and label == 'Generate audio':
        app.palette(label)
    else:
        app.menu(label)
    app.accessibility('click', label, role='button')


def exercise(app, document, report):
    open_operation(app, 'Generate audio')
    app.accessibility('wait', {'espeak': 'eSpeak NG', 'piper': 'Piper'}[report['engine']])
    app.accessibility('wait', 'Save audio', seconds=50)
    if app.streams():
        raise RuntimeError('Generate audio started playback without an explicit action')
    app.accessibility('click', 'Play')
    until(app.playing, 8, 'Generated audio did not play')
    monitor = document.parent / 'monitor.wav'
    app.record(monitor, 2)
    report['generatedPlayback'] = verify_signal(monitor)
    app.accessibility('click', 'Insert audio', role='button')
    app.accessibility('gone', 'Save audio', seconds=20)
    if app.backend == 'wayland':
        app.menu('Save')
    else:
        app.key('ctrl+s')
    attachment = until(lambda: installed_audio(document), 12, 'The generated attachment was not saved')
    report['insertedAudio'] = verify_signal(attachment)
    if report['insertedAudio']['sampleRate'] != 24000:
        raise RuntimeError('The generated attachment does not use the shared WAV format')
    saved = document.read_text(encoding='utf-8')
    if NARRATION not in saved:
        raise RuntimeError('Audio insertion did not preserve its text equivalent')
    until(lambda: not app.streams(), 8, 'Inserting audio did not close its preview stream')
    if app.streams():
        raise RuntimeError('A stream remained before explicit narration')
    open_operation(app, 'Read aloud')
    until(app.playing, 30, 'Narration never began playing')
    report['readAloudPlayed'] = True
    app.accessibility('click', 'Stop narration', role='button')
    until(lambda: not app.streams(), 8, 'Stop narration did not release playback')
    report['readAloudStopped'] = True
    app.accessibility('click', 'Close', role='button')
    app.accessibility('gone', 'Read aloud')
    report['readAloudPreservedDocument'] = document.read_text(encoding='utf-8') == saved
    if not report['readAloudPreservedDocument']:
        raise RuntimeError('Read aloud changed the saved document')


def exercise_cancellation(app, document, report):
    source_before = document.read_bytes()
    open_operation(app, 'Generate audio')
    worker = until(lambda: observe_piper_worker(app), 15, 'No owned Piper synthesis worker was observed')
    app.accessibility('click', 'Cancel synthesis', role='button')
    app.accessibility('gone', 'Cancel synthesis', seconds=20)
    app.accessibility('wait', 'Generate audio', role='button')
    until(lambda: process_state(worker['pid'], worker['identity'])['status'] in ('gone', 'reused'),
          8, 'Piper worker remained after synthesis cancellation')
    app.accessibility('gone', 'Save audio')
    if app.streams() or document.read_bytes() != source_before or list(document.parent.glob('*.wav')):
        raise RuntimeError('Cancelled synthesis retained playback, modified the document or published audio')
    report['cancelledOwnedPiperWorker'] = worker
    app.accessibility('click', 'Close', role='button')
    app.accessibility('gone', 'Generate audio')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--sink', required=True)
    parser.add_argument('--engine', required=True, choices=['espeak', 'piper'])
    parser.add_argument('--backend', required=True, choices=['x11', 'wayland'])
    parser.add_argument('--cancel-synthesis', action='store_true')
    args = parser.parse_args()
    if args.cancel_synthesis and args.engine != 'piper':
        parser.error('The active synthesis cancellation fixture uses Piper')
    args.output.mkdir()
    root = args.output.resolve()
    report = {'engine': args.engine, 'cancelSynthesis': args.cancel_synthesis, 'backend': args.backend}
    document = root / 'probe.md'
    text = '\n\n'.join([NARRATION] * 32) if args.cancel_synthesis else NARRATION
    document.write_text(f'# Speech qualification\n\n{text}\n', encoding='utf-8')
    try:
        validate_desktop(args.backend, args.sink)
        assert_offline()
        report['strictNetworkDisconnected'] = True
        baseline = speech_temps()
        with DesktopApp(['snap', 'run', 'busymark'], root, args.sink, args.backend, True, report) as app:
            try:
                app.launch(document)
                if app.backend == 'wayland':
                    app.focus_wayland_seat()
                if args.cancel_synthesis:
                    exercise_cancellation(app, document, report)
                else:
                    exercise(app, document, report)
                until(lambda: not speech_temps() - baseline, 8, 'Speech left temporary audio after dialog close')
                report['noSpeechTempsAfterDialogClose'] = True
                app.close()
            except Exception:
                if app.pid is not None and app.process.poll() is None:
                    try:
                        app.accessibility('dump', seconds=1)
                    except Exception as observation_error:
                        report['accessibilityObservationError'] = repr(observation_error)
                raise
        report['remainingSpeechTemps'] = sorted(speech_temps() - baseline)
    except Exception as error:
        report['error'] = repr(error)
    report['ok'] = healthy_exit(report) and report.get('remainingSpeechTemps') == []
    return write_report(root / 'report.json', report)


if __name__ == '__main__':
    raise SystemExit(main())

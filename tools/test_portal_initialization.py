#!/usr/bin/python3
"""Controlled native portal regression, never a startup performance benchmark.

Run on a disposable X11 display. Each case owns an isolated session bus and
portal service, and drives GTK through its control pipe (no injected input).
The one-second progress assertion runs only after a request is explicitly held;
it is a regression bound, not a latency target. Failed cases remain failed even
if normal closure or identity-verified cleanup succeeds.
"""
import argparse
import json
import os
from pathlib import Path
import select
import shlex
import signal
import socket
import subprocess
import tempfile
import threading
import time

from owned_processes import ChildTracker, cleanup_owned, identity, process_state, signal_owned

SERVICE = Path(__file__).resolve().parent.parent / 'docs/upstream/flutter/tests/portal_service.py'
NAMESPACE = 'org.gnome.desktop.interface'


class Channel:
    def __init__(self, reader, writer):
        self.reader, self.writer = reader, writer
        self.buffer = b''
        self.events = []

    def send(self, message):
        mark = len(self.events)
        data = (json.dumps(message) if isinstance(message, dict) else message) + '\n'
        self.writer.write(data.encode())
        self.writer.flush()
        return mark

    def read(self, timeout):
        deadline = time.monotonic() + timeout
        while b'\n' not in self.buffer:
            remaining = max(0, deadline - time.monotonic())
            if not select.select([self.reader], [], [], remaining)[0]:
                return None
            chunk = os.read(self.reader.fileno(), 65536)
            if not chunk:
                raise RuntimeError('Owned control channel closed unexpectedly')
            self.buffer += chunk
            if len(self.buffer) > 1024 * 1024:
                raise RuntimeError('Owned control channel bound exceeded')
        line, self.buffer = self.buffer.split(b'\n', 1)
        event = json.loads(line)
        self.events.append(event)
        return event

    def until(self, predicate, timeout=5, after=0):
        deadline = time.monotonic() + timeout
        for event in self.events[after:]:
            if predicate(event):
                return event
        while time.monotonic() < deadline:
            event = self.read(max(0, deadline - time.monotonic()))
            if event is None:
                break
            if predicate(event):
                return event
        raise AssertionError('Owned protocol progress assertion failed: ' + repr(self.events[-8:]))

    def drain(self):
        while b'\n' in self.buffer or select.select([self.reader], [], [], 0)[0]:
            self.read(0)


class AuthenticationGate:
    """Delay only the owned client's session-bus authentication, without logging it."""
    def __init__(self, directory, upstream):
        self.path = str(directory / 'authentication-gate')
        self.upstream = upstream
        self.listener = socket.socket(socket.AF_UNIX)
        self.listener.bind(self.path)
        self.listener.listen(1)
        self.accepted, self.release, self.stopped = threading.Event(), threading.Event(), threading.Event()
        self.connections = []
        self.thread = threading.Thread(target=self.run, daemon=True)
        self.thread.start()

    def run(self):
        try:
            client, _ = self.listener.accept()
            self.connections.append(client)
            self.accepted.set()
            self.release.wait()
            if self.stopped.is_set():
                return
            server = socket.socket(socket.AF_UNIX)
            server.connect(self.upstream)
            self.connections.append(server)
            while not self.stopped.is_set():
                for source in select.select([client, server], [], [], .05)[0]:
                    data = source.recv(65536)
                    if not data:
                        return
                    (server if source is client else client).sendall(data)
        except OSError:
            if not self.stopped.is_set():
                raise

    def close(self):
        self.stopped.set()
        self.release.set()
        self.listener.close()
        for connection in self.connections:
            connection.close()
        self.thread.join(timeout=2)
        assert not self.thread.is_alive(), 'Owned authentication gate did not retire'


class Fixture:
    def __init__(self, output, probe, service_arguments, activation=False, authentication=False, missing=False, socket_parent=None):
        self.output, self.probe = output, probe
        output.mkdir()
        self.tracker = ChildTracker()
        self.socket_directory = tempfile.TemporaryDirectory(prefix='bmportal-', dir=socket_parent or '/tmp')
        self.sockets = Path(self.socket_directory.name)
        self.address = 'unix:path=' + str(self.sockets / 'bus')
        self.service_arguments = service_arguments
        self.activation, self.authentication, self.missing = activation, authentication, missing
        self.processes, self.services, self.logs = [], [], []
        self.client = self.client_channel = self.bus = self.gate = self.activation_socket = None
        self.environment = os.environ.copy()
        for key, leaf in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                          ('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_STATE_HOME', 'state')]:
            directory = output / leaf
            directory.mkdir()
            self.environment[key] = str(directory)
        self.environment.update(DBUS_SESSION_BUS_ADDRESS=self.address, GSETTINGS_BACKEND='memory', GDK_BACKEND='x11')
        self.record = {'probe': str(probe), 'serviceArguments': service_arguments,
                       'qualification': 'Owned isolated bus and GTK control. Deliberate withholding is not natural performance evidence.'}

    def launch(self, command, name, environment=None):
        log = (self.output / (name + '.stderr')).open('xb')
        self.logs.append(log)
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=log, env=self.environment if environment is None else environment, bufsize=0)
        self.tracker.seen[process.pid] = identity(process.pid)
        self.processes.append(process)
        self.tracker.scan()
        return process

    def start_service(self, arguments):
        process = self.launch(['/usr/bin/python3', str(SERVICE), '--address', self.address, *arguments],
                              'service-' + str(len(self.services)))
        channel = Channel(process.stdout, process.stdin)
        channel.until(lambda e: e['event'] == 'ready')
        self.services.append((process, channel))
        return channel

    def start_bus(self):
        services = self.output / 'services'
        services.mkdir()
        if self.activation:
            self.activation_socket = socket.socket(socket.AF_UNIX)
            control_path = str(self.sockets / 'activation')
            self.activation_socket.bind(control_path)
            self.activation_socket.listen(1)
            command = ['/usr/bin/python3', str(SERVICE), '--address', self.address,
                       '--hold', 'name', '--control-socket', control_path]
            (services / 'org.freedesktop.portal.Desktop.service').write_text(
                '[D-BUS Service]\nName=org.freedesktop.portal.Desktop\nExec=' + shlex.join(command) + '\n')
        config = self.output / 'bus.conf'
        config.write_text('<busconfig><type>session</type><listen>' + self.address +
                          '</listen><auth>EXTERNAL</auth><servicedir>' + str(services) +
                          '</servicedir><policy context="default"><allow send_destination="*"/>'
                          '<allow receive_sender="*"/><allow own="*"/></policy></busconfig>')
        self.bus = self.launch(['/usr/bin/dbus-daemon', '--nofork', '--print-address=1',
                                '--config-file=' + str(config)], 'bus')
        assert select.select([self.bus.stdout], [], [], 5)[0], 'Owned bus did not start'
        assert self.bus.stdout.readline().decode().startswith(self.address)
        if not self.activation and not self.missing:
            self.start_service(self.service_arguments)
        if self.authentication:
            self.gate = AuthenticationGate(self.sockets, str(self.sockets / 'bus'))
            self.environment['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=' + self.gate.path
            self.environment['BM_PORTAL_AUTH_COMPONENT'] = '1'
    def start(self):
        self.start_bus()
        self.client = self.launch([str(self.probe)], 'client')
        self.tracker.root = self.client.pid
        self.client_channel = Channel(self.client.stdout, self.client.stdin)
        self.client_channel.until(lambda e: e['event'] == 'entered')
        if self.activation:
            assert select.select([self.activation_socket], [], [], 5)[0], 'Owned activation not requested'
            connection, _ = self.activation_socket.accept()
            reader, writer = connection.makefile('rb', buffering=0), connection.makefile('wb', buffering=0)
            channel = Channel(reader, writer)
            event = channel.until(lambda e: e['event'] == 'ready')
            self.tracker.seen[event['pid']] = identity(event['pid'])
            self.services.append((None, channel))

    @property
    def service(self):
        return self.services[0][1]

    def held(self):
        return self.service.until(lambda e: e['event'] == 'request' and e['held'])

    def progress(self):
        mark = self.client_channel.send('ping')
        return self.client_channel.until(lambda e: e['event'] == 'progress', timeout=1, after=mark)

    def command(self, action, **values):
        mark = self.service.send(dict(action=action, **values))
        return self.service.until(lambda e: e['event'] == 'command' and e['action'] == action, after=mark)

    def initialized(self):
        return self.client_channel.until(lambda e: e['event'] == 'initialized')

    def close_client(self):
        self.client_channel.send('close')
        self.client.wait(timeout=5)
        assert self.client.returncode == 0, self.client.returncode

    def cleanup(self, error):
        # Release test barriers, then request normal closure. Use the maintained
        # identity-aware cleanup only for failed/hung checks; never turn them
        # into passing checks because cleanup happened to succeed.
        cleanup_errors = []
        if self.gate:
            self.gate.release.set()
        for _, channel in self.services:
            try:
                mark = channel.send({'action': 'release'})
                channel.until(lambda e: e['event'] == 'command' and e['action'] == 'release', after=mark)
            except (AssertionError, RuntimeError, OSError) as failure:
                cleanup_errors.append(repr(failure))
        if self.client is not None and self.client.poll() is None:
            try:
                self.client_channel.send('close')
                self.client.wait(timeout=5)
            except (OSError, subprocess.TimeoutExpired) as failure:
                cleanup_errors.append(repr(failure))
        for process, channel in self.services:
            try:
                channel.send({'action': 'quit'})
                if process is not None:
                    process.wait(timeout=5)
                    if process.returncode != 0:
                        cleanup_errors.append("Owned portal service exited " + str(process.returncode))
                else:
                    # D-Bus activated this owned service. Its parent exiting is
                    # irrelevant: independently wait on the captured identity.
                    pid = next(e['pid'] for e in channel.events if e['event'] == 'ready')
                    deadline = time.monotonic() + 5
                    while process_state(pid, self.tracker.seen[pid])['status'] == 'running':
                        if time.monotonic() >= deadline:
                            raise subprocess.TimeoutExpired('owned activated portal exit', 5)
                        time.sleep(.01)
            except (OSError, subprocess.TimeoutExpired) as failure:
                cleanup_errors.append(repr(failure))
        if self.bus is not None and self.bus.poll() is None:
            signal_owned(self.bus.pid, self.tracker.seen[self.bus.pid], signal.SIGTERM)
            try:
                self.bus.wait(timeout=5)
            except subprocess.TimeoutExpired as failure:
                cleanup_errors.append(repr(failure))
        if self.gate:
            try:
                self.gate.close()
            except Exception as failure:
                cleanup_errors.append(repr(failure))
        if self.activation_socket:
            self.activation_socket.close()
        self.tracker.scan()
        outcomes, unresolved = cleanup_owned(self.tracker, 2, 2)
        self.tracker.close()
        self.record.update(error=error, cleanupErrors=cleanup_errors,
                           clientExitCode=self.client.returncode if self.client else None,
                           childObservationErrors=self.tracker.errors,
                           observedIdentities=self.tracker.seen,
                           cleanupOutcomes=outcomes, unresolvedSurvivors=unresolved,
                           clientEvents=self.client_channel.events if self.client_channel else [],
                           serviceEvents=[channel.events for _, channel in self.services])
        self.record['ok'] = (error is None and not cleanup_errors and not outcomes and not unresolved
                             and not self.tracker.errors and self.record['clientExitCode'] == 0)
        (self.output / 'result.json').write_text(json.dumps(self.record, indent=2))
        for log in self.logs:
            log.close()
        self.socket_directory.cleanup()
        return self.record


def expect_snapshot(value, nondefault=True, scale=None, clock12=None):
    expected = dict(clock12=nondefault, dark=nondefault,
                    animations=not nondefault, contrast=nondefault,
                    scale=(1.5 if nondefault else 1.0) if scale is None else scale)
    if clock12 is not None:
        expected['clock12'] = clock12
    assert {k: value[k] for k in expected} == expected, (value, expected)


def exercise(name, f):
    f.start()
    # The provider must expose reliable local values before any portal reply.
    # This event is unavailable on the synchronous control until its held call
    # completes; progress below remains the causal old-engine regression.
    if name == 'authentication':
        assert f.gate.accepted.wait(5)
        assert f.progress()['initialized'] == 0
        expect_snapshot(f.client_channel.until(lambda e: e['event'] == 'local'), nondefault=False, scale=1.25)
        f.close_client()
        return
    if name == 'factory-held':
        f.held()
        assert f.progress()['initialized'] == 0
        expect_snapshot(f.client_channel.until(lambda e: e['event'] == 'local'), nondefault=False, scale=1.25)
        f.close_client()
        return
    if name == 'factory':
        expect_snapshot(f.client_channel.until(lambda e: e['event'] == 'changed'))
    elif name in ['activation', 'activation-close']:
        assert f.progress()['initialized'] == 0
        if name == 'activation-close':
            f.close_client()
            return
        f.command('own')
        expect_snapshot(f.initialized())
    elif name in ['held-read', 'newer-signal', 'signal-order', 'cancel', 'close-pending', 'dispose-pending', 'repeat', 'restart', 'local-precedence', 'dispose-publication']:
        f.held()
        if name != 'signal-order':
            assert f.progress()['initialized'] == 0
        if name == 'close-pending':
            f.close_client()
            return
        if name in ['dispose-pending', 'dispose-publication']:
            mark = f.client_channel.send('retire-publication' if name == 'dispose-publication' else 'dispose')
            assert f.client_channel.until(lambda e: e['event'] == 'disposed', after=mark)['finalized']
            f.command('release')
            assert f.progress()['initialized'] == 0
        elif name == 'cancel':
            mark = f.client_channel.send('cancel')
            assert f.client_channel.until(lambda e: e['event'] == 'initialization-error', after=mark)['cancelled']
            f.command('release')
            assert f.progress()['initialized'] == 0
        elif name == 'restart':
            f.command('drop')
            f.initialized()  # Local values remain usable across owner loss.
            replacement = f.start_service(['--scale', '2'])
            f.client_channel.until(lambda e: e.get('scale') == 2)
            f.command('release')  # Deliver stale old-owner responses afterwards.
            f.progress()
            mark = f.client_channel.send('values')
            expect_snapshot(f.client_channel.until(lambda e: e['event'] == 'values', after=mark), scale=2)
        else:
            if name == 'local-precedence':
                mark = f.client_channel.send('local-change')
                expect_snapshot(f.client_channel.until(lambda e: e['event'] == 'changed', after=mark), scale=1.75)
                assert f.progress()['changes'] == 1
            if name == 'repeat':
                mark = f.client_channel.send('repeat')
                assert f.client_channel.until(lambda e: e['event'] == 'initialization-error', after=mark)['pending']
            if name == 'signal-order':
                f.command('change', namespace=NAMESPACE, key='clock-format', type='s', value='24h')
            elif name == 'newer-signal':
                f.command('change', namespace=NAMESPACE, key='text-scaling-factor', type='d', value=2)
                # Live authority cannot wait for another withheld initial key.
                f.client_channel.until(lambda e: e.get('scale') == 2, timeout=1)
                assert f.progress()['initialized'] == 0
                assert f.progress()['changes'] == 1
            f.command('release')
            expect_snapshot(f.initialized(), scale=2 if name == 'newer-signal' else None,
                            clock12=False if name == 'signal-order' else None)
            if name == 'local-precedence':
                assert f.progress()['changes'] == 2
                f.client_channel.send('local-change')
                assert f.progress()['changes'] == 2
            if name == 'repeat':
                mark = f.client_channel.send('repeat')
                expect_snapshot(f.client_channel.until(lambda e: e['event'] == 'initialized', after=mark))
                assert f.progress()['initialized'] == 2
    else:
        expect_snapshot(f.initialized(), nondefault=name not in ['missing', 'malformed', 'failure'],
                        scale=1.25 if name in ['partial', 'missing', 'malformed', 'failure'] else None)
        if name == 'fast':
            f.command('change', namespace=NAMESPACE, key='text-scaling-factor', type='d', value=2)
            expect_snapshot(f.client_channel.until(lambda e: e.get('scale') == 2), scale=2)
    if name not in ['cancel', 'dispose-pending', 'dispose-publication', 'restart']:
        # Exactly one complete initial authority update, never six visual
        # changes. Missing/invalid authority keeps the same local appearance.
        expected_changes = 0 if name in ['missing', 'malformed', 'failure'] else 2 if name in ['fast', 'local-precedence', 'newer-signal'] else 1
        assert f.progress()['changes'] == expected_changes
    if name not in ['missing', 'authentication', 'activation', 'restart']:
        f.service.drain()
        requests = [e for e in f.service.events if e.get('event') == 'request']
        assert not any(e['member'] == 'GetAll' for e in requests), requests
        assert len([e for e in requests if e['member'] == 'Read']) == 6, requests
    f.close_client()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--probe', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--cases', nargs='+')
    args = parser.parse_args()
    output = args.output.resolve() if args.output else Path(tempfile.mkdtemp(prefix='busymark-portal-tests-'))
    if args.output:
        output.mkdir(parents=True, exist_ok=False)
    cases = args.cases or ['fast', 'getall', 'held-read', 'newer-signal', 'signal-order', 'repeat', 'cancel',
                           'close-pending', 'dispose-pending', 'missing', 'malformed', 'partial',
                           'failure', 'restart', 'activation', 'authentication', 'factory', 'factory-held', 'local-precedence', 'activation-close', 'dispose-publication']
    records = []
    for name in cases:
        held = name in ['held-read', 'newer-signal', 'signal-order', 'repeat', 'cancel', 'close-pending', 'dispose-pending', 'restart', 'factory-held', 'local-precedence', 'dispose-publication']
        service_args = ['--hold', 'read' if held else 'getall' if name == 'getall' else 'none']
        if name == 'malformed':
            service_args += ['--malformed']
        if name == 'partial':
            service_args += ['--omit-key', 'text-scaling-factor']
        if name == 'failure':
            service_args += ['--fail']
        fixture = Fixture(output / name, args.probe.resolve(), service_args,
                          activation=name in ['activation', 'activation-close'], authentication=name == 'authentication', missing=name == 'missing')
        if name.startswith('factory'):
            fixture.environment['BM_PORTAL_FACTORY'] = '1'
        error = None
        try:
            exercise(name, fixture)
        except Exception as failure:
            error = repr(failure)
        result = fixture.cleanup(error)
        records.append(dict(case=name, **result))
        (output / 'summary.json').write_text(json.dumps(records, indent=2))
        print(name, 'PASS' if result['ok'] else 'FAIL', flush=True)
        if not result['ok']:
            raise SystemExit('Portal regression failed; retained evidence: ' + str(output))
    print('Portal regression evidence: ' + str(output), flush=True)


if __name__ == '__main__':
    main()

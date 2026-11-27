#!/usr/bin/python3
"""Verify a synthetic speech credential through strict Snap restarts and deletion."""

import argparse
import os
from pathlib import Path
import re
import secrets
import shutil
import signal
import subprocess
import tempfile

from audio_desktop_smoke import DesktopApp, healthy_exit, run, until, validate_desktop, write_report
from owned_processes import identity, signal_owned
from speech_desktop_smoke import assert_offline


CREDENTIAL = 'busymark.speech.provider-key.elevenlabs'
NO_KEY = 'Save a valid provider key in Settings before requesting speech.'
OFFLINE = 'BusyMark could not connect to ElevenLabs.'


def service_owner():
    result = run('gdbus', 'call', '--session', '--dest', 'org.freedesktop.DBus',
                 '--object-path', '/org/freedesktop/DBus', '--method',
                 'org.freedesktop.DBus.GetConnectionUnixProcessID', 'org.freedesktop.secrets',
                 check=False)
    match = re.fullmatch(rb'\(uint32 (\d+),\)\n', result.stdout)
    return int(match[1]) if result.returncode == 0 and match else None


def stored_secret(vault_environment):
    observed = run('secret-tool', 'lookup', 'credential', CREDENTIAL, check=False, env=vault_environment)
    return observed.stdout.rstrip(b'\n') if observed.returncode == 0 else None


def verify_vault_link():
    links = run('snap', 'connections', 'busymark').stdout.decode().splitlines()
    if not any(line.split()[:3] == ['password-manager-service', 'busymark:password-manager-service',
                                     ':password-manager-service'] for line in links):
        raise RuntimeError('The installed Snap is missing its authorized password-manager connection')


def pause_empty_fixture_service(paused):
    owner = service_owner()
    if owner is None:
        return
    daemon = 'gnome-keyring-daemon.service'
    socket = 'gnome-keyring-daemon.socket'
    observed = run('systemctl', '--user', 'show', '--property=MainPID', '--value', daemon).stdout
    keyrings = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share')) / 'keyrings'
    if observed.strip() != str(owner).encode() or (keyrings.exists() and any(keyrings.iterdir())):
        raise RuntimeError('The existing Secret Service is not an empty disposable GNOME fixture')
    for unit in (socket, daemon):
        if run('systemctl', '--user', 'is-active', '--quiet', unit, check=False).returncode == 0:
            paused.append(unit)
    run('systemctl', '--user', 'stop', socket, daemon)
    until(lambda: service_owner() is None, 5, 'The disposable desktop service did not release its bus name')


def open_speech(app, document):
    app.launch(document)
    app.key('ctrl+alt+s')
    app.accessibility('click', 'Speech', role='button')
    app.accessibility('wait', 'Store key', role='button')


def enter_synthetic_key(app, token):
    for _ in range(30):
        if app.accessibility('focused', role='password text', seconds=0, optional=True):
            app.type(token)
            return
        app.key('Tab')
    raise RuntimeError('Keyboard navigation did not focus the obscured credential field')


def app_phase(args, root, document, service, phase, action):
    report = {'phase': phase}
    try:
        with DesktopApp(['snap', 'run', 'busymark'], root, args.sink, args.backend, True, report,
                        desktop_service=service.pid) as app:
            open_speech(app, document)
            action(app)
            report['actionsCompleted'] = True
            app.close()
    except Exception as error:
        report['error'] = repr(error)
    report['ok'] = healthy_exit(report) and report.get('actionsCompleted') is True
    return report


def exercise(args, root, document, keyring_directory, report):
    if service_owner() is not None:
        raise RuntimeError('Refusing to replace an existing Secret Service')
    token = secrets.token_hex(24)
    with tempfile.TemporaryDirectory(prefix='vault-', dir=root) as temporary:
        control = Path(temporary) / 'control'
        control.mkdir(mode=0o700)
        environment = dict(os.environ, GNOME_KEYRING_CONTROL=str(control), XDG_DATA_HOME=temporary)
        with (root / 'keyring.log').open('wb') as log:
            service = subprocess.Popen(
                ['gnome-keyring-daemon', '--login', '--foreground', '--components=secrets',
                 '--control-directory', str(control)], env=environment, stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL, stderr=log)
        service_stamp = identity(service.pid)
        try:
            with service.stdin as unlock:
                unlock.write(secrets.token_hex(24).encode())
            until(lambda: (control / 'control').is_socket(), 15, 'Secret Service control socket is unavailable')
            run('gnome-keyring-daemon', '--start', '--components=secrets', '--control-directory',
                str(control), env=environment)
            until(lambda: service_owner() == service.pid, 15, 'Owned daemon did not acquire the normal user bus')
            if stored_secret(environment) is not None:
                raise RuntimeError('The disposable vault is not empty')
            report['fixtureReady'] = True
            encrypted = keyring_directory / 'default.keyring'

            def store(app):
                app.accessibility('click', 'Discover engines and voices', role='button')
                app.accessibility('wait', NO_KEY)
                enter_synthetic_key(app, token)
                app.accessibility('click', 'Store key', role='button')
                app.accessibility('wait', 'The key was saved in secure storage.')
                if encrypted.is_file():
                    if encrypted.stat().st_mode & 0o777 != 0o600 or token.encode() in encrypted.read_bytes():
                        raise RuntimeError('Secret portal output is not protected')
                    report['storage'] = 'Secret portal encrypted file'
                elif stored_secret(environment) == token.encode():
                    report['storage'] = 'desktop Secret Service'
                else:
                    raise RuntimeError('Stored credential did not reach an observed secure backend')

            def restart_and_delete(app):
                app.accessibility('click', 'Discover engines and voices', role='button')
                # With the network disconnected, this response proves that
                # the new process loaded the credential without a paid call.
                app.accessibility('wait', OFFLINE, seconds=20)
                if report['storage'] == 'desktop Secret Service' and stored_secret(environment) != token.encode():
                    raise RuntimeError('Credential changed between application launches')
                report['readAfterRestart'] = True
                app.accessibility('click', 'Delete key', role='button')
                app.accessibility('wait', 'The key was removed from secure storage.')
                app.accessibility('click', 'Discover engines and voices', role='button')
                app.accessibility('wait', NO_KEY)
                report['deleted'] = stored_secret(environment) is None
                if not report['deleted']:
                    raise RuntimeError('The isolated vault still contains the credential')

            stored = app_phase(args, root, document, service, 'store', store)
            report['launches'] = [stored]
            if stored.get('actionsCompleted') and not stored.get('unresolvedSurvivors'):
                report['launches'].append(app_phase(args, root, document, service, 'restart-delete', restart_and_delete))
            for file in [*keyring_directory.glob('*.keyring'), *root.glob('*.log'),
                         args.profile / 'settings.json']:
                if file.is_file() and token.encode() in file.read_bytes():
                    raise RuntimeError('The synthetic credential appeared in plaintext evidence')
            report['noPlaintext'] = True
        finally:
            if service_owner() == service.pid:
                run('secret-tool', 'clear', 'credential', CREDENTIAL, check=False, env=environment)
            if service.poll() is None and service_stamp is not None:
                report['keyringStop'] = signal_owned(service.pid, service_stamp, signal.SIGTERM)
                try:
                    service.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    report['keyringForcedCleanup'] = signal_owned(service.pid, service_stamp, signal.SIGKILL)
                    service.wait(timeout=4)
            report['ownedKeyringExited'] = service.poll() is not None
            if keyring_directory.exists():
                shutil.rmtree(keyring_directory)
            report['privateVaultFilesRemoved'] = not keyring_directory.exists()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--profile', required=True, type=Path)
    parser.add_argument('--sink', required=True)
    parser.add_argument('--backend', required=True, choices=['x11', 'wayland'])
    args = parser.parse_args()
    args.output.mkdir()
    root = args.output.resolve()
    document = root / 'probe.md'
    document.write_text('# Isolated credential qualification\n', encoding='utf-8')
    report = {'backend': args.backend}
    paused = []
    try:
        validate_desktop(args.backend, args.sink)
        assert_offline()
        verify_vault_link()
        report['strictNetworkDisconnected'] = True
        profile = args.profile.resolve(strict=True)
        expected = (Path.home() / 'snap/busymark/current/.local/share/io.busystack.busymark')
        if profile != expected.resolve(strict=True):
            raise RuntimeError('Expected the disposable installed Snap application profile')
        keyring_directory = args.profile.parent / 'keyrings'
        if keyring_directory.exists() or keyring_directory.is_symlink():
            raise RuntimeError('Refusing to overwrite an existing application keyring')
        pause_empty_fixture_service(paused)
        exercise(args, root, document, keyring_directory, report)
    except Exception as error:
        report['error'] = repr(error)
    finally:
        if paused:
            restored = run('systemctl', '--user', 'start', *paused, check=False)
            report['testSessionServiceRestored'] = restored.returncode == 0
    launches = report.get('launches', [])
    report['ok'] = (not report.get('error') and not report.get('keyringForcedCleanup') and len(launches) == 2
                    and report.get('testSessionServiceRestored', True)
                    and all(launch['ok'] for launch in launches)
                    and all(report.get(check) is True for check in ('readAfterRestart', 'deleted', 'noPlaintext',
                                                                   'ownedKeyringExited', 'privateVaultFilesRemoved')))
    return write_report(root / 'report.json', report)


if __name__ == '__main__':
    raise SystemExit(main())

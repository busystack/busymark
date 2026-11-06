#!/usr/bin/env python3
"""Run the installed BusyMark capture harness on an owned private session bus.

The abstract Unix address remains visible inside Snap's mount namespace. The
ordinary session configuration, authentication and confinement stay in force.
"""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import uuid


def main():
    if len(sys.argv) not in [4, 5]:
        raise SystemExit('Expected installed binary, artifact directory, fixture and optional text scale')
    output = Path(sys.argv[2]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='bsg-native-bus-', dir=output) as temporary:
        env = dict(os.environ)
        # snapd creates its genuine systemd scope/portal connection on the
        # normal desktop. The confined shell switches the application itself
        # to this wrapper's private bus/profile after the ordinary command-chain.
        env['BUSYSTACK_NATIVE_SNAP_LAUNCH_BUS'] = env.get('DBUS_SESSION_BUS_ADDRESS', '')
        env['BUSYSTACK_NATIVE_SNAP_LAUNCH_RUNTIME'] = env.get('XDG_RUNTIME_DIR', '')
        for suffix in ['CONFIG_HOME', 'DATA_HOME', 'CACHE_HOME', 'STATE_HOME', 'RUNTIME_DIR']:
            directory = Path(temporary) / suffix
            directory.mkdir(mode=0o700)
            env['XDG_'+suffix] = str(directory)
        address = 'unix:abstract=/tmp/dbus-bsg-native-'+uuid.uuid4().hex
        with (output/'session-bus.log').open('w') as log:
            bus = subprocess.Popen(['dbus-daemon', '--session', '--nofork', '--print-address=1',
                                    '--address='+address], env=env, stdout=subprocess.PIPE, stderr=log)
            try:
                actual = bus.stdout.readline().decode().strip()
                if not actual.startswith(address):
                    raise RuntimeError('Private session bus did not bind its requested address')
                env.update(DBUS_SESSION_BUS_ADDRESS=actual, BUSYSTACK_NATIVE_SNAP_APP='busymark')
                result = subprocess.run(['/usr/bin/python3', str(Path(__file__).with_name('git_native_desktop.py')),
                                         *sys.argv[1:]], env=env)
                return result.returncode
            finally:
                bus.terminate()
                bus.wait(timeout=10)


if __name__ == '__main__':
    raise SystemExit(main())

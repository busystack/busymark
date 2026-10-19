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
from pathlib import Path
import sys
import tempfile

# This proposed-engine driver is deliberately outside ordinary app acceptance.
sys.path.insert(0, str(Path(__file__).resolve().parents[4] / 'tools'))
from portal_test_support import Fixture, NAMESPACE, expect_snapshot


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

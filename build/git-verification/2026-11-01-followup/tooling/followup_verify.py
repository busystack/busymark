"""Verification of the two 2026-11-01 BusyMark integration corrections."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import time

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
source = root / 'inputs/busymark'
logs = root / 'followup-20261101-cf29cd1'
logs.mkdir(exist_ok=True)
env = dict(os.environ, PATH=str(root/'flutter/bin')+':'+os.environ['PATH'],
           PUB_CACHE=str(root/'pub-cache'), CI='true', TMPDIR='/var/tmp')

def run(name, args):
    if shutil.disk_usage(root).free < 3 * 1024**3:
        raise SystemExit('Verification stopped: guest free space below 3 GiB')
    path = logs / (name + '.log')
    attempt = 1
    while path.exists():
        attempt += 1
        path = logs / (name + '-attempt' + str(attempt) + '.log')
    print('START', name, flush=True)
    started = time.time()
    with path.open('w') as log:
        result = subprocess.run(args, cwd=source, env=env, stdout=log,
                                stderr=subprocess.STDOUT)
    receipt = dict(name=name, argv=args, exit=result.returncode,
                   started=started, finished=time.time())
    with (logs/'commands.jsonl').open('a') as out:
        out.write(json.dumps(receipt)+'\n')
    print('END', name, result.returncode, flush=True)
    if result.returncode:
        print(path.read_text()[-8000:], flush=True)
        raise SystemExit(result.returncode)

if sys.argv[1] == 'validate':
    run('source-revision', ['git', 'rev-parse', 'HEAD'])
    run('shared-pins', ['python3', 'tools/checkout_shared_dependencies.py', '--check'])
    run('git-localization-ci', ['python3', '../busystack_git_flutter/tool/sync_host_localizations.py',
        '--arb', 'lib/l10n/app_en.arb', '--adapter',
        'lib/src/git/application/shared_git_localizations.dart', '--class-name',
        'AppLocalizations', '--import-uri',
        '../../../l10n/generated/app_localizations.dart', '--check'])
    run('generate-localizations', ['flutter', 'gen-l10n'])
    run('generated-clean', ['git', 'diff', '--exit-code'])
elif sys.argv[1] == 'release':
    run('release-build', ['flutter', 'build', 'linux', '--release', '--no-pub'])
else:
    raise SystemExit('Expected validate or release')

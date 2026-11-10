from pathlib import Path
import json, os, subprocess, sys, time

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
inputs = root/'inputs'
env = dict(os.environ, PATH=str(root/'flutter/bin')+':'+str(root/'node/bin')+':'+os.environ['PATH'],
           PUB_CACHE=str(root/'pub-cache'), CI='true', TMPDIR='/var/tmp',
           BUSYFILES_FLUTTER_SDK=str(root/'flutter'),
           BUSYSTACK_TEST_GIT=str(root/'official-assets/git-runtime/bin/git'),
           BUSYSTACK_TEST_GIT_256=str(root/'official-assets/git-runtime/bin/git'),
           BUSYSTACK_GIT_EXECUTABLE=str(root/'official-assets/git-runtime/bin/git'),
           BUSYSTACK_GIT_HELPER_PATH=str(root/'official-assets/busystack-git-helper'),
           BUSYFILES_GIO_LIBRARY=str(inputs/'busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so'),
           BUSYFILES_TEST_GIO_LIBRARY=str(inputs/'busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so'))

def run(name, cwd, *argv):
    import shutil
    if shutil.disk_usage(root).free < 3*1024**3: raise SystemExit('Guest capacity below 3 GiB; no build started')
    base=name
    attempt=1
    while (root/'sidebar-refinement-20261101'/f'{name}.log').exists():
        attempt+=1
        name=f'{base}-attempt{attempt}'
    print('START', name, flush=True)
    start=time.time()
    with (root/'sidebar-refinement-20261101'/f'{name}.log').open('w') as log:
        result=subprocess.run(argv, cwd=inputs/cwd, env=env, stdout=log, stderr=subprocess.STDOUT)
    with (root/'sidebar-refinement-20261101/commands.jsonl').open('a') as evidence:
        evidence.write(json.dumps({'name':name,'cwd':str(inputs/cwd),'argv':argv,
            'start':start,'end':time.time(),'exit':result.returncode})+'\n')
    print('END', name, result.returncode, round(time.time()-start, 1), flush=True)
    if result.returncode:
        print((root/'sidebar-refinement-20261101'/f'{name}.log').read_text(errors='replace')[-10000:],flush=True)
        raise SystemExit(result.returncode)


phase=sys.argv[1]
if phase=='setup':
    for package in ['busystack_git','busystack_git_flutter','busymark','busyfiles']:
        run(package+'-pub',package,'dart' if package in ['busystack_git','busyfiles'] else 'flutter','pub','get','--offline','--enforce-lockfile')
    run('files-ui-pub','busyfiles/apps/busyfiles_ui','flutter','pub','get','--offline','--enforce-lockfile')
elif phase=='audit':
    run('mark-pins','busymark','python3','tools/checkout_shared_dependencies.py','--check')
    run('shared-pins','busystack_git_flutter','python3','tool/checkout_shared_dependencies.py','--check')
    run('files-pins','busyfiles','python3','scripts/ci/checkout-shared-dependencies.py','--check')
    run('mark-l10n-ci','busymark','python3','../busystack_git_flutter/tool/sync_host_localizations.py','--arb','lib/l10n/app_en.arb','--adapter','lib/src/git/application/shared_git_localizations.dart','--class-name','AppLocalizations','--import-uri','../../../l10n/generated/app_localizations.dart','--check')
    run('mark-gen-l10n','busymark','flutter','gen-l10n')
    run('mark-generated-clean','busymark','git','diff','--exit-code')
    run('files-l10n-ci','busyfiles','python3','../busystack_git_flutter/tool/sync_host_localizations.py','--arb','apps/busyfiles_ui/lib/src/l10n/arb/busyfiles_en.arb','--adapter','apps/busyfiles_ui/lib/src/features/browser/shared_git_localizations.dart','--class-name','BusyFilesStrings','--import-uri','../../l10n/generated/busyfiles_localizations.dart','--named','--check')
    run('files-gen-l10n','busyfiles/apps/busyfiles_ui','flutter','gen-l10n')
    run('files-generated-clean','busyfiles','git','diff','--exit-code')
    run('native-audit-selftest','busystack_git_flutter','dart','run','tool/test_native_presentation_audit.dart')
    run('native-audit-all','busystack_git_flutter','dart','run','tool/check_native_presentation.dart','lib/src','../busymark/lib/src/git','../busyfiles/apps/busyfiles_ui/lib/src/features/browser/git_workspace.dart')
    run('mark-audit-pub','busymark/tools/git_ui_audit','dart','pub','get','--offline','--enforce-lockfile')
    run('mark-audit-selftest','busymark/tools/git_ui_audit','dart','run','bin/check.dart','--self-test')
    run('mark-audit','busymark/tools/git_ui_audit','dart','run','bin/check.dart')
    for package in ['busystack_git','busystack_git_flutter','busymark','busyfiles/apps/busyfiles_ui']:
        run(package.replace('/','-')+'-analyze',package,*(['dart','analyze'] if package=='busystack_git' else ['flutter','analyze','--no-pub']))
    run('engine-runtime-check','busystack_git','dart','run','tool/check_git.dart')
    run('mark-workflow-checks','busymark','python3','-m','unittest','tools/test_official_flutter_workflow.py')
elif phase=='mark-final-checks':
    # The audit phase already analyzed production and resolved both native gates
    # against these same pinned sources. Bind those completed checks to source.
    sdk=json.loads(subprocess.check_output(['flutter','--version','--machine'],env=env,text=True))
    assert sdk['frameworkVersion']=='3.47.5' and sdk['dartSdkVersion'].startswith('3.13.4')
    assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=root/'flutter')
    data=dict(sdk=sdk,mark=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busymark',text=True).strip(),
      files=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busyfiles',text=True).strip(),
      dependencies=json.loads((inputs/'busymark/tool/shared_dependencies.json').read_text()))
    (root/'sidebar-refinement-20261101/final-sources.json').write_text(json.dumps(data,indent=2))
elif phase=='refinement-final':
    run('final-mark-analyze','busymark','flutter','analyze','--no-pub')
    run('final-host-native-adapter','busymark/tools/git_ui_audit','dart','run','bin/check.dart')
    run('final-format','busymark','python3',str(root/'sidebar_refinement_format.py'))
    run('final-mark-pins','busymark','python3','tools/checkout_shared_dependencies.py','--check')
    data=json.loads((root/'sidebar-refinement-20261101/final-sources.json').read_text())
    data['mark']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busymark',text=True).strip()
    data['productionSource']=data['mark']
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=inputs/'busymark')
    (root/'sidebar-refinement-20261101/final-sources.json').write_text(json.dumps(data,indent=2))
elif phase=='tool-final-checks':
    run('host-tool-final-pub','busymark/tools/git_ui_audit','dart','pub','get','--offline','--enforce-lockfile')
    run('host-tool-final-analyze','busymark/tools/git_ui_audit','dart','analyze')
    run('host-tool-final-selftest','busymark/tools/git_ui_audit','dart','run','bin/check.dart','--self-test')
    run('host-tool-final-audit','busymark/tools/git_ui_audit','dart','run','bin/check.dart')
    original=root/'sidebar-refinement-20261101/format-checks.json'
    if original.exists() and not (original.parent/'format-before-tool-resolution.json').exists():
        original.rename(original.parent/'format-before-tool-resolution.json')
    run('final-format-checks','busymark','python3',str(root/'commit_correction_format.py'))
    # The final tooling commit changes no production/runtime source.
    run('production-source-equivalence','busymark','git','diff','--exit-code','3c566f078c384bc0f8eb55ddad6a490c1a5eda46','HEAD','--','lib','linux','pubspec.yaml','pubspec.lock')
    data=json.loads((root/'sidebar-refinement-20261101/final-sources.json').read_text())
    data['mark']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busymark',text=True).strip()
    data['hostTestsSource']='3c566f078c384bc0f8eb55ddad6a490c1a5eda46'
    (root/'sidebar-refinement-20261101/final-sources.json').write_text(json.dumps(data,indent=2))
elif phase=='engine-tests':
    run('engine-tests','busystack_git','dart','test','--concurrency=1','--reporter=json')
elif phase=='shared-tests':
    run('shared-tests','busystack_git_flutter','flutter','test','--no-pub','--concurrency=1','--machine')
    run('shared-real-repositories','busystack_git_flutter','flutter','test','--no-pub','--concurrency=1','--dart-define=BUSYSTACK_TEST_GIT='+env['BUSYSTACK_TEST_GIT'],'--dart-define=BUSYSTACK_GIT_HELPER_PATH='+env['BUSYSTACK_GIT_HELPER_PATH'],'tool/comparison_real_repository_test.dart','tool/commit_real_repository_test.dart','tool/conflict_grouping_real_repository_test.dart','--machine')
elif phase=='mark-tests':
    run('mark-host-tests','busymark','flutter','test','--no-pub','--concurrency=1','--machine','test/src/app_smoke_test.dart','test/src/workspace_controller_test.dart','test/src/localization_audit_test.dart','test/src/app_settings_test.dart','test/src/git')
elif phase=='files-tests':
    run('files-git-ipc-tests','busyfiles','dart','tool/run_package_executable.dart','test','test','--concurrency=1','--reporter=json','packages/busyfiles_ipc/test/git_protocol_test.dart','apps/busyfilesd/test/git_ipc_test.dart','apps/busyfilesd/test/git_content_fingerprint_test.dart')
    ui=inputs/'busyfiles/apps/busyfiles_ui/test'
    tests=[str(p.relative_to(ui.parent)) for p in sorted(ui.glob('git_*test.dart'))]
    run('files-ui-git-tests','busyfiles/apps/busyfiles_ui','../../scripts/with-isolated-desktop-session.sh','../../scripts/flutter-busyfiles','test','--no-pub','--concurrency=1','--machine',*tests)
elif phase=='native-tests':
    run('native-configure','busystack_git_flutter','cmake','-S','linux/native','-B','build/native','-G','Ninja')
    run('native-build','busystack_git_flutter','cmake','--build','build/native','--parallel','2')
    run('native-tests','busystack_git_flutter','xvfb-run','-a','dbus-run-session','--','ctest','--test-dir','build/native','--output-on-failure')
elif phase=='mark-release':
    run('mark-release','busymark','flutter','build','linux','--release','--no-pub')
elif phase=='files-release':
    env['BUSYFILES_SHARED_DEPENDENCY_CACHE']=str(inputs)
    run('files-release','busyfiles','bash','scripts/build-release-artifacts.sh',str(root/'sidebar-refinement-20261101/files-release'))
elif phase=='files-developer-release':
    run('files-developer-release','busyfiles/apps/busyfiles_ui','../../scripts/flutter-busyfiles','build','linux','--release','--no-pub')
elif phase=='files-daemon':
    run('files-developer-daemon','busyfiles/apps/busyfilesd','dart','build','cli','-o',str(root/'sidebar-refinement-20261101/files-developer-daemon'))
else:
    raise SystemExit('Unknown phase')

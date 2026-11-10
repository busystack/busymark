from pathlib import Path
import json,os,shutil,subprocess,sys,time
r=Path('/home/ubuntu/busystack-native-git-verification-20261031'); inputs=r/'inputs'; out=r/'log-toolbar-refinement-20261102'
env=dict(os.environ,PATH=str(r/'flutter/bin')+':'+str(r/'node/bin')+':'+os.environ['PATH'],PUB_CACHE=str(r/'pub-cache'),CI='true',TMPDIR='/var/tmp',
 BUSYFILES_FLUTTER_SDK=str(r/'flutter'), BUSYSTACK_TEST_GIT=str(r/'official-assets/git-runtime/bin/git'),
 BUSYSTACK_TEST_GIT_256=str(r/'official-assets/git-runtime/bin/git'),BUSYSTACK_GIT_EXECUTABLE=str(r/'official-assets/git-runtime/bin/git'),
 BUSYSTACK_GIT_HELPER_PATH=str(r/'official-assets/busystack-git-helper'),
 BUSYFILES_GIO_LIBRARY=str(inputs/'busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so'),
 BUSYFILES_TEST_GIO_LIBRARY=str(inputs/'busyfiles/native/build/libbusyfiles_gio/libbusyfiles_gio.so'))
def run(name,folder,*argv):
 if shutil.disk_usage(r).free<3*1024**3: raise SystemExit('Guest capacity below 3 GiB; no build started')
 base=name;attempt=1
 while (out/(name+'.log')).exists():attempt+=1;name=base+'-attempt'+str(attempt)
 print('START',name,flush=True);start=time.time()
 with (out/(name+'.log')).open('w') as log:
  result=subprocess.run(argv,cwd=inputs/folder,env=env,stdout=log,stderr=subprocess.STDOUT)
 with (out/'commands.jsonl').open('a') as receipt:receipt.write(json.dumps(dict(name=name,cwd=str(inputs/folder),argv=argv,start=start,end=time.time(),exit=result.returncode))+'\n')
 print('END',name,result.returncode,round(time.time()-start,1),flush=True)
 if result.returncode: print((out/(name+'.log')).read_text(errors='replace')[-6000:],flush=True);raise SystemExit(result.returncode)
phase=sys.argv[1]
if phase=='setup':
 for package in ['busystack_git','busystack_git_flutter','busymark','busyfiles','busyfiles/apps/busyfiles_ui']:
  run(package.replace('/','-')+'-pub',package,'dart' if package in ['busystack_git','busyfiles'] else 'flutter','pub','get','--offline','--enforce-lockfile')
elif phase=='audit':
 run('mark-pins','busymark','python3','tools/checkout_shared_dependencies.py','--check')
 run('shared-pins','busystack_git_flutter','python3','tool/checkout_shared_dependencies.py','--check')
 run('files-pins','busyfiles','python3','scripts/ci/checkout-shared-dependencies.py','--check')
 run('mark-l10n-ci','busymark','python3','../busystack_git_flutter/tool/sync_host_localizations.py','--arb','lib/l10n/app_en.arb','--adapter','lib/src/git/application/shared_git_localizations.dart','--class-name','AppLocalizations','--import-uri','../../../l10n/generated/app_localizations.dart','--check')
 run('mark-gen-l10n','busymark','flutter','gen-l10n');run('mark-generated-clean','busymark','git','diff','--exit-code')
 run('files-l10n-ci','busyfiles','python3','../busystack_git_flutter/tool/sync_host_localizations.py','--arb','apps/busyfiles_ui/lib/src/l10n/arb/busyfiles_en.arb','--adapter','apps/busyfiles_ui/lib/src/features/browser/shared_git_localizations.dart','--class-name','BusyFilesStrings','--import-uri','../../l10n/generated/busyfiles_localizations.dart','--named','--check')
 run('files-gen-l10n','busyfiles/apps/busyfiles_ui','flutter','gen-l10n');run('files-generated-clean','busyfiles','git','diff','--exit-code')
 run('native-audit-selftest','busystack_git_flutter','dart','run','tool/test_native_presentation_audit.dart')
 run('native-audit-all','busystack_git_flutter','dart','run','tool/check_native_presentation.dart','lib/src','../busymark/lib/src/git','../busyfiles/apps/busyfiles_ui/lib/src/features/browser/git_workspace.dart')
 run('mark-audit-pub','busymark/tools/git_ui_audit','dart','pub','get','--offline','--enforce-lockfile')
 run('mark-audit-selftest','busymark/tools/git_ui_audit','dart','run','bin/check.dart','--self-test')
 run('mark-audit','busymark/tools/git_ui_audit','dart','run','bin/check.dart')
 for folder in ['busystack_git','busystack_git_flutter','busymark','busyfiles/apps/busyfiles_ui']:
  run(folder.replace('/','-')+'-analyze',folder,*(['dart','analyze'] if folder=='busystack_git' else ['flutter','analyze','--no-pub']))
 run('git-runtime','busystack_git','dart','run','tool/check_git.dart')
 run('mark-workflow-checks','busymark','python3','-m','unittest','tools/test_official_flutter_workflow.py')
 run('native-configure','busystack_git_flutter','cmake','-S','linux/native','-B','build/native','-G','Ninja')
 run('native-build','busystack_git_flutter','cmake','--build','build/native','--parallel','2')
 run('native-tests','busystack_git_flutter','xvfb-run','-a','dbus-run-session','--','ctest','--test-dir','build/native','--output-on-failure')
 sdk=json.loads(subprocess.check_output(['flutter','--version','--machine'],env=env,text=True))
 assert sdk['frameworkVersion']=='3.47.5' and sdk['dartSdkVersion'].startswith('3.13.4')
 assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=r/'flutter')
 (out/'final-sources.json').write_text(json.dumps(dict(sdk=sdk,mark=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busymark',text=True).strip(),files=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busyfiles',text=True).strip(),dependencies=json.loads((inputs/'busymark/tool/shared_dependencies.json').read_text())),indent=2))
elif phase=='shared-tests':
 run('mark-release','busymark','flutter','build','linux','--release','--no-pub')
 subprocess.run(['python3',str(r/'log_toolbar_export.py')],check=True)
 run('shared-tests','busystack_git_flutter','flutter','test','--no-pub','--concurrency=1','--machine')
 run('shared-real-repositories','busystack_git_flutter','flutter','test','--no-pub','--concurrency=1','--dart-define=BUSYSTACK_TEST_GIT='+env['BUSYSTACK_TEST_GIT'],'--dart-define=BUSYSTACK_GIT_HELPER_PATH='+env['BUSYSTACK_GIT_HELPER_PATH'],'tool/comparison_real_repository_test.dart','tool/commit_real_repository_test.dart','tool/conflict_grouping_real_repository_test.dart','--machine')
elif phase=='mark-tests':
 run('mark-host-tests','busymark','flutter','test','--no-pub','--concurrency=1','--machine','test/src/app_smoke_test.dart','test/src/workspace_controller_test.dart','test/src/localization_audit_test.dart','test/src/app_settings_test.dart','test/src/git')
elif phase=='files-tests':
 run('files-git-ipc-tests','busyfiles','dart','tool/run_package_executable.dart','test','test','--concurrency=1','--reporter=json','packages/busyfiles_ipc/test/git_protocol_test.dart','apps/busyfilesd/test/git_ipc_test.dart','apps/busyfilesd/test/git_content_fingerprint_test.dart')
 ui=inputs/'busyfiles/apps/busyfiles_ui/test';tests=[str(p.relative_to(ui.parent)) for p in sorted(ui.glob('git_*test.dart'))]
 run('files-ui-git-tests','busyfiles/apps/busyfiles_ui','../../scripts/with-isolated-desktop-session.sh','../../scripts/flutter-busyfiles','test','--no-pub','--concurrency=1','--machine',*tests)
elif phase=='release':
 assert (out/'release-runtime-receipt.json').exists()
 run('files-ui-release','busyfiles/apps/busyfiles_ui','../../scripts/flutter-busyfiles','build','linux','--release','--no-pub')
 run('files-developer-daemon','busyfiles/apps/busyfilesd','dart','build','cli','-o',str(out/'files-developer-daemon-final'))
elif phase=='focus-final':
 sources=json.loads((out/'final-sources.json').read_text())
 shutil.copyfile(out/'final-sources.json',out/'final-sources-before-focus.json')
 shutil.copyfile(out/'release-runtime-receipt.json',out/'release-runtime-receipt-before-focus.json')
 sources['mark']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busymark',text=True).strip()
 (out/'final-sources.json').write_text(json.dumps(sources,indent=2))
 run('mark-focus-analyze','busymark','flutter','analyze','--no-pub')
 run('native-audit-final-focus','busystack_git_flutter','dart','run','tool/check_native_presentation.dart','lib/src','../busymark/lib/src/git','../busyfiles/apps/busyfiles_ui/lib/src/features/browser/git_workspace.dart')
 run('mark-focus-pins','busymark','python3','tools/checkout_shared_dependencies.py','--check')
 run('mark-focus-l10n-ci','busymark','python3','../busystack_git_flutter/tool/sync_host_localizations.py','--arb','lib/l10n/app_en.arb','--adapter','lib/src/git/application/shared_git_localizations.dart','--class-name','AppLocalizations','--import-uri','../../../l10n/generated/app_localizations.dart','--check')
 run('mark-focus-release','busymark','flutter','build','linux','--release','--no-pub')
 subprocess.run(['python3',str(r/'log_toolbar_export.py')],check=True)
elif phase=='files-inline-preflight':
 sources=json.loads((out/'final-sources.json').read_text())
 shutil.copyfile(out/'final-sources.json',out/'final-sources-before-inline.json')
 shutil.copyfile(out/'files-native-runtime.json',out/'files-native-runtime-before-inline.json')
 sources['files']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busyfiles',text=True).strip()
 (out/'final-sources.json').write_text(json.dumps(sources,indent=2))
 run('files-analyze-final','busyfiles/apps/busyfiles_ui','../../scripts/flutter-busyfiles','analyze','--no-pub')
 run('files-pins-final','busyfiles','python3','scripts/ci/checkout-shared-dependencies.py','--check')
 run('native-audit-final','busystack_git_flutter','dart','run','tool/check_native_presentation.dart','lib/src','../busymark/lib/src/git','../busyfiles/apps/busyfiles_ui/lib/src/features/browser/git_workspace.dart')
elif phase=='files-release-final':
 run('files-ui-release-final','busyfiles/apps/busyfiles_ui','../../scripts/flutter-busyfiles','build','linux','--release','--no-pub')
elif phase=='files-debug':
 run('files-ui-debug','busyfiles/apps/busyfiles_ui','../../scripts/flutter-busyfiles','build','linux','--debug','--no-pub')
 run('files-developer-daemon','busyfiles/apps/busyfilesd','dart','build','cli','-o',str(out/'files-developer-daemon-final'))
elif phase=='localized-final':
 for leaf in ['final-sources.json','release-runtime-receipt.json']:
  previous=out/(Path(leaf).stem+'-before-localization.json')
  assert not previous.exists()
  shutil.copyfile(out/leaf,previous)
 run('mark-l10n-ci-final','busymark','python3','../busystack_git_flutter/tool/sync_host_localizations.py','--arb','lib/l10n/app_en.arb','--adapter','lib/src/git/application/shared_git_localizations.dart','--class-name','AppLocalizations','--import-uri','../../../l10n/generated/app_localizations.dart','--check')
 run('mark-gen-l10n-final','busymark','flutter','gen-l10n')
 run('mark-generated-clean-final','busymark','git','diff','--exit-code')
 run('mark-analyze-final','busymark','flutter','analyze','--no-pub')
 run('mark-pins-final','busymark','python3','tools/checkout_shared_dependencies.py','--check')
 sources=json.loads((out/'final-sources.json').read_text())
 sources['mark']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=inputs/'busymark',text=True).strip()
 (out/'final-sources.json').write_text(json.dumps(sources,indent=2))
 run('mark-release-final','busymark','flutter','build','linux','--release','--no-pub')
 subprocess.run(['python3',str(r/'log_toolbar_export.py')],check=True)
elif phase=='format':
 run('final-format','busymark','python3',str(r/'log_toolbar_format.py'))
else:raise SystemExit('Unknown phase')

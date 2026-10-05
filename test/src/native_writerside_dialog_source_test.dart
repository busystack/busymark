import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux Writerside title and duplicate dialogs are GTK-owned', () {
    final host = File(
      'linux/runner/writerside_dialog_host.cc',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(host, contains('gtk_dialog_new_with_buttons'));
    expect(host, contains('show_duplicate_topic'));
    expect(host, contains('show_edit_title'));
    expect(host, contains('gtk_expander_new'));
    expect(host, contains('gtk_link_button_new_with_label'));
    expect(workspace, contains('NativeWritersideDialogService()'));
    expect(workspace, contains('.showEditTitle('));
    expect(workspace, contains('.showDuplicateTopic('));
  });

  final nativeDisplay =
      Platform.environment['BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY'];
  test(
    'GTK Writerside contents follow application direction, filenames stay LTR',
    () async {
      final temporary = Directory.systemTemp.createTempSync(
        'busymark-native-dialog-test-',
      );
      addTearDown(() => temporary.deleteSync(recursive: true));
      final engine = Directory('linux/flutter/ephemeral').absolute.path;
      final flags = await Process.run('pkg-config', [
        '--cflags',
        '--libs',
        'gtk+-3.0',
      ]);
      expect(flags.exitCode, 0, reason: '${flags.stderr}');
      final binary = '${temporary.path}/writerside-dialog-test';
      final compiled = await Process.run(Platform.environment['CXX'] ?? 'c++', [
        '-std=c++14',
        '-Wall',
        '-Werror',
        '-I$engine',
        'test/support/native_writerside_dialog_host_test.cc',
        '-L$engine',
        '-lflutter_linux_gtk',
        '-Wl,-rpath,$engine',
        '-Wl,--wrap=fl_method_call_respond_success',
        ...'${flags.stdout}'.trim().split(RegExp(r'\s+')),
        '-o',
        binary,
      ]);
      expect(compiled.exitCode, 0, reason: '${compiled.stderr}');
      final result = await Process.run(
        binary,
        const [],
        environment: {
          'DISPLAY': nativeDisplay!,
          'GDK_BACKEND': 'x11',
          'NO_AT_BRIDGE': '1',
        },
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    skip: !Platform.isLinux || nativeDisplay == null
        ? 'Requires a Linux build and an isolated '
              'BUSYMARK_NATIVE_DIALOG_TEST_DISPLAY.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

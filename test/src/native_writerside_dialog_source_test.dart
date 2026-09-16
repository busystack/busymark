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
}

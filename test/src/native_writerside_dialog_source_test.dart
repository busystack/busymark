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
  test(
    'interactive Writerside dialogs reuse the GTK host and Dart callbacks',
    () {
      final host = File(
        'linux/runner/writerside_dialog_host.cc',
      ).readAsStringSync();
      final dialogs = File(
        'lib/src/workspace/presentation/writerside_toc_dialogs.dart',
      ).readAsStringSync();
      for (final method in [
        'showCreateTopic',
        'showRenameTopic',
        'showTocText',
        'showExistingTopicPicker',
      ]) {
        expect(host, contains('"$method"'));
      }
      expect(
        host,
        matches(
          RegExp(r'GTK_DIALOG_MODAL\s*\|\s*GTK_DIALOG_DESTROY_WITH_PARENT'),
        ),
      );
      expect(host, contains('GTK_TEXT_DIR_LTR'));
      expect(host, contains('writersideDialogEvent'));
      expect(host, contains('state->pending'));
      expect(host, contains('gtk_window_set_deletable'));
      expect(host, contains('G_CALLBACK(interactive_key)'));
      expect(
        host,
        contains('interactive_response(nullptr, GTK_RESPONSE_CANCEL, state)'),
      );
      expect(host, contains('g_weak_ref_get'));
      expect(host, contains('if (state->finished) return;'));
      expect(host, contains('reply->revision != state->revision'));
      expect(dialogs, contains('.showRenameTopic('));
      expect(dialogs, contains('.showTocText('));
      expect(dialogs, contains('.showExistingTopicPicker('));
      expect(dialogs, contains('return index == null ? null : topics[index]'));
    },
  );
}

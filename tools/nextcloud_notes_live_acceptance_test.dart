import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'nextcloud_notes_live_acceptance.dart' as acceptance;

void main() {
  test('authenticated Nextcloud Notes acceptance', () async {
    final environment = Platform.environment;
    final credentials = environment['BUSYMARK_NOTES_LIVE_CREDENTIALS'];
    final reportPath = environment['BUSYMARK_NOTES_LIVE_REPORT'];
    final ca = environment['BUSYMARK_NOTES_LIVE_CA'];
    final attachmentReads =
        environment['BUSYMARK_NOTES_LIVE_ATTACHMENT_READS'] == '1';
    final audio = environment['BUSYMARK_NOTES_LIVE_AUDIO'] == '1';
    if (credentials == null ||
        reportPath == null ||
        ((attachmentReads || audio) && ca == null) ||
        (attachmentReads && audio)) {
      throw ArgumentError(
        'Set the private fixture credentials and report paths, and provide a CA for one focused scenario.',
      );
    }
    await acceptance.main([
      credentials,
      reportPath,
      if (ca != null) ca,
      if (attachmentReads) '--attachment-reads',
      if (audio) '--audio',
    ]);
    final report = jsonDecode(await File(reportPath).readAsString()) as Map;
    expect(report['ok'], isTrue, reason: report['failure'] as String?);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

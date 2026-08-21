import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux packages secure AI credential storage consistently', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final workflow = File(
      '.github/workflows/flutter-linux.yml',
    ).readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    final credentialHost = File(
      'linux/runner/secure_credential_host.cc',
    ).readAsStringSync();

    expect(pubspec, isNot(contains('flutter_secure_storage:')));
    expect(credentialHost, contains('secret_password_lookup('));
    expect(credentialHost, contains('secret_password_store('));
    expect(credentialHost, isNot(contains('secret_service_get')));
    expect(credentialHost, isNot(contains('password-manager-service')));
    expect(workflow, contains('libsecret-1-dev'));
    expect(snapcraft, contains('- libsecret-1-dev'));
    expect(snapcraft, contains('- libsecret-1-0'));
    expect(snapcraft, contains('- desktop'));
  });

  test('real local AI qualification covers every shipped action', () {
    final qualification = File(
      'tools/ai_ollama_qualification.dart',
    ).readAsStringSync();

    for (final feature in [
      'AiFeature.editDocument',
      'AiFeature.draftCommitMessage',
    ]) {
      expect(qualification, contains(feature));
    }
    for (final target in [
      'AiEditTargetKind.selection',
      'AiEditTargetKind.insertAfterBlock',
      'AiEditTargetKind.block',
      'AiEditTargetKind.section',
      'AiEditTargetKind.document',
    ]) {
      expect(qualification, contains(target));
    }
    expect(qualification, contains('provider.checkHealth'));
    expect(qualification, contains('AiCoordinator'));
  });
}

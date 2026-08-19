import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux packages secure AI credential storage consistently', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final workflow = File(
      '.github/workflows/flutter-linux.yml',
    ).readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(pubspec, contains('flutter_secure_storage: ^11.0.0'));
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
      'AiFeature.rewrite',
      'AiFeature.shorten',
      'AiFeature.summarize',
      'AiFeature.tone',
      'AiFeature.translate',
      'AiFeature.proofread',
      'AiFeature.draft',
      'AiFeature.explainCode',
      'AiFeature.improveCode',
      'AiFeature.draftCommitMessage',
    ]) {
      expect(qualification, contains(feature));
    }
    expect(qualification, contains('provider.checkHealth'));
    expect(qualification, contains('AiCoordinator'));
  });
}

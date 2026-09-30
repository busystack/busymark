import 'dart:io';
import 'dart:convert';

import 'package:busymark/src/spellcheck/spelling_catalog.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_installer.dart';
import 'package:crypto/crypto.dart';

Future<void> main(List<String> arguments) async {
  final aff = File(arguments[0]);
  final dic = File(arguments[1]);
  final destinationRoot = arguments[2];
  final spec = SpellingDictionaryInstallSpec(
    resourceId: 'en-Test',
    id: 'en-Test',
    locales: const ['en-Test'],
    label: 'Test English',
    sourceRevision: 'fixture',
    affSha256: (await sha256.bind(aff.openRead()).first).toString(),
    dicSha256: (await sha256.bind(dic.openRead()).first).toString(),
    affSize: await aff.length(),
    dicSize: await dic.length(),
    kind: SpellingDictionaryInstallationKind.downloaded,
  );
  try {
    await const SpellingDictionaryPairInstaller().install(
      affSource: aff,
      dicSource: dic,
      spec: spec,
      destinationRoot: destinationRoot,
      validateNativePair: (_, _, _) async {
        stdout.writeln('validating');
        await stdin
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first;
        return 'UTF-8';
      },
    );
  } on FileSystemException {
    exitCode = 2;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

import '../hook/build.dart' as spelling;

void main() {
  test('debug startup accepts a hook request without code assets', () async {
    final temporary = await Directory.systemTemp.createTemp('spelling-hook-');
    addTearDown(() => temporary.delete(recursive: true));
    final output = File('${temporary.path}/output.json');
    final shared = await Directory('${temporary.path}/shared').create();
    final builder = BuildInputBuilder()
      ..setupShared(
        packageRoot: temporary.uri,
        packageName: 'busymark_spellcheck_native',
        outputDirectoryShared: shared.uri,
        outputFile: output.uri,
      )
      ..setupBuildInput(assets: {})
      ..config.setupBuild(linkingEnabled: false);
    final config = File('${temporary.path}/input.json');
    await config.writeAsString(jsonEncode(builder.json));
    await spelling.main(['--config=${config.path}']);
    final result = jsonDecode(await output.readAsString()) as Map;
    expect(result['assets'] ?? [], isEmpty);
    expect(result['dependencies'] ?? [], isEmpty);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service/utils.dart';

Future<void> main(List<String> args) async {
  final log = File(args[0]).readAsStringSync();
  final urls = RegExp(
    r'http://127\.0\.0\.1:\d+/[A-Za-z0-9_=-]+/',
  ).allMatches(log);
  if (urls.isEmpty) throw StateError('Ordinary debug service not ready');
  final service = await vmServiceConnectUri(
    convertToWebSocketUrl(
      serviceProtocolUrl: Uri.parse(urls.last.group(0)!),
    ).toString(),
  );
  try {
    final vm = await service.getVM();
    final isolate = vm.isolates!.firstWhere((i) => i.name == 'main');
    final detail = await service.getIsolate(isolate.id!);
    final library = detail.libraries!.firstWhere(
      (l) => l.uri == 'package:flutter/src/widgets/binding.dart',
    );
    const expressions = {
      'textScale':
          'WidgetsBinding.instance.platformDispatcher.textScaleFactor.toString()',
      'devicePixelRatio':
          'WidgetsBinding.instance.platformDispatcher.views.single.devicePixelRatio.toString()',
    };
    final values = <String, String?>{};
    for (final entry in expressions.entries) {
      final result = await service.evaluate(
        isolate.id!,
        library.id!,
        entry.value,
      );
      if (result is! InstanceRef)
        throw StateError('Read-only diagnostic failed');
      values[entry.key] = result.valueAsString;
    }
    final receipt = {
      'readOnly': true,
      'expressions': expressions,
      'values': values,
    };
    File(args[1]).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
    );
    stdout.writeln(jsonEncode(receipt));
  } finally {
    await service.dispose();
  }
}

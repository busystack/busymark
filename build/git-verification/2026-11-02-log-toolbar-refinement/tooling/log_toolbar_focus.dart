import 'dart:convert';
import 'dart:io';
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/utils.dart';

Future<void> main(List<String> args) async {
  final text = File(args[0]).readAsStringSync();
  final matches = RegExp(r'http://127\.0\.0\.1:\d+/[A-Za-z0-9_=-]+/').allMatches(text).toList();
  if (matches.isEmpty) throw StateError('Ordinary debug VM service not ready');
  final uri = convertToWebSocketUrl(serviceProtocolUrl: Uri.parse(matches.last.group(0)!));
  final service = await vmServiceConnectUri(uri.toString());
  try {
    final vm = await service.getVM();
    final isolate = vm.isolates!.firstWhere((i) => i.name == 'main');
    late Map<String, dynamic> data;
    if (args.length > 2 && args[2] == 'creator') {
      final detail = await service.getIsolate(isolate.id!);
      final library = detail.libraries!.firstWhere((l) => l.uri == 'package:flutter/src/widgets/focus_manager.dart');
      const expression = '(FocusManager.instance.primaryFocus?.context as Element?)?.debugGetCreatorChain(100)';
      final result = await service.evaluate(isolate.id!, library.id!, expression);
      if (result is! InstanceRef) throw StateError('Diagnostic expression failed: $result');
      final full = await service.getObject(isolate.id!, result.id!, offset: 0, count: 100000);
      if (full is! Instance || full.valueAsStringIsTruncated == true) throw StateError('Incomplete focus diagnostic');
      data = {'data': full.valueAsString, 'expression': expression, 'readOnly': true};
    } else {
      final result = await service.callServiceExtension(args.length > 2 ? args[2] : 'ext.flutter.debugDumpFocusTree', isolateId: isolate.id);
      data = result.json!;
    }
    File(args[1]).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln(data['data']);
  } finally { await service.dispose(); }
}

import 'dart:async';

import 'package:busymark/src/platform/native_writerside_dialog_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises both directions of the production dialog protocol.
class TestNativeWritersideDialogHost {
  TestNativeWritersideDialogHost({
    this.channel = const MethodChannel(nativeWritersideDialogChannelName),
  });

  final MethodChannel channel;
  final opened = Completer<Map<Object?, Object?>>();
  final closed = Completer<Object?>();
  final calls = <MethodCall>[];
  late Map<Object?, Object?> arguments;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          arguments = call.arguments as Map<Object?, Object?>;
          if (!opened.isCompleted) opened.complete(arguments);
          return closed.future;
        });
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  Future<Object?> event(Map<String, Object?> values) async {
    const codec = StandardMethodCodec();
    final reply = Completer<Object?>();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(
            MethodCall('writersideDialogEvent', {
              'session': arguments['session'],
              ...values,
            }),
          ),
          (data) {
            try {
              if (data == null) throw MissingPluginException();
              reply.complete(codec.decodeEnvelope(data));
            } catch (error, stack) {
              reply.completeError(error, stack);
            }
          },
        );
    return reply.future;
  }
}

import 'dart:async';

import 'package:busymark/src/platform/linux_gtk_accent_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const method = MethodChannel('test.busymark/gtk_accent');
  const events = EventChannel('test.busymark/gtk_accent/events');
  const eventMethod = MethodChannel('test.busymark/gtk_accent/events');
  const service = LinuxGtkAccentService(channel: method, events: events);
  const blue = Color(0xff336699);
  final bluePayload = {
    'available': true,
    'rgb': [0.2, 0.4, 0.6],
  };
  final greenPayload = {
    'available': true,
    'rgb': [0.0, 0.6, 0.0],
  };

  Future<void> send(Object? payload) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope(payload),
      (_) {},
    );
  }

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(method, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(eventMethod, null);
  });

  test('validates availability, finite normalized RGB and payload shape', () {
    expect(colorFromGtkAccentPayload(bluePayload), blue);
    expect(
      colorFromGtkAccentPayload({
        'available': true,
        'rgb': [0.7843137383460999, 0.5333333611488342, 0.0],
      }),
      const Color(0xffc88800),
    );
    expect(
      colorFromGtkAccentPayload({
        'available': true,
        'rgb': [0, 0, 0],
      }),
      const Color(0xff000000),
    ); // Explicit valid black is not lookup failure.
    for (final payload in [
      null,
      false,
      {},
      {'available': false},
      {'available': true},
      {
        'available': true,
        'rgb': [0, 0],
      },
      {
        'available': true,
        'rgb': [double.nan, 0, 0],
      },
      {
        'available': true,
        'rgb': [double.infinity, 0, 0],
      },
      {
        'available': true,
        'rgb': [-0.1, 0, 0],
      },
      {
        'available': true,
        'rgb': [0, 1.1, 0],
      },
      {
        'available': true,
        'rgb': ['blue', 0, 0],
      },
      {
        'available': 'true',
        'rgb': [0, 0, 0],
      },
    ]) {
      expect(colorFromGtkAccentPayload(payload), isNull, reason: '$payload');
    }
  });

  testWidgets('attaches before snapshot and rejects a superseded snapshot', (
    tester,
  ) async {
    final snapshot = Completer<Object?>();
    var listening = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(eventMethod, (
      call,
    ) async {
      if (call.method == 'listen') listening = true;
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(method, (call) {
      expect(listening, isTrue);
      return snapshot.future;
    });
    final values = <Color?>[];
    final subscription = service.watchAccentColor().listen(values.add);
    await tester.pump();
    await send(greenPayload);
    await tester.pump();
    snapshot.complete(bluePayload);
    await tester.pump();
    expect(values, [const Color(0xff009900)]);
    await subscription.cancel();
  });

  testWidgets('replays current value, deduplicates and safely resubscribes', (
    tester,
  ) async {
    var current = bluePayload;
    var listens = 0;
    var cancels = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(eventMethod, (
      call,
    ) async {
      if (call.method == 'listen') {
        listens++;
        await send(current);
      }
      if (call.method == 'cancel') cancels++;
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      method,
      (_) async => current,
    );
    final values = <Color?>[];
    var subscription = service.watchAccentColor().listen(values.add);
    await tester.pump();
    await send(bluePayload);
    await send({'available': false});
    await send({'available': false});
    await send({
      'available': true,
      'rgb': ['bad'],
    });
    await send(greenPayload);
    await tester.pump();
    expect(values, [blue, null, const Color(0xff009900)]);
    await subscription.cancel();
    current = greenPayload;
    subscription = service.watchAccentColor().listen(values.add);
    await tester.pump();
    expect(values.last, const Color(0xff009900));
    expect(listens, 2);
    await subscription.cancel();
    expect(cancels, 2);
  });

  testWidgets('missing channels are unavailable and cancellable', (
    tester,
  ) async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      method,
      (_) async => throw MissingPluginException(),
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      eventMethod,
      (_) async => throw MissingPluginException(),
    );
    final values = <Color?>[];
    final subscription = service.watchAccentColor().listen(values.add);
    await tester.pump();
    expect(values, [null]);
    expect(await service.readAccentColor(), isNull);
    await subscription.cancel();
  });

  testWidgets('cancellation while snapshot is pending discards its result', (
    tester,
  ) async {
    final snapshot = Completer<Object?>();
    var cancels = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(eventMethod, (
      call,
    ) async {
      if (call.method == 'cancel') cancels++;
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      method,
      (_) => snapshot.future,
    );
    final values = <Color?>[];
    final subscription = service.watchAccentColor().listen(values.add);
    await tester.pump();
    await subscription.cancel();
    snapshot.complete(bluePayload);
    await tester.pump();
    expect(values, isEmpty);
    expect(cancels, 1);
  });
}

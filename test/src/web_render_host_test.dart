import 'dart:async';

import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('busymark.test/visualization');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('sends explicit request IDs and decodes a typed map response', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <String, Object?>{'svg': '<svg/>', 'diagnostics': <Object?>[]};
    });
    const host = PlatformWebRenderHost(channel: channel);

    final response = await host.renderMermaid(
      source: 'graph TD; A-->B',
      theme: VisualizationTheme.dark,
      cancellationToken: VisualizationCancellationToken(),
    );

    expect(response['svg'], '<svg/>');
    expect(received?.method, 'renderMermaid');
    final arguments = received?.arguments as Map<Object?, Object?>;
    expect(arguments['source'], 'graph TD; A-->B');
    expect(arguments['theme'], 'dark');
    expect(arguments['requestId'], isA<String>());
  });

  test(
    'cancels the matching native request and rejects a late success',
    () async {
      final renderCompleter = Completer<Object?>();
      String? renderRequestId;
      String? cancelledRequestId;
      messenger.setMockMethodCallHandler(channel, (call) async {
        final arguments = call.arguments as Map<Object?, Object?>;
        if (call.method == 'renderPlantUml') {
          renderRequestId = arguments['requestId'] as String;
          return renderCompleter.future;
        }
        if (call.method == 'cancelRender') {
          cancelledRequestId = arguments['requestId'] as String;
          return true;
        }
        throw MissingPluginException();
      });
      const host = PlatformWebRenderHost(channel: channel);
      final token = VisualizationCancellationToken();
      final operation = host.renderPlantUml(
        source: '@startuml\nA -> B\n@enduml',
        theme: VisualizationTheme.light,
        cancellationToken: token,
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();
      renderCompleter.complete(<String, Object?>{'svg': '<svg/>'});

      await expectLater(
        operation,
        throwsA(isA<VisualizationCancelledException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cancelledRequestId, renderRequestId);
    },
  );

  test('times out and requests native cancellation', () async {
    final renderCompleter = Completer<Object?>();
    String? renderRequestId;
    String? cancelledRequestId;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      if (call.method == 'renderMermaid') {
        renderRequestId = arguments['requestId'] as String;
        return renderCompleter.future;
      }
      if (call.method == 'cancelRender') {
        cancelledRequestId = arguments['requestId'] as String;
        return true;
      }
      throw MissingPluginException();
    });
    const host = PlatformWebRenderHost(
      channel: channel,
      renderTimeout: Duration(milliseconds: 20),
    );

    await expectLater(
      host.renderMermaid(
        source: 'graph TD; A-->B',
        theme: VisualizationTheme.light,
        cancellationToken: VisualizationCancellationToken(),
      ),
      throwsA(isA<TimeoutException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cancelledRequestId, renderRequestId);
  });

  test('rejects an invalid native response shape', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'not a map');
    const host = PlatformWebRenderHost(channel: channel);

    await expectLater(
      host.renderMermaid(
        source: 'graph TD; A-->B',
        theme: VisualizationTheme.light,
        cancellationToken: VisualizationCancellationToken(),
      ),
      throwsA(isA<WebRenderHostException>()),
    );
  });

  test('decodes OpenAPI references with source locations', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => <String, Object?>{
        'references': <Object?>[
          <String, Object?>{
            'value': 'components.yaml',
            'line': 8,
            'column': 15,
          },
        ],
      },
    );
    const host = PlatformWebRenderHost(channel: channel);

    final references = await host.inspectOpenApiReferences(
      r'$ref: components.yaml',
      VisualizationCancellationToken(),
    );

    expect(references.single.value, 'components.yaml');
    expect(references.single.line, 8);
    expect(references.single.column, 15);
  });

  test('sends PNG bytes to the native image clipboard', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });
    const host = PlatformWebRenderHost(channel: channel);
    final png = Uint8List.fromList([137, 80, 78, 71]);

    await host.copyPngToClipboard(png);

    expect(received?.method, 'copyVisualizationImage');
    final arguments = received?.arguments as Map<Object?, Object?>;
    expect(arguments['png'], png);
  });
}

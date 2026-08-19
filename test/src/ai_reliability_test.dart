import 'dart:async';
import 'dart:convert';

import 'package:busymark/src/ai/ai_coordinator.dart';
import 'package:busymark/src/ai/ai_http_transport.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ai_provider.dart';
import 'package:busymark/src/ai/ai_provider_registry.dart';
import 'package:busymark/src/ai/ollama_ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('coordinator honors Retry-After and caps retry attempts', () async {
    final provider = _RetryProvider(
      failures: 2,
      failure: const AiException(
        AiFailureCode.rateLimited,
        'Rate limited.',
        retryable: true,
        retryAfter: Duration(seconds: 3),
      ),
    );
    final delays = <Duration>[];
    final coordinator = AiCoordinator(
      provider: provider,
      retryDelay: (delay, token) async {
        token.throwIfCancelled();
        delays.add(delay);
      },
    );
    addTearDown(coordinator.dispose);

    final events = await coordinator.stream(_request(maxRetries: 2)).toList();

    expect(provider.attempts, 3);
    expect(delays, [const Duration(seconds: 3), const Duration(seconds: 3)]);
    expect(events.whereType<AiCompleted>(), hasLength(1));
  });

  test('coordinator never retries after partial output', () async {
    final provider = _PartialFailureProvider();
    final coordinator = AiCoordinator(
      provider: provider,
      retryDelay: (_, _) async {},
    );
    addTearDown(coordinator.dispose);

    await expectLater(
      coordinator.stream(_request(maxRetries: 2)).toList(),
      throwsA(isA<AiException>()),
    );
    expect(provider.attempts, 1);
  });

  test('coordinator bounds all retries by one total deadline', () async {
    final provider = _RetryProvider(
      failures: 10,
      failure: const AiException(
        AiFailureCode.connection,
        'Temporarily unavailable.',
        retryable: true,
      ),
    );
    final coordinator = AiCoordinator(
      provider: provider,
      retryDelay: (_, _) => Completer<void>().future,
    );
    addTearDown(coordinator.dispose);

    await expectLater(
      coordinator
          .stream(
            _request(maxRetries: 2, deadline: const Duration(milliseconds: 40)),
          )
          .toList(),
      throwsA(
        isA<AiException>().having(
          (error) => error.code,
          'code',
          AiFailureCode.timeout,
        ),
      ),
    );
    expect(provider.attempts, 1);
  });

  test('global permit pool limits requests across different targets', () async {
    final provider = _PermitProvider();
    final coordinator = AiCoordinator(
      provider: provider,
      maximumConcurrentRequests: 2,
    );
    addTearDown(coordinator.dispose);
    final results = [
      coordinator.stream(_request(id: 'one', target: 'one')).toList(),
      coordinator.stream(_request(id: 'two', target: 'two')).toList(),
      coordinator.stream(_request(id: 'three', target: 'three')).toList(),
    ];
    await provider.waitForStarts(2);

    expect(provider.maximumActive, 2);
    expect(provider.startedIds, isNot(contains('three')));
    provider.finish('one');
    await provider.waitForStarts(3);
    expect(provider.startedIds, contains('three'));
    provider
      ..finish('two')
      ..finish('three');

    await Future.wait(results);
    expect(provider.maximumActive, 2);
  });

  test(
    'request-id cancellation cannot cancel a newer request for the target',
    () async {
      final provider = _PermitProvider();
      final coordinator = AiCoordinator(provider: provider);
      addTearDown(coordinator.dispose);
      final first = coordinator
          .stream(_request(id: 'old', target: 'same'))
          .toList();
      final firstExpectation = expectLater(first, throwsA(isA<AiException>()));
      await provider.waitForStarts(1);
      final second = coordinator
          .stream(_request(id: 'new', target: 'same'))
          .toList();
      await provider.waitForStarts(2);

      coordinator.cancelRequest('old');
      expect(provider.tokens['new']?.isCancelled, isFalse);
      provider.finish('new');

      await firstExpectation;
      expect(await second, contains(isA<AiCompleted>()));
    },
  );

  test(
    'model fallback stays inside the explicitly selected provider',
    () async {
      final local = _ModelFallbackProvider(AiProviderKind.ollamaLocal);
      final cloud = _ModelFallbackProvider(AiProviderKind.openAi);
      final coordinator = AiCoordinator(
        registry: AiProviderRegistry([local, cloud]),
      );
      addTearDown(coordinator.dispose);
      final request = _request().copyWithModels(['unsupported', 'local-good']);

      await coordinator.stream(request).toList();

      expect(local.modelsAttempted, ['unsupported', 'local-good']);
      expect(cloud.modelsAttempted, isEmpty);
    },
  );

  test(
    'Ollama uses an absolute deadline even while bytes keep arriving',
    () async {
      final provider = OllamaAiProvider(
        client: _ContinuousOllamaClient(),
        endpoint: 'http://127.0.0.1:11434',
      );
      final token = AiCancellationToken();

      await expectLater(
        provider
            .stream(
              _request(deadline: const Duration(milliseconds: 40)),
              cancellationToken: token,
            )
            .toList(),
        throwsA(
          isA<AiException>().having(
            (error) => error.code,
            'code',
            AiFailureCode.timeout,
          ),
        ),
      );
      await token.dispose();
    },
  );

  test(
    'cancellation interrupts the preliminary Ollama model request',
    () async {
      final client = _NeverRespondingClient();
      final provider = OllamaAiProvider(
        client: client,
        endpoint: 'http://127.0.0.1:11434',
      );
      final token = AiCancellationToken();
      final future = provider.listModels(cancellationToken: token);
      await Future<void>.delayed(Duration.zero);

      token.cancel();

      await expectLater(
        future,
        throwsA(
          isA<AiException>().having(
            (error) => error.code,
            'code',
            AiFailureCode.cancelled,
          ),
        ),
      );
      await token.dispose();
      client.complete();
    },
  );

  test('Retry-After supports seconds and HTTP dates without negatives', () {
    final now = DateTime.utc(2026, 8, 19, 12);
    expect(
      AiHttpTransport.parseRetryAfter('7', now: now),
      const Duration(seconds: 7),
    );
    expect(
      AiHttpTransport.parseRetryAfter(
        'Wed, 19 Aug 2026 12:00:05 GMT',
        now: now,
      ),
      const Duration(seconds: 5),
    );
    expect(
      AiHttpTransport.parseRetryAfter(
        'Wed, 19 Aug 2026 11:59:00 GMT',
        now: now,
      ),
      Duration.zero,
    );
    expect(AiHttpTransport.parseRetryAfter('invalid', now: now), isNull);
  });
}

AiRequest _request({
  String id = 'request',
  String target = 'target',
  int maxRetries = 0,
  Duration deadline = const Duration(seconds: 5),
}) => AiPromptBuilder.build(
  id: id,
  targetId: target,
  feature: AiFeature.rewrite,
  scope: AiScope.selection,
  input: 'Original text.',
  model: 'test-model',
  sourceRevision: 1,
  maxRetries: maxRetries,
  deadline: deadline,
);

extension on AiRequest {
  AiRequest copyWithModels(List<String> models) => AiRequest(
    id: id,
    targetId: targetId,
    provider: provider,
    feature: feature,
    scope: scope,
    input: input,
    modelCandidates: models,
    sourceRevision: sourceRevision,
    systemPrompt: systemPrompt,
    userPrompt: userPrompt,
    maxInputTokens: maxInputTokens,
    maxTotalInputTokens: maxTotalInputTokens,
    maxOutputTokens: maxOutputTokens,
    maxRetries: maxRetries,
    deadline: deadline,
    contentFormat: contentFormat,
    promptVersion: promptVersion,
  );
}

abstract class _TestProvider implements AiProvider {
  _TestProvider(this.kind);

  final AiProviderKind kind;

  @override
  String get id => kind.id;

  @override
  AiProviderCapabilities get capabilities => AiProviderCapabilities(
    kind: kind,
    streaming: true,
    modelDiscovery: false,
    maximumConcurrentRequests: 2,
    recommendedModels: const {},
  );

  @override
  Future<AiHealthResult> checkHealth({
    required String model,
    required AiCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<List<AiModelInfo>> listModels({
    AiCancellationToken? cancellationToken,
  }) async => const [];
}

class _RetryProvider extends _TestProvider {
  _RetryProvider({required this.failures, required this.failure})
    : super(AiProviderKind.ollamaLocal);

  final int failures;
  final AiException failure;
  var attempts = 0;

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    attempts += 1;
    if (attempts <= failures) {
      throw failure;
    }
    yield const AiTextDelta('Revised text.');
    yield const AiCompleted();
  }
}

class _PartialFailureProvider extends _TestProvider {
  _PartialFailureProvider() : super(AiProviderKind.ollamaLocal);

  var attempts = 0;

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    attempts += 1;
    yield const AiTextDelta('Partial');
    throw const AiException(
      AiFailureCode.connection,
      'Connection failed.',
      retryable: true,
    );
  }
}

class _PermitProvider extends _TestProvider {
  _PermitProvider() : super(AiProviderKind.ollamaLocal);

  final completions = <String, Completer<void>>{};
  final tokens = <String, AiCancellationToken>{};
  final startedIds = <String>[];
  var active = 0;
  var maximumActive = 0;
  final _changed = StreamController<void>.broadcast();

  Future<void> waitForStarts(int count) async {
    while (startedIds.length < count) {
      await _changed.stream.first;
    }
  }

  void finish(String id) => completions[id]!.complete();

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    tokens[request.id] = cancellationToken;
    final completion = completions.putIfAbsent(request.id, Completer<void>.new);
    startedIds.add(request.id);
    active += 1;
    if (active > maximumActive) {
      maximumActive = active;
    }
    _changed.add(null);
    try {
      final cancelled = Object();
      final result = await Future.any<Object?>([
        completion.future,
        cancellationToken.whenCancelled.then<Object?>((_) => cancelled),
      ]);
      if (identical(result, cancelled)) {
        cancellationToken.throwIfCancelled();
      }
      yield const AiTextDelta('Revised text.');
      yield const AiCompleted();
    } finally {
      active -= 1;
    }
  }
}

class _ModelFallbackProvider extends _TestProvider {
  _ModelFallbackProvider(super.kind);

  final modelsAttempted = <String>[];

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    modelsAttempted.add(request.model);
    if (request.model != 'local-good') {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Unsupported model.',
      );
    }
    yield const AiTextDelta('Revised text.');
    yield const AiCompleted();
  }
}

class _ContinuousOllamaClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path == '/api/tags') {
      return _jsonResponse('{"models":[{"name":"test-model"}]}');
    }
    if (request.url.path == '/api/show') {
      return _jsonResponse(
        '{"capabilities":["completion"],'
        '"model_info":{"test.context_length":32768}}',
      );
    }
    return http.StreamedResponse(_continuousRecords(), 200);
  }

  Stream<List<int>> _continuousRecords() async* {
    for (var index = 0; index < 100; index += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      yield utf8.encode('{"message":{"content":"x"},"done":false}\n');
    }
  }
}

class _NeverRespondingClient extends http.BaseClient {
  final _response = Completer<http.StreamedResponse>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _response.future;

  void complete() {
    if (!_response.isCompleted) {
      _response.complete(_jsonResponse('{"models":[]}'));
    }
  }
}

http.StreamedResponse _jsonResponse(String value) => http.StreamedResponse(
  Stream.value(utf8.encode(value)),
  200,
  headers: const {'content-type': 'application/json'},
);

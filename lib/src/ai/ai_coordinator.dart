import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'ai_http_transport.dart';
import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_provider.dart';
import 'ai_provider_registry.dart';

typedef AiRetryDelay =
    Future<void> Function(
      Duration delay,
      AiCancellationToken cancellationToken,
    );
typedef AiUsageObserver = FutureOr<void> Function(AiUsage usage);

class AiCoordinator {
  AiCoordinator({
    AiProvider? provider,
    AiProviderRegistry? registry,
    AiMarkdownGuard markdownGuard = const AiMarkdownGuard(),
    AiRetryDelay retryDelay = _defaultRetryDelay,
    AiUsageObserver? onUsage,
    int maximumConcurrentRequests = 2,
    Random? retryRandom,
  }) : assert(provider != null || registry != null),
       _registry = registry ?? AiProviderRegistry([provider!]),
       _markdownGuard = markdownGuard,
       _retryDelay = retryDelay,
       _onUsage = onUsage,
       _retryRandom = retryRandom ?? Random(),
       _permits = _AiPermitPool(maximumConcurrentRequests);

  final AiProviderRegistry _registry;
  final AiMarkdownGuard _markdownGuard;
  final AiRetryDelay _retryDelay;
  final AiUsageObserver? _onUsage;
  final Random _retryRandom;
  final _active = <String, _ActiveAiRequest>{};
  final _AiPermitPool _permits;
  var _disposed = false;

  Stream<AiStreamEvent> stream(AiRequest request) async* {
    if (_disposed) {
      throw const AiException(
        AiFailureCode.cancelled,
        'The AI coordinator has been disposed.',
      );
    }
    AiPolicy.validateRequest(request);
    final previous = _active.remove(request.targetId);
    previous?.token.cancel();
    final active = _ActiveAiRequest(request.id, AiCancellationToken());
    _active[request.targetId] = active;
    var acquired = false;
    try {
      await _permits.acquire(active.token);
      acquired = true;
      _requireCurrent(request, active);
      final totalDeadline = AiDeadline(request.deadline);
      var effectiveRequest = request;
      if (request.hierarchicalChunks.isNotEmpty) {
        final summaries = <String>[];
        for (
          var index = 0;
          index < request.hierarchicalChunks.length;
          index += 1
        ) {
          _requireCurrent(request, active);
          final stage = request.summaryStage(
            stageId: 'section-$index',
            stageInput: request.hierarchicalChunks[index],
            task:
                'Summarize this document section faithfully and concisely. Preserve technical names and do not add facts.',
            outputTokens: 1200,
          );
          summaries.add(
            await _collectValidated(stage, request, active, totalDeadline),
          );
        }
        effectiveRequest = request.synthesisFromSummaries(
          summaries
              .asMap()
              .entries
              .map((entry) => 'Section ${entry.key + 1}:\n${entry.value}')
              .join('\n\n'),
        );
        AiPolicy.validateRequest(effectiveRequest);
      }
      final output = StringBuffer();
      var outputBytes = 0;
      var completed = false;
      await for (final event in _providerEvents(
        effectiveRequest,
        active.token,
        totalDeadline,
      )) {
        _requireCurrent(request, active);
        switch (event) {
          case AiTextDelta(:final text):
            if (completed) {
              throw const AiException(
                AiFailureCode.malformedResponse,
                'The AI provider returned content after completion.',
              );
            }
            output.write(text);
            outputBytes += utf8.encode(text).length;
            if (outputBytes > AiPolicy.maxGeneratedOutputBytes) {
              throw const AiException(
                AiFailureCode.responseTooLarge,
                'The AI proposal is too large.',
              );
            }
          case AiUsageEvent(:final usage):
            await _recordUsage(usage);
          case AiCompleted():
            if (completed) {
              throw const AiException(
                AiFailureCode.malformedResponse,
                'The AI provider completed the request more than once.',
              );
            }
            _markdownGuard.validate(request, output.toString());
            completed = true;
          case AiStarted():
            break;
        }
        yield event;
      }
      if (!completed) {
        throw const AiException(
          AiFailureCode.malformedResponse,
          'The AI provider ended before completing the proposal.',
          retryable: true,
        );
      }
    } finally {
      if (acquired) {
        _permits.release();
      }
      if (_isCurrent(request, active)) {
        _active.remove(request.targetId);
      }
      await active.token.dispose();
    }
  }

  Future<String> _collectValidated(
    AiRequest stage,
    AiRequest parent,
    _ActiveAiRequest active,
    AiDeadline totalDeadline,
  ) async {
    final output = StringBuffer();
    var completed = false;
    await for (final event in _providerEvents(
      stage,
      active.token,
      totalDeadline,
    )) {
      _requireCurrent(parent, active);
      switch (event) {
        case AiTextDelta(:final text):
          output.write(text);
        case AiUsageEvent(:final usage):
          await _recordUsage(usage);
        case AiCompleted():
          completed = true;
        case AiStarted():
          break;
      }
    }
    if (!completed) {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'The AI provider ended a summary stage before completion.',
        retryable: true,
      );
    }
    _markdownGuard.validate(stage, output.toString());
    return output.toString();
  }

  Stream<AiStreamEvent> _providerEvents(
    AiRequest request,
    AiCancellationToken cancellationToken,
    AiDeadline totalDeadline,
  ) async* {
    final provider = _registry.require(request.provider);
    AiException? lastFailure;
    for (
      var modelIndex = 0;
      modelIndex < request.modelCandidates.length;
      modelIndex += 1
    ) {
      final routed = request.copyWithModel(request.modelCandidates[modelIndex]);
      for (var attempt = 0; attempt <= request.maxRetries; attempt += 1) {
        cancellationToken.throwIfCancelled();
        final remaining = totalDeadline.remaining;
        if (remaining == Duration.zero) {
          throw totalDeadline.timeout(
            'The AI request did not finish before its total deadline.',
          );
        }
        final attemptRequest = routed.copyWithDeadline(remaining);
        var emittedText = false;
        try {
          await for (final event in provider.stream(
            attemptRequest,
            cancellationToken: cancellationToken,
          )) {
            if (event is AiTextDelta && event.text.isNotEmpty) {
              emittedText = true;
            }
            yield event;
          }
          return;
        } on AiException catch (error) {
          lastFailure = error;
          if (error.code == AiFailureCode.cancelled ||
              error.code == AiFailureCode.superseded ||
              emittedText) {
            rethrow;
          }
          final canRetry = error.retryable && attempt < request.maxRetries;
          if (canRetry) {
            await totalDeadline.wait(
              _retryDelay(
                error.retryAfter ?? _backoff(attempt),
                cancellationToken,
              ),
              cancellationToken,
              timeoutMessage:
                  'The AI request did not finish before its total deadline.',
            );
            continue;
          }
          final canTryNextModel =
              modelIndex + 1 < request.modelCandidates.length &&
              error.statusCode != 401 &&
              error.statusCode != 403;
          if (!canTryNextModel) {
            rethrow;
          }
          break;
        }
      }
    }
    throw lastFailure ??
        const AiException(
          AiFailureCode.rejected,
          'No configured AI model could complete the request.',
        );
  }

  Future<void> _recordUsage(AiUsage usage) async {
    final observer = _onUsage;
    if (observer == null) {
      return;
    }
    try {
      await observer(usage);
    } on Object {
      // Usage persistence must never invalidate an otherwise valid proposal.
    }
  }

  void cancelRequest(String requestId) {
    for (final entry in _active.entries.toList(growable: false)) {
      if (entry.value.requestId == requestId) {
        _active.remove(entry.key)?.token.cancel();
        return;
      }
    }
  }

  void cancelTarget(String targetId) {
    _active.remove(targetId)?.token.cancel();
  }

  @Deprecated('Use cancelRequest so a stale dialog cannot cancel newer work.')
  void cancel(String targetId) => cancelTarget(targetId);

  Future<void> dispose() async {
    _disposed = true;
    final active = _active.values.toList(growable: false);
    _active.clear();
    for (final request in active) {
      request.token.cancel();
      await request.token.dispose();
    }
    await _permits.dispose();
  }

  void _requireCurrent(AiRequest request, _ActiveAiRequest active) {
    if (!_isCurrent(request, active)) {
      throw const AiException(
        AiFailureCode.superseded,
        'A newer AI request replaced this proposal.',
      );
    }
  }

  bool _isCurrent(AiRequest request, _ActiveAiRequest active) {
    return identical(_active[request.targetId], active) &&
        active.requestId == request.id &&
        !active.token.isCancelled;
  }

  Duration _backoff(int attempt) {
    final exponential = (500 * (1 << attempt)).clamp(500, 8000);
    final jitter = _retryRandom.nextInt(251);
    return Duration(milliseconds: (exponential + jitter).clamp(500, 8000));
  }
}

class _ActiveAiRequest {
  const _ActiveAiRequest(this.requestId, this.token);

  final String requestId;
  final AiCancellationToken token;
}

class _AiPermitPool {
  _AiPermitPool(this.maximum) : assert(maximum > 0);

  final int maximum;
  final _waiting = <_AiPermitWaiter>[];
  var _active = 0;
  var _disposed = false;

  Future<void> acquire(AiCancellationToken token) async {
    token.throwIfCancelled();
    if (_disposed) {
      throw const AiException(
        AiFailureCode.cancelled,
        'The AI coordinator has been disposed.',
      );
    }
    if (_active < maximum) {
      _active += 1;
      return;
    }
    final waiter = _AiPermitWaiter(token);
    _waiting.add(waiter);
    final cancelled = Object();
    final result = await Future.any<Object?>([
      waiter.ready.future,
      token.whenCancelled.then<Object?>((_) => cancelled),
    ]);
    if (identical(result, cancelled)) {
      if (!_waiting.remove(waiter) && waiter.granted) {
        release();
      }
      token.throwIfCancelled();
    }
    if (token.isCancelled) {
      if (waiter.granted) {
        release();
      }
      token.throwIfCancelled();
    }
  }

  void release() {
    if (_active > 0) {
      _active -= 1;
    }
    _grantWaiting();
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final waiter in _waiting) {
      if (!waiter.ready.isCompleted) {
        waiter.ready.completeError(
          const AiException(
            AiFailureCode.cancelled,
            'The AI coordinator has been disposed.',
          ),
        );
      }
    }
    _waiting.clear();
  }

  void _grantWaiting() {
    if (_disposed) {
      return;
    }
    while (_active < maximum && _waiting.isNotEmpty) {
      final waiter = _waiting.removeAt(0);
      if (waiter.token.isCancelled) {
        continue;
      }
      _active += 1;
      waiter.granted = true;
      waiter.ready.complete();
    }
  }
}

class _AiPermitWaiter {
  _AiPermitWaiter(this.token);

  final AiCancellationToken token;
  final ready = Completer<void>();
  var granted = false;
}

Future<void> _defaultRetryDelay(
  Duration delay,
  AiCancellationToken cancellationToken,
) async {
  if (delay <= Duration.zero) {
    cancellationToken.throwIfCancelled();
    return;
  }
  final cancelled = Object();
  final result = await Future.any<Object?>([
    Future<void>.delayed(delay),
    cancellationToken.whenCancelled.then<Object?>((_) => cancelled),
  ]);
  if (identical(result, cancelled)) {
    cancellationToken.throwIfCancelled();
  }
}

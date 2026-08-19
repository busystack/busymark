import 'dart:async';

import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_provider.dart';

class AiCoordinator {
  AiCoordinator({
    required AiProvider provider,
    AiMarkdownGuard markdownGuard = const AiMarkdownGuard(),
  }) : _provider = provider,
       _markdownGuard = markdownGuard;

  final AiProvider _provider;
  final AiMarkdownGuard _markdownGuard;
  final _active = <String, _ActiveAiRequest>{};
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
    final output = StringBuffer();
    var completed = false;
    try {
      await for (final event in _provider.stream(
        request,
        cancellationToken: active.token,
      )) {
        if (!_isCurrent(request, active)) {
          throw const AiException(
            AiFailureCode.superseded,
            'A newer AI request replaced this proposal.',
          );
        }
        if (event is AiTextDelta) {
          if (completed) {
            throw const AiException(
              AiFailureCode.malformedResponse,
              'The AI provider returned content after completion.',
            );
          }
          output.write(event.text);
          if (output.length > AiPolicy.maxOutputCharacters) {
            throw const AiException(
              AiFailureCode.responseTooLarge,
              'The AI proposal is too large.',
            );
          }
        } else if (event is AiCompleted) {
          if (completed) {
            throw const AiException(
              AiFailureCode.malformedResponse,
              'The AI provider completed the request more than once.',
            );
          }
          _markdownGuard.validate(request, output.toString());
          completed = true;
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
      if (_isCurrent(request, active)) {
        _active.remove(request.targetId);
      }
      await active.token.dispose();
    }
  }

  void cancel(String targetId) {
    _active.remove(targetId)?.token.cancel();
  }

  Future<void> dispose() async {
    _disposed = true;
    final active = _active.values.toList(growable: false);
    _active.clear();
    for (final request in active) {
      request.token.cancel();
      await request.token.dispose();
    }
  }

  bool _isCurrent(AiRequest request, _ActiveAiRequest active) {
    return identical(_active[request.targetId], active) &&
        active.requestId == request.id &&
        !active.token.isCancelled;
  }
}

class _ActiveAiRequest {
  const _ActiveAiRequest(this.requestId, this.token);

  final String requestId;
  final AiCancellationToken token;
}

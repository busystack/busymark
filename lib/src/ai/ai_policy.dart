import 'dart:io';

import '../markdown/markdown_fence.dart';
import 'ai_models.dart';

abstract final class AiPolicy {
  static const maxSelectionCharacters = 40000;
  static const maxDocumentCharacters = 100000;
  static const maxOutputCharacters = 100000;

  static Uri validateLocalOllamaEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Enter an Ollama origin such as http://127.0.0.1:11434.',
      );
    }
    if (!_isLoopbackHost(uri.host)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Local AI permits loopback Ollama endpoints only.',
      );
    }
    return uri.replace(path: '/');
  }

  static void validateRequest(AiRequest request) {
    if (request.model.trim().isEmpty) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Choose an installed Ollama model in Settings.',
      );
    }
    if (request.input.trim().isEmpty && request.feature != AiFeature.draft) {
      throw const AiException(
        AiFailureCode.validation,
        'Select text or open a non-empty document first.',
      );
    }
    final limit = request.scope == AiScope.document
        ? maxDocumentCharacters
        : maxSelectionCharacters;
    if (request.input.length > limit) {
      throw AiException(
        AiFailureCode.validation,
        'The requested AI context exceeds the $limit character limit.',
      );
    }
  }

  static bool _isLoopbackHost(String host) {
    if (host.toLowerCase() == 'localhost') {
      return true;
    }
    final address = InternetAddress.tryParse(host);
    return address?.isLoopback ?? false;
  }
}

class AiMarkdownGuard {
  const AiMarkdownGuard();

  void validate(AiRequest request, String output) {
    final normalized = output.trim();
    if (normalized.isEmpty) {
      throw const AiException(
        AiFailureCode.validation,
        'The model returned an empty proposal.',
      );
    }
    if (output.length > AiPolicy.maxOutputCharacters) {
      throw const AiException(
        AiFailureCode.responseTooLarge,
        'The AI proposal is too large.',
      );
    }
    if (_looksWrappedInFence(normalized)) {
      throw const AiException(
        AiFailureCode.validation,
        'The model wrapped the proposal in a code fence.',
      );
    }
    if (request.contentFormat != AiContentFormat.markdown ||
        !request.feature.preservesExistingMarkdown) {
      return;
    }
    _requireSameProtectedValues(
      protectedKind: 'fenced code block',
      before: _fencedCodeBlocks(request.input),
      after: _fencedCodeBlocks(output),
    );
    _requireSameProtectedValues(
      protectedKind: 'inline code',
      before: _inlineCode(request.input),
      after: _inlineCode(output),
    );
    _requireSameProtectedValues(
      protectedKind: 'link destination',
      before: _linkDestinations(request.input),
      after: _linkDestinations(output),
    );
  }

  bool _looksWrappedInFence(String value) {
    final lines = value.split('\n');
    if (lines.length < 2) {
      return false;
    }
    final first = lines.first.trimLeft();
    final last = lines.last.trim();
    return (first.startsWith('```') && last == '```') ||
        (first.startsWith('~~~') && last == '~~~');
  }

  List<String> _fencedCodeBlocks(String value) {
    return [
      for (final span in _fencedCodeSpans(value))
        value.substring(span.start, span.end),
    ];
  }

  List<String> _inlineCode(String value) {
    final withoutFences = StringBuffer();
    var cursor = 0;
    for (final span in _fencedCodeSpans(value)) {
      withoutFences
        ..write(value.substring(cursor, span.start))
        ..writeln();
      cursor = span.end;
    }
    withoutFences.write(value.substring(cursor));
    return RegExp(r'(?<!`)`([^`\n]+)`(?!`)')
        .allMatches(withoutFences.toString())
        .map((match) => match.group(0)!)
        .toList();
  }

  List<_AiTextSpan> _fencedCodeSpans(String value) {
    final lines = value.split('\n');
    final spans = <_AiTextSpan>[];
    var lineIndex = 0;
    var offset = 0;
    while (lineIndex < lines.length) {
      final line = lines[lineIndex];
      final start = offset;
      final lineEnd = offset + line.length;
      final nextOffset = lineEnd + (lineIndex < lines.length - 1 ? 1 : 0);
      final fence = MarkdownFence.parse(line);
      if (fence == null) {
        offset = nextOffset;
        lineIndex += 1;
        continue;
      }

      var closingIndex = lineIndex + 1;
      var closingEnd = nextOffset;
      var foundClosingFence = false;
      while (closingIndex < lines.length) {
        final candidate = lines[closingIndex];
        closingEnd +=
            candidate.length + (closingIndex < lines.length - 1 ? 1 : 0);
        if (fence.closes(candidate)) {
          foundClosingFence = true;
          break;
        }
        closingIndex += 1;
      }
      spans.add(
        _AiTextSpan(start, foundClosingFence ? closingEnd : value.length),
      );
      if (!foundClosingFence) {
        break;
      }
      offset = closingEnd;
      lineIndex = closingIndex + 1;
    }
    return spans;
  }

  List<String> _linkDestinations(String value) {
    final destinations = <String>[
      for (final match in RegExp(r'!?\[[^\]]*\]\(([^\s)]+)').allMatches(value))
        match.group(1)!,
      for (final match in RegExp(
        r'^\s*\[[^\]]+\]:\s*(\S+)',
        multiLine: true,
      ).allMatches(value))
        match.group(1)!,
    ]..sort();
    return destinations;
  }

  void _requireSameProtectedValues({
    required String protectedKind,
    required List<String> before,
    required List<String> after,
  }) {
    if (before.length == after.length) {
      var equal = true;
      for (var index = 0; index < before.length; index += 1) {
        if (before[index] != after[index]) {
          equal = false;
          break;
        }
      }
      if (equal) {
        return;
      }
    }
    throw AiException(
      AiFailureCode.validation,
      'The model changed protected $protectedKind content. The proposal was not applied.',
    );
  }
}

class _AiTextSpan {
  const _AiTextSpan(this.start, this.end);

  final int start;
  final int end;
}

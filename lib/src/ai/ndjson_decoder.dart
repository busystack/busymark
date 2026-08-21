import 'dart:async';
import 'dart:convert';

import 'ai_models.dart';

class NdjsonDecoder {
  const NdjsonDecoder({this.maxBytes = 2 * 1024 * 1024});

  final int maxBytes;

  Stream<Map<String, Object?>> decode(Stream<List<int>> input) async* {
    var byteCount = 0;
    Stream<List<int>> bounded() async* {
      await for (final chunk in input) {
        byteCount += chunk.length;
        if (byteCount > maxBytes) {
          throw const AiException(
            AiFailureCode.responseTooLarge,
            'The AI response exceeded the size limit.',
          );
        }
        yield chunk;
      }
    }

    await for (final line
        in bounded().transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) {
        continue;
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(line);
      } on FormatException {
        throw const AiException(
          AiFailureCode.malformedResponse,
          'Ollama returned malformed streaming data.',
        );
      }
      if (decoded is! Map) {
        throw const AiException(
          AiFailureCode.malformedResponse,
          'Ollama returned an unexpected streaming record.',
        );
      }
      yield decoded.cast<String, Object?>();
    }
  }
}

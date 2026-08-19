import 'dart:convert';

import 'ai_models.dart';

class AiSseEvent {
  const AiSseEvent({required this.data, this.event, this.id});

  final String data;
  final String? event;
  final String? id;
}

class SseDecoder {
  const SseDecoder({this.maxBytes = 2 * 1024 * 1024});

  final int maxBytes;

  Stream<AiSseEvent> decode(Stream<List<int>> input) async* {
    var byteCount = 0;
    String? eventName;
    String? eventId;
    final dataLines = <String>[];

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

    AiSseEvent? takeEvent() {
      if (dataLines.isEmpty) {
        eventName = null;
        return null;
      }
      final event = AiSseEvent(
        data: dataLines.join('\n'),
        event: eventName,
        id: eventId,
      );
      dataLines.clear();
      eventName = null;
      return event;
    }

    await for (final rawLine
        in bounded().transform(utf8.decoder).transform(const LineSplitter())) {
      final line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      if (line.isEmpty) {
        final event = takeEvent();
        if (event != null) {
          yield event;
        }
        continue;
      }
      if (line.startsWith(':')) {
        continue;
      }
      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      switch (field) {
        case 'data':
          dataLines.add(value);
          break;
        case 'event':
          eventName = value;
          break;
        case 'id':
          if (!value.contains('\u0000')) {
            eventId = value;
          }
          break;
      }
    }
    final finalEvent = takeEvent();
    if (finalEvent != null) {
      yield finalEvent;
    }
  }
}

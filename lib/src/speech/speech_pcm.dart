import 'dart:typed_data';

import '../ai/ai_models.dart';
import 'speech_provider.dart';

const speechMaxBytes = 100 * 1024 * 1024;
const speechChunkMaxBytes = 16 * 1024 * 1024;
const speechResultSampleRate = 24000;

Never invalidSpeechAudio() => throw const AiException(
  AiFailureCode.malformedResponse,
  'The speech response has invalid or unsupported audio.',
);

bool isWave(List<int> bytes) =>
    bytes.length >= 12 &&
    _signature(bytes, 0, 'RIFF') &&
    _signature(bytes, 8, 'WAVE');

bool _signature(List<int> bytes, int offset, String value) {
  for (var i = 0; i < value.length; i++) {
    if (bytes[offset + i] != value.codeUnitAt(i)) return false;
  }
  return true;
}

SpeechPcm decodeSpeechWave(Uint8List bytes, {bool allowPipeHeader = false}) {
  if (!isWave(bytes) || bytes.lengthInBytes > speechChunkMaxBytes) {
    invalidSpeechAudio();
  }
  final data = ByteData.sublistView(bytes);
  final riffLength = data.getUint32(4, Endian.little) + 8;
  if (riffLength != bytes.length &&
      !(allowPipeHeader && riffLength > bytes.length)) {
    invalidSpeechAudio();
  }
  int? sampleRate;
  int? channels;
  Uint8List? samples;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    var length = data.getUint32(offset + 4, Endian.little);
    final value = offset + 8;
    final isData = _signature(bytes, offset, 'data');
    if (allowPipeHeader && isData && length > bytes.length - value) {
      length = bytes.length - value;
    }
    if (length > bytes.length - value) invalidSpeechAudio();
    if (_signature(bytes, offset, 'fmt ')) {
      if (sampleRate != null ||
          length < 16 ||
          data.getUint16(value, Endian.little) != 1 ||
          data.getUint16(value + 14, Endian.little) != 16) {
        invalidSpeechAudio();
      }
      channels = data.getUint16(value + 2, Endian.little);
      sampleRate = data.getUint32(value + 4, Endian.little);
      if (data.getUint16(value + 12, Endian.little) != channels * 2 ||
          data.getUint32(value + 8, Endian.little) !=
              sampleRate * channels * 2) {
        invalidSpeechAudio();
      }
    } else if (isData) {
      if (samples != null || sampleRate == null) invalidSpeechAudio();
      samples = Uint8List.sublistView(bytes, value, value + length);
    }
    offset = value + length + (length.isOdd ? 1 : 0);
  }
  if (offset != bytes.length || samples == null || sampleRate == null) {
    invalidSpeechAudio();
  }
  return SpeechPcm(samples, sampleRate: sampleRate, channels: channels!);
}

Uint8List encodeSpeechWave(SpeechPcm pcm) {
  final length = pcm.bytes.lengthInBytes;
  final bytes = Uint8List(length + 44);
  final header = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  header.setUint32(4, length + 36, Endian.little);
  bytes.setRange(8, 16, 'WAVEfmt '.codeUnits);
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, pcm.channels, Endian.little);
  header.setUint32(24, pcm.sampleRate, Endian.little);
  header.setUint32(28, pcm.sampleRate * pcm.channels * 2, Endian.little);
  header.setUint16(32, pcm.channels * 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, 'data'.codeUnits);
  header.setUint32(40, length, Endian.little);
  bytes.setRange(44, bytes.lengthInBytes, pcm.bytes);
  return bytes;
}

/// Resamples using linear interpolation and averages interleaved stereo.
Uint8List normalizeSpeechPcm(SpeechPcm pcm) {
  if (pcm.sampleRate == speechResultSampleRate && pcm.channels == 1) {
    return pcm.bytes;
  }
  final input = ByteData.sublistView(pcm.bytes);
  final output = ByteData(
    ((pcm.frames * speechResultSampleRate / pcm.sampleRate).round().clamp(
          1,
          speechMaxBytes ~/ 2,
        )) *
        2,
  );
  double sample(int frame) {
    final offset = frame * pcm.channels * 2;
    final first = input.getInt16(offset, Endian.little);
    return pcm.channels == 1
        ? first.toDouble()
        : (first + input.getInt16(offset + 2, Endian.little)) / 2;
  }

  for (var i = 0; i < output.lengthInBytes ~/ 2; i++) {
    final position = i * pcm.sampleRate / speechResultSampleRate;
    final lower = position.floor().clamp(0, pcm.frames - 1);
    final upper = (lower + 1).clamp(0, pcm.frames - 1);
    final weight = position - lower;
    final value = (sample(lower) * (1 - weight) + sample(upper) * weight)
        .round();
    output.setInt16(i * 2, value.clamp(-32768, 32767), Endian.little);
  }
  return output.buffer.asUint8List();
}

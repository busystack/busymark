import 'dart:io';

import 'asset_limits.dart';

enum AudioAssetFormat {
  mp3('mp3', 'audio/mpeg'),
  wav('wav', 'audio/wav'),
  ogg('ogg', 'audio/ogg'),
  flac('flac', 'audio/flac'),
  adts('aac', 'audio/aac'),
  mp4('m4a', 'audio/mp4'),
  webm('webm', 'audio/webm');

  const AudioAssetFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;

  static const extensions = [
    'mp3',
    'wav',
    'ogg',
    'oga',
    'opus',
    'flac',
    'aac',
    'm4a',
    'mp4',
    'webm',
  ];

  /// Identifies containers at the asset boundary. The player is responsible
  /// for reporting whether a container contains a decodable audio stream.
  static AudioAssetFormat? identify(List<int> bytes) {
    bool at(int offset, String signature) {
      if (bytes.length < offset + signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[offset + index] != signature.codeUnitAt(index)) return false;
      }
      return true;
    }

    if (at(0, 'RIFF') && at(8, 'WAVE')) return wav;
    if (at(0, 'OggS')) return ogg;
    if (at(0, 'fLaC')) return flac;
    if (at(4, 'ftyp')) return mp4;
    if (at(0, '\x1a\x45\xdf\xa3')) return webm;
    if (at(0, 'ID3')) return mp3;
    if (bytes.length < 7 || bytes[0] != 0xff) return null;
    if (bytes[1] & 0xf6 == 0xf0) return adts;
    if (bytes[1] & 0xe0 == 0xe0 &&
        bytes[1] & 0x18 != 0x08 &&
        bytes[1] & 0x06 != 0 &&
        bytes[2] & 0xf0 != 0xf0 &&
        bytes[2] & 0x0c != 0x0c) {
      return mp3;
    }
    return null;
  }

  static Future<AudioAssetFormat?> inspect(File file) async {
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file ||
        stat.size <= 0 ||
        stat.size > maximumManagedAssetBytes) {
      return null;
    }
    final stream = await file.open();
    try {
      return identify(await stream.read(64));
    } finally {
      await stream.close();
    }
  }
}

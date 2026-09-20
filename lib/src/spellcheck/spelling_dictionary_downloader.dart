import 'dart:io';

import 'package:path/path.dart' as p;

import 'spelling_catalog.dart';
import 'spelling_dictionary_installer.dart';

final class SpellingDictionaryDownloadCancelled implements Exception {
  const SpellingDictionaryDownloadCancelled();

  @override
  String toString() => 'Dictionary installation was cancelled.';
}

final class SpellingDictionaryDownloadCancellation {
  bool _cancelled = false;
  final List<void Function()> _callbacks = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final callback in _callbacks.toList(growable: false)) {
      callback();
    }
    _callbacks.clear();
  }

  void throwIfCancelled() {
    if (_cancelled) throw const SpellingDictionaryDownloadCancelled();
  }

  void register(void Function() callback) {
    if (_cancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }

  void unregister(void Function() callback) => _callbacks.remove(callback);
}

typedef SpellingDictionaryDownloadProgress =
    void Function(int receivedBytes, int totalBytes);

typedef SpellingDictionaryFileDownload =
    Future<void> Function({
      required Uri source,
      required File destination,
      required int expectedBytes,
      required SpellingDictionaryDownloadCancellation cancellation,
      required void Function(int receivedBytes) onProgress,
    });

/// Downloads exactly one catalog pair and publishes it through the shared pair
/// installer used by local imports.
final class SpellingDictionaryDownloader {
  const SpellingDictionaryDownloader({
    this.installer = const SpellingDictionaryPairInstaller(),
    this.downloadFile = _downloadFile,
  });

  final SpellingDictionaryPairInstaller installer;
  final SpellingDictionaryFileDownload downloadFile;

  Future<SpellingDictionaryInstallation> install({
    required SpellingDictionaryResource resource,
    required String downloadedRoot,
    required Future<String> Function(String affPath, String dicPath)
    validateNativePair,
    required SpellingDictionaryDownloadCancellation cancellation,
    required SpellingDictionaryDownloadProgress onProgress,
  }) async {
    cancellation.throwIfCancelled();
    final root = Directory(p.normalize(p.absolute(downloadedRoot)));
    await root.create(recursive: true);
    final downloadStage = await root.createTemp('.busymark-download-');
    final aff = File(p.join(downloadStage.path, 'download.aff'));
    final dic = File(p.join(downloadStage.path, 'download.dic'));
    var affReceived = 0;
    var dicReceived = 0;
    void publishProgress() =>
        onProgress(affReceived + dicReceived, resource.downloadSize);
    try {
      await downloadFile(
        source: resource.affDownloadUrl,
        destination: aff,
        expectedBytes: resource.affSize,
        cancellation: cancellation,
        onProgress: (received) {
          affReceived = received;
          publishProgress();
        },
      );
      cancellation.throwIfCancelled();
      await downloadFile(
        source: resource.dicDownloadUrl,
        destination: dic,
        expectedBytes: resource.dicSize,
        cancellation: cancellation,
        onProgress: (received) {
          dicReceived = received;
          publishProgress();
        },
      );
      cancellation.throwIfCancelled();
      return await installer.install(
        affSource: aff,
        dicSource: dic,
        spec: SpellingDictionaryInstallSpec.downloaded(resource),
        destinationRoot: root.path,
        validateNativePair: validateNativePair,
        cancellationGuard: cancellation.throwIfCancelled,
      );
    } finally {
      if (await downloadStage.exists()) {
        await downloadStage.delete(recursive: true);
      }
    }
  }
}

Future<void> _downloadFile({
  required Uri source,
  required File destination,
  required int expectedBytes,
  required SpellingDictionaryDownloadCancellation cancellation,
  required void Function(int receivedBytes) onProgress,
}) async {
  if (source.scheme != 'https') {
    throw const FormatException('Dictionary downloads must use HTTPS.');
  }
  final client = HttpClient()..autoUncompress = false;
  void abort() => client.close(force: true);
  cancellation.register(abort);
  IOSink? sink;
  try {
    cancellation.throwIfCancelled();
    final request = await client.getUrl(source);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Dictionary download returned HTTP ${response.statusCode}.',
        uri: source,
      );
    }
    final declaredLength = response.contentLength;
    if (declaredLength >= 0 && declaredLength != expectedBytes) {
      throw const FormatException(
        'Dictionary download size does not match its catalog.',
      );
    }
    sink = destination.openWrite();
    var received = 0;
    await for (final bytes in response) {
      cancellation.throwIfCancelled();
      received += bytes.length;
      if (received > expectedBytes) {
        throw const FormatException('Dictionary download exceeded its size.');
      }
      sink.add(bytes);
      onProgress(received);
    }
    await sink.flush();
    await sink.close();
    sink = null;
    cancellation.throwIfCancelled();
    if (received != expectedBytes) {
      throw const FormatException('Dictionary download was incomplete.');
    }
  } on Object {
    if (cancellation.isCancelled) {
      throw const SpellingDictionaryDownloadCancelled();
    }
    rethrow;
  } finally {
    cancellation.unregister(abort);
    await sink?.close();
    client.close(force: true);
  }
}

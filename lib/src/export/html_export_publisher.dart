import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../core/atomic_file_writer.dart';
import '../core/linux_atomic_file_api.dart';
import 'html_export_models.dart';

const htmlExportManifest = '.busymark-html-export.json';

class HtmlExportPublisher {
  const HtmlExportPublisher({this.fileWriter = const AtomicFileWriter()});
  final AtomicFileWriter fileWriter;

  Future<Directory> staging(String destination) async {
    final parent = Directory(p.dirname(p.absolute(destination)));
    if (!await parent.exists()) {
      throw const HtmlExportException(
        'The destination parent directory does not exist.',
      );
    }
    return parent.createTemp('.busymark-html-');
  }

  Future<void> publishDocument({
    required Directory stage,
    required String destination,
    required String html,
    required String assetsName,
    required bool overwrite,
    required HtmlExportCancellationToken token,
  }) async {
    token.check();
    final type = await FileSystemEntity.type(destination, followLinks: false);
    if (type != FileSystemEntityType.notFound && !overwrite) {
      throw const HtmlExportException(
        'The destination already exists. Confirm overwrite to replace it.',
      );
    }
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const HtmlExportException(
        'The HTML destination must be a regular file.',
      );
    }
    final stagedAssets = Directory(p.join(stage.path, assetsName));
    if (await stagedAssets.exists()) {
      final target = Directory(p.join(p.dirname(destination), assetsName));
      final targetType = await FileSystemEntity.type(
        target.path,
        followLinks: false,
      );
      if (targetType == FileSystemEntityType.notFound) {
        await _manifest(stagedAssets, 'assets');
        _publishDirectory(stagedAssets.path, target.path);
      } else {
        await _verifyOwned(target, 'assets');
        // Immutable names ensure an old entry point remains valid throughout.
        await for (final entity in stagedAssets.list(followLinks: false)) {
          token.check();
          if (entity is! File) {
            throw const HtmlExportException('Invalid staged asset.');
          }
          final targetPath = p.join(target.path, p.basename(entity.path));
          if (!await File(targetPath).exists()) {
            await fileWriter.writeBytes(
              targetPath,
              await entity.readAsBytes(),
              overwrite: false,
            );
          }
        }
        // Assets are append-only; the ownership marker is stable and no previous
        // files are removed. Each filename is verified against its content hash.
      }
    }
    token.check();
    await fileWriter.writeBytes(
      destination,
      utf8.encode(html),
      overwrite: overwrite,
    );
  }

  Future<void> publishSite({
    required Directory stage,
    required String destination,
    required bool overwrite,
    required HtmlExportCancellationToken token,
  }) async {
    await _manifest(stage, 'site');
    token.check();
    final type = await FileSystemEntity.type(destination, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      _publishDirectory(stage.path, destination);
      return;
    }
    if (!overwrite) {
      throw const HtmlExportException(
        'The destination already exists. Confirm overwrite to replace it.',
      );
    }
    final previous = Directory(destination);
    final identity = await _verifyOwned(previous, 'site');
    token.check();
    final api = LinuxAtomicFileApi.instance;
    if (!api.isAvailable) {
      throw const HtmlExportException(
        'Atomic directory replacement is unavailable on this system. Choose a new destination.',
      );
    }
    final error = api.exchange(stage.path, destination);
    if (error != null) {
      throw HtmlExportException(
        'Could not atomically replace the HTML export (system error $error).',
      );
    }
    // Verify the exchanged directory too, protecting a concurrently changed target.
    try {
      if (await _verifyOwned(stage, 'site') != identity) {
        throw const HtmlExportException(
          'The destination changed during export.',
        );
      }
    } on Object {
      final rollback = api.exchange(stage.path, destination);
      if (rollback != null) {
        throw HtmlExportRecoveryException(stage.path);
      }
      rethrow;
    }
  }

  void _publishDirectory(String source, String target) {
    final api = LinuxAtomicFileApi.instance;
    if (!api.isAvailable) {
      throw const HtmlExportException(
        'Atomic directory publication is unavailable.',
      );
    }
    final error = api.publishNoReplace(source, target, directory: true);
    if (error != null) {
      throw HtmlExportException(
        'Could not publish the export directory (system error $error).',
      );
    }
  }

  Future<void> _manifest(Directory directory, String kind) async {
    final files = <String, String>{};
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Link) {
        throw const HtmlExportException(
          'Export output must not contain symlinks.',
        );
      }
      if (entity is File) {
        files[p.relative(entity.path, from: directory.path)] = sha256
            .convert(await entity.readAsBytes())
            .toString();
      }
    }
    await File(p.join(directory.path, htmlExportManifest)).writeAsString(
      jsonEncode({
        'owner': 'BusyMark HTML export',
        'version': 1,
        'kind': kind,
        'files': files,
      }),
      flush: true,
    );
  }

  Future<String> _verifyOwned(Directory directory, String kind) async {
    if (await FileSystemEntity.type(directory.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const HtmlExportException(
        'The destination is not an exporter-owned directory.',
      );
    }
    final marker = File(p.join(directory.path, htmlExportManifest));
    if (await FileSystemEntity.type(marker.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await marker.length() > 1024 * 1024) {
      throw const HtmlExportException(
        'The destination is not an exporter-owned directory. Choose a dedicated export directory.',
      );
    }
    final source = await marker.readAsString();
    final manifest = jsonDecode(source);
    if (manifest is! Map ||
        manifest['owner'] != 'BusyMark HTML export' ||
        manifest['kind'] != kind ||
        manifest['version'] != 1 ||
        manifest['files'] is! Map) {
      throw const HtmlExportException('Invalid export ownership marker.');
    }
    final expected = Map<String, dynamic>.from(manifest['files'] as Map);
    var count = 0;
    var bytes = 0;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (++count > 10000 || entity is Link) {
        throw const HtmlExportException(
          'The destination contains unsupported user files.',
        );
      }
      if (entity is Directory) {
        if (kind != 'site' ||
            p.relative(entity.path, from: directory.path) != 'assets') {
          throw const HtmlExportException(
            'The destination contains an unexpected directory.',
          );
        }
      }
      if (entity is! File || entity.path == marker.path) continue;
      final name = p.relative(entity.path, from: directory.path);
      final length = await entity.length();
      bytes += length;
      if (length > 256 * 1024 * 1024 || bytes > 1024 * 1024 * 1024) {
        throw const HtmlExportException(
          'The previous directory exceeds ownership verification limits. Choose a new destination.',
        );
      }
      final digest = sha256.convert(await entity.readAsBytes()).toString();
      if (kind == 'assets'
          ? !RegExp('^$digest\\.[a-z0-9]+\$').hasMatch(name)
          : expected.remove(name) != digest) {
        throw const HtmlExportException(
          'The previous export contains changed or unowned files. Choose a new destination to preserve them.',
        );
      }
    }
    if (kind == 'site' && expected.isNotEmpty) {
      throw const HtmlExportException(
        'The previous export is incomplete. Choose a new destination.',
      );
    }
    return sha256.convert(utf8.encode(source)).toString();
  }
}

/// Cleanup must retain the displaced directory if even rollback is unavailable.
class HtmlExportRecoveryException extends HtmlExportException {
  HtmlExportRecoveryException(String stagePath)
    : super(
        'Directory replacement could not be rolled back. The previous output is retained at $stagePath.',
      );
}

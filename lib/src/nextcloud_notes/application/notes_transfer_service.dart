import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../assets/asset_limits.dart';
import '../../assets/document_media_resolver.dart';
import '../../export/markdown_copy_export_service.dart';
import '../data/notes_attachment_references.dart';
import '../data/notes_api_client.dart';
import '../domain/notes_models.dart';
import '../domain/notes_search.dart' show normalizeNotesSearch;
import 'notes_repository.dart';

class NotesTransferCancellation {
  bool cancelled = false;
  void cancel() => cancelled = true;
  void check() {
    if (cancelled) throw const FileSystemException('Transfer cancelled.');
  }
}

class NotesExportResult {
  const NotesExportResult(this.path, this.count, this.omissions);
  final String path;
  final int count;
  final List<String> omissions;
  bool get complete => omissions.isEmpty;
}

class NotesImportItem {
  NotesImportItem({
    required this.key,
    required this.path,
    required this.title,
    required this.category,
    required this.content,
    this.favorite = false,
    this.activityMicros,
    this.serverModified,
    this.collision = false,
    this.media = const {},
    this.issues = const [],
  });
  final String key, path, title, content;
  String category;
  final bool favorite, collision;
  final int? activityMicros, serverModified;
  final Map<String, ({String path, String filename, String digest})> media;
  final List<String> issues;
  bool selected = true;
}

class NotesImportReview {
  const NotesImportReview(this.root, this.items, this.issues);
  final String root;
  final List<NotesImportItem> items;
  final List<String> issues;
}

class NotesImportOutcome {
  const NotesImportOutcome(
    this.item, {
    this.noteId,
    this.error,
    this.alreadyImported = false,
  });
  final String item;
  final String? noteId, error;
  final bool alreadyImported;
}

/// Portable snapshots contain document metadata only. Every note is an
/// ordinary Markdown document; local identities, credentials and outbox are
/// deliberately absent from the versioned interchange manifest.
class NotesTransferService {
  const NotesTransferService(this.repository);
  final NotesRepository repository;
  static const manifestName = 'busymark-notes.json';
  static const format = 'busymark-notes';
  static const version = 1;
  static const maximumDocumentBytes = 4 * 1024 * 1024;

  Future<NotesExportResult> exportSnapshot({
    required List<NextcloudNote> notes,
    required String destination,
    required NotesTransferCancellation cancellation,
    void Function(int completed, int total)? onProgress,
  }) async {
    final parent = Directory(destination);
    await _safeAbsolute(parent.path);
    final staging = await parent.createTemp('.busymark-export-');
    final published = p.join(
      parent.path,
      'BusyMark-notes-${const Uuid().v4()}',
    );
    final documents = <Map<String, Object?>>[];
    final omissions = <String>[];
    final directories = <String, String>{'': ''};
    final used = <String>{};
    try {
      for (final note in notes) {
        cancellation.check();
        var directory = '';
        var original = '';
        for (final component
            in note.category.split('/').where((s) => s.isNotEmpty)) {
          original = original.isEmpty ? component : '$original/$component';
          directory = directories.putIfAbsent(
            original,
            () => p.join(
              directory,
              _uniqueName(component, used, 'entry:$directory'),
            ),
          );
        }
        final name = _uniqueName(
          note.title,
          used,
          'entry:$directory',
          extension: '.md',
        );
        final relative = p.join(directory, name);
        final file = File(p.join(staging.path, relative));
        await file.parent.create(recursive: true);
        final missing = <String>[];
        await const MarkdownCopyExportService().export(
          source: note.content,
          destinationPath: file.path,
          media: DocumentMediaContext(
            identity: note.localId,
            resolve: (r) =>
                repository.resolveCachedMedia(note.accountId, note.localId, r),
            resolveCached: (_) => null,
          ),
          onMissing: missing.add,
          isCancelled: () => cancellation.cancelled,
        );
        final availability = await repository.attachmentAvailability(
          note.localId,
          source: note.content,
        );
        missing.addAll(availability.external);
        for (final reference in missing) {
          omissions.add('${note.title}: $reference');
        }
        documents.add({
          'file': p.split(relative).join('/'),
          'title': note.title,
          'category': note.category,
          'favorite': note.favorite,
          'activityMicros': note.activityMicros,
          'serverModified': note.modified,
          'workingVersion': true,
          'unresolvedConflict':
              note.metadataConflict != null ||
              note.syncState == NoteSyncState.conflict ||
              note.syncState == NoteSyncState.deletedRemotely &&
                  note.hasPendingChanges,
          'omissions': missing,
        });
        onProgress?.call(documents.length, notes.length);
      }
      cancellation.check();
      await File(p.join(staging.path, manifestName)).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'format': format,
          'version': version,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
          'documents': documents,
          'complete': omissions.isEmpty,
        }),
        flush: true,
      );
      cancellation.check();
      if (await FileSystemEntity.type(published, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw const FileSystemException('Export destination already exists.');
      }
      await staging.rename(published);
      return NotesExportResult(
        published,
        documents.length,
        List.unmodifiable(omissions),
      );
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<NotesImportReview> review(
    String source,
    String accountId, {
    String category = '',
    NotesTransferCancellation? cancellation,
  }) async {
    await _safeAbsolute(source);
    final type = await FileSystemEntity.type(source, followLinks: false);
    final root = type == FileSystemEntityType.directory
        ? p.normalize(p.absolute(source))
        : p.dirname(p.absolute(source));
    final manifest = File(p.join(root, manifestName));
    final issues = <String>[];
    final entries = <Map<String, dynamic>>[];
    if (type == FileSystemEntityType.directory && await manifest.exists()) {
      await _within(root, manifest.path);
      if (await manifest.length() > maximumDocumentBytes) {
        throw const FormatException('Manifest is too large.');
      }
      final data =
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      if (data['format'] != format ||
          data['version'] != version ||
          data['documents'] is! List) {
        throw const FormatException('Unsupported Notes snapshot manifest.');
      }
      for (final item in data['documents'] as List) {
        final entry = Map<String, dynamic>.from(item as Map);
        if (entry['file'] is! String ||
            entry['title'] is! String ||
            entry['category'] is! String ||
            entry['favorite'] is! bool) {
          throw const FormatException('Invalid Notes snapshot entry.');
        }
        entries.add(entry);
      }
    } else if (type == FileSystemEntityType.file) {
      if (!_markdown(source)) {
        throw const FormatException('Choose Markdown files.');
      }
      entries.add({
        'file': p.basename(source),
        'title': p.basenameWithoutExtension(source),
        'category': category,
      });
    } else if (type == FileSystemEntityType.directory) {
      await for (final entity in Directory(
        root,
      ).list(recursive: true, followLinks: false)) {
        cancellation?.check();
        if (entity is Link) {
          issues.add(
            'Symbolic link skipped: ${p.relative(entity.path, from: root)}',
          );
          continue;
        }
        if (entity is File && _markdown(entity.path)) {
          final relative = p.relative(entity.path, from: root);
          final parent = p.dirname(relative);
          entries.add({
            'file': p.split(relative).join('/'),
            'title': p.basenameWithoutExtension(relative),
            'category': [
              category,
              if (parent != '.') p.split(parent).join('/'),
            ].where((s) => s.isNotEmpty).join('/'),
          });
        }
      }
    } else {
      throw const FileSystemException('Import source is unavailable.');
    }
    entries.sort(
      (a, b) => (a['file'] as String).compareTo(b['file'] as String),
    );
    final items = <NotesImportItem>[];
    final paths = <String>{};
    for (final entry in entries) {
      cancellation?.check();
      if (!_markdown(entry['file'] as String)) {
        throw const FormatException(
          'Snapshot entries must be Markdown documents.',
        );
      }
      final path = _relative(root, entry['file'] as String);
      if (!paths.add(path)) {
        throw const FormatException('Duplicate manifest file mapping.');
      }
      await _within(root, path);
      final file = File(path);
      if (await file.length() > maximumDocumentBytes) {
        issues.add('Document too large: ${entry['file']}');
        continue;
      }
      final content = await file.readAsString();
      final media = <String, ({String path, String filename, String digest})>{};
      final itemIssues = <String>[];
      for (final occurrence in await scanNotesAttachmentReferences(content)) {
        final reference = occurrence.reference;
        final uri = Uri.tryParse(reference);
        if (reference.startsWith('#') ||
            uri?.scheme == 'https' ||
            uri?.scheme == 'http') {
          if (occurrence.image) itemIssues.add('External image: $reference');
          continue;
        }
        if (uri?.hasScheme == true ||
            reference.startsWith('//') ||
            reference.contains('\\')) {
          itemIssues.add('Unsupported reference: $reference');
          continue;
        }
        // Preserve unrelated document links. Import only recognized image and
        // snapshot companion-media destinations, through the shared scanner.
        final decoded = canonicalAttachmentReference(reference);
        if (decoded == null) {
          if (occurrence.image) itemIssues.add('Unsafe reference: $reference');
          continue;
        }
        if (!occurrence.image && !decoded.contains('.attachments-')) continue;
        try {
          final asset = _relative(
            root,
            p
                .split(p.relative(file.parent.path, from: root))
                .where((s) => s != '.')
                .followedBy(decoded.split('/'))
                .join('/'),
          );
          await _within(root, asset);
          final assetFile = File(asset);
          if (await assetFile.length() > maximumManagedAssetBytes) {
            throw const FileSystemException('Media exceeds size limit.');
          }
          final digest = await sha256.bind(assetFile.openRead()).first;
          media[reference] = (
            path: asset,
            filename: p.basename(asset),
            digest: digest.toString(),
          );
        } on Object {
          itemIssues.add('Missing or unsafe media: $reference');
        }
      }
      final targetCategory = entry['category'] as String;
      final title = entry['title'] as String;
      final collision = repository.notes.any(
        (n) =>
            n.accountId == accountId &&
            n.title == title &&
            n.category == targetCategory &&
            n.syncState != NoteSyncState.deletedRemotely,
      );
      final digest = sha256.convert(utf8.encode(content)).toString();
      // Source location and content identity survive process restarts. Target
      // category corrections do not change identity or duplicate successful work.
      final key = sha256
          .convert(utf8.encode('$root\u0000${entry['file']}\u0000$digest'))
          .toString();
      items.add(
        NotesImportItem(
          key: key,
          path: path,
          title: title,
          category: targetCategory,
          content: content,
          favorite: entry['favorite'] as bool? ?? false,
          activityMicros: entry['activityMicros'] as int?,
          serverModified: entry['serverModified'] as int?,
          collision: collision,
          media: media,
          issues: itemIssues,
        ),
      );
    }
    return NotesImportReview(root, items, issues);
  }

  Future<List<NotesImportOutcome>> importReviewed(
    NotesImportReview review,
    String accountId, {
    required NotesTransferCancellation cancellation,
    void Function(int completed, int total)? onProgress,
  }) async {
    final outcomes = <NotesImportOutcome>[];
    final selected = review.items.where((i) => i.selected).toList();
    for (final item in selected) {
      if (cancellation.cancelled) break;
      try {
        final existing = await repository.store.importedNote(
          accountId,
          item.key,
        );
        if (existing != null) {
          outcomes.add(
            NotesImportOutcome(
              item.title,
              noteId: existing,
              alreadyImported: true,
            ),
          );
          onProgress?.call(outcomes.length, selected.length);
          continue;
        }
        await _within(review.root, item.path);
        final file = File(item.path);
        if (await file.length() > maximumDocumentBytes ||
            await file.readAsString() != item.content) {
          throw const FileSystemException('Document changed after review.');
        }
        final media = <String, ({String filename, Uint8List bytes})>{};
        var total = 0;
        for (final entry in item.media.entries) {
          cancellation.check();
          await _within(review.root, entry.value.path);
          final asset = File(entry.value.path);
          final length = await asset.length();
          total += length;
          if (length > maximumManagedAssetBytes || total > 256 * 1024 * 1024) {
            throw const FileSystemException('Media exceeds import size limit.');
          }
          final bytes = await asset.readAsBytes();
          if (sha256.convert(bytes).toString() != entry.value.digest) {
            throw const FileSystemException('Media changed after review.');
          }
          media[entry.key] = (filename: entry.value.filename, bytes: bytes);
        }
        cancellation.check();
        final note = await repository.importLocal(
          accountId: accountId,
          sourceKey: item.key,
          title: item.title,
          category: item.category,
          content: item.content,
          favorite: item.favorite,
          activityMicros: item.activityMicros,
          modified: item.serverModified,
          media: media,
        );
        outcomes.add(NotesImportOutcome(item.title, noteId: note.localId));
      } on Object catch (error) {
        outcomes.add(NotesImportOutcome(item.title, error: error.toString()));
      }
      onProgress?.call(outcomes.length, selected.length);
    }
    return outcomes;
  }

  static bool _markdown(String path) =>
      {'.md', '.markdown'}.contains(p.extension(path).toLowerCase());
  static String _relative(String root, String relative) {
    if (p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative.contains('\u0000') ||
        relative.split('/').any((s) => s == '..' || s.isEmpty)) {
      throw const FormatException('Unsafe import path.');
    }
    final path = p.normalize(p.join(root, relative));
    if (!p.isWithin(root, path)) {
      throw const FormatException('Import path escapes source.');
    }
    return path;
  }

  static Future<void> _within(String root, String path) async {
    if (!p.isWithin(root, path)) {
      throw const FileSystemException('Import path escapes source.');
    }
    await _safeAbsolute(path);
    final resolved = await File(path).resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw const FileSystemException('Import path escapes source.');
    }
  }

  static Future<void> _safeAbsolute(String path) async {
    var current = p.normalize(p.absolute(path));
    while (true) {
      if (await FileSystemEntity.isLink(current)) {
        throw const FileSystemException(
          'Symbolic links are not allowed in transfers.',
        );
      }
      final parent = p.dirname(current);
      if (parent == current) break;
      current = parent;
    }
  }

  static String _uniqueName(
    String input,
    Set<String> used,
    String scope, {
    String extension = '',
  }) {
    var stem = input
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f\x7f]'), '_')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (stem.isEmpty ||
        RegExp(
          r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$',
          caseSensitive: false,
        ).hasMatch(stem)) {
      stem = 'note';
    }
    // Bound UTF-8 component bytes, leaving room for collision suffixes.
    while (utf8.encode(stem).length > 120) {
      stem = String.fromCharCodes(stem.runes.take(stem.runes.length - 1));
    }
    var name = '$stem$extension';
    var suffix = 1;
    while (!used.add('$scope:${normalizeNotesSearch(name)}')) {
      name = '$stem-${++suffix}$extension';
    }
    return name;
  }
}

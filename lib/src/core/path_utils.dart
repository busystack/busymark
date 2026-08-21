import 'dart:io';

import 'package:path/path.dart' as p;

import 'diagnostic.dart';

const ignoredDirectoryNames = {
  '.git',
  '.hg',
  '.svn',
  '.dart_tool',
  '.idea',
  '.cache',
  '.gradle',
  '.pub',
  '.venv',
  '.next',
  'coverage',
  'build',
  'dist',
  'out',
  'node_modules',
  'target',
  'venv',
};

/// Repository metadata must never be exposed as ordinary workspace content.
const versionControlMetadataDirectoryNames = {'.git', '.hg', '.svn'};

const documentationFileExtensions = {
  '.md',
  '.markdown',
  '.topic',
  '.tree',
  '.cfg',
  '.list',
  '.xml',
};

const resourceFileExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.svg',
  '.webp',
  '.pdf',
  '.css',
  '.js',
};

class WorkspaceScanOptions {
  const WorkspaceScanOptions({
    this.maxParsedFileBytes = 2 * 1024 * 1024,
    this.maxParsedDocuments = 5000,
    this.maxTreeEntries = 10000,
    this.followLinks = false,
    this.includeUnsupportedFiles = false,
    this.includeDirectories = false,
    this.includeHiddenDirectories = false,
    this.includeExcludedDirectories = false,
  });

  final int maxParsedFileBytes;
  final int maxParsedDocuments;

  /// Maximum number of filesystem entries inspected while walking the tree.
  ///
  /// Directories, links, and unsupported files all consume this budget.
  final int maxTreeEntries;
  final bool followLinks;
  final bool includeUnsupportedFiles;
  final bool includeDirectories;
  final bool includeHiddenDirectories;
  final bool includeExcludedDirectories;
}

typedef WorkspaceDirectoryLister =
    Stream<FileSystemEntity> Function(
      Directory directory, {
      required bool followLinks,
    });

class WorkspaceScanResult {
  const WorkspaceScanResult({
    required this.entities,
    required this.diagnostics,
  });

  final List<FileSystemEntity> entities;
  final List<Diagnostic> diagnostics;
}

String normalizePath(String path) {
  final value = path.trim();
  if (_isFileUri(value)) {
    return p.normalize(Uri.parse(value).toFilePath());
  }
  if (p.isAbsolute(value)) {
    return p.normalize(value);
  }
  return p.normalize(p.absolute(value));
}

bool isFileUriPath(String path) => _isFileUri(path.trim());

bool isPortalDocumentPath(String path) {
  final value = path.trim();
  return value.startsWith('/run/user/') && value.contains('/doc/');
}

bool _isFileUri(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'file';
}

String normalizedRelative(String root, String path) {
  return p.normalize(p.relative(path, from: root)).replaceAll(r'\', '/');
}

bool isMarkdownPath(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.md' || extension == '.markdown';
}

bool isTextDocumentationPath(String path) {
  final extension = p.extension(path).toLowerCase();
  return documentationFileExtensions.contains(extension);
}

bool isWorkspaceResourcePath(String path) {
  return resourceFileExtensions.contains(p.extension(path).toLowerCase());
}

bool isWorkspaceTreePath(String path) {
  return isTextDocumentationPath(path) || isWorkspaceResourcePath(path);
}

Future<List<FileSystemEntity>> listWorkspaceEntities(String rootPath) async {
  return (await scanWorkspaceEntities(rootPath)).entities;
}

Future<WorkspaceScanResult> scanWorkspaceEntities(
  String rootPath, {
  WorkspaceScanOptions options = const WorkspaceScanOptions(),
  WorkspaceDirectoryLister? directoryLister,
}) async {
  final directory = Directory(rootPath);
  if (!await directory.exists()) {
    return const WorkspaceScanResult(entities: [], diagnostics: []);
  }
  final listDirectory = directoryLister ?? _listWorkspaceDirectory;
  final entities = <FileSystemEntity>[];
  final diagnostics = <Diagnostic>[];
  final pending = <Directory>[directory];
  var pendingIndex = 0;
  var inspectedEntries = 0;
  var reachedTreeEntryLimit = options.maxTreeEntries <= 0;

  while (pendingIndex < pending.length &&
      inspectedEntries < options.maxTreeEntries) {
    final current = pending[pendingIndex++];
    final listing = <FileSystemEntity>[];
    try {
      await for (final entity in listDirectory(
        current,
        followLinks: options.followLinks,
      )) {
        listing.add(entity);
        inspectedEntries++;
        if (inspectedEntries >= options.maxTreeEntries) {
          reachedTreeEntryLimit = true;
          break;
        }
      }
    } on Object catch (error) {
      diagnostics.add(
        _scanWarning(
          current.path,
          'workspace.scan.inspect-failed',
          args: {'error': '$error'},
        ),
      );
      continue;
    }
    listing.sort((a, b) => a.path.compareTo(b.path));

    for (final entity in listing) {
      FileSystemEntityType type;
      try {
        type = await FileSystemEntity.type(
          entity.path,
          followLinks: options.followLinks,
        );
      } on Object catch (error) {
        diagnostics.add(
          _scanWarning(
            entity.path,
            'workspace.scan.inspect-failed',
            args: {'error': '$error'},
          ),
        );
        continue;
      }
      if (type == FileSystemEntityType.directory) {
        final name = p.basename(entity.path);
        if (versionControlMetadataDirectoryNames.contains(name) ||
            (!options.includeHiddenDirectories && name.startsWith('.')) ||
            (!options.includeExcludedDirectories &&
                ignoredDirectoryNames.contains(name))) {
          continue;
        }
        if (options.includeDirectories) {
          entities.add(entity);
        }
        pending.add(Directory(entity.path));
        continue;
      }
      if (type == FileSystemEntityType.link && !options.followLinks) {
        continue;
      }
      if (type != FileSystemEntityType.file ||
          (!options.includeUnsupportedFiles &&
              !isWorkspaceTreePath(entity.path))) {
        continue;
      }
      entities.add(entity);
    }
  }
  if (reachedTreeEntryLimit) {
    diagnostics.add(_scanWarning(rootPath, 'workspace.scan.skipped'));
  }
  entities.sort((a, b) => a.path.compareTo(b.path));
  return WorkspaceScanResult(
    entities: entities,
    diagnostics: sortDiagnostics(diagnostics),
  );
}

Stream<FileSystemEntity> _listWorkspaceDirectory(
  Directory directory, {
  required bool followLinks,
}) {
  return directory.list(followLinks: followLinks);
}

Diagnostic _scanWarning(
  String path,
  String code, {
  Map<String, Object?> args = const {},
}) {
  return Diagnostic(
    code: code,
    severity: DiagnosticSeverity.warning,
    filePath: path,
    args: args,
  );
}

/// BusyMark heading anchors follow `package:markdown` GFM heading IDs, extended
/// to Unicode letters, marks, and numbers for localized documents.
///
/// Compatibility target:
/// - lower-case and trim heading text
/// - keep Unicode letters, combining marks, numbers, ASCII `_`, and ASCII `-`
/// - remove other punctuation
/// - convert whitespace to ASCII hyphens
String slugForHeading(String text) {
  final buffer = StringBuffer();
  final validSlugCharacter = RegExp(r'[\p{L}\p{M}\p{N}_-]', unicode: true);
  final whitespace = RegExp(r'\s', unicode: true);
  for (final rune in text.toLowerCase().trim().runes) {
    final char = String.fromCharCode(rune);
    if (validSlugCharacter.hasMatch(char)) {
      buffer.write(char);
    } else if (whitespace.hasMatch(char)) {
      buffer.write('-');
    }
  }
  return buffer.toString();
}

/// Returns the next source-order ID for a generated Markdown heading.
///
/// [occurrenceCounts] is updated so every parser or editor projection applies
/// the same duplicate suffixes. Empty slugs use the conventional `section`
/// fallback.
String nextGeneratedHeadingId(
  String baseId,
  Map<String, int> occurrenceCounts,
) {
  final normalizedBase = baseId.isEmpty ? 'section' : baseId;
  final occurrence = occurrenceCounts[normalizedBase] ?? 0;
  occurrenceCounts[normalizedBase] = occurrence + 1;
  return occurrence == 0 ? normalizedBase : '$normalizedBase-$occurrence';
}

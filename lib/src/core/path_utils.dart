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

const documentationFileExtensions = {
  '.md',
  '.markdown',
  '.mdown',
  '.mkd',
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
  });

  final int maxParsedFileBytes;
  final int maxParsedDocuments;
  final int maxTreeEntries;
  final bool followLinks;
}

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
}) async {
  final directory = Directory(rootPath);
  if (!await directory.exists()) {
    return const WorkspaceScanResult(entities: [], diagnostics: []);
  }
  final entities = <FileSystemEntity>[];
  final diagnostics = <Diagnostic>[];
  final pending = <Directory>[directory];
  var pendingIndex = 0;

  while (pendingIndex < pending.length &&
      entities.length < options.maxTreeEntries) {
    final current = pending[pendingIndex++];
    List<FileSystemEntity> listing;
    try {
      listing = await current.list(followLinks: options.followLinks).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } on Object catch (error) {
      diagnostics.add(
        _scanWarning(current.path, 'Could not list folder: $error'),
      );
      continue;
    }

    for (final entity in listing) {
      FileSystemEntityType type;
      try {
        type = await FileSystemEntity.type(
          entity.path,
          followLinks: options.followLinks,
        );
      } on Object catch (error) {
        diagnostics.add(
          _scanWarning(entity.path, 'Could not inspect path: $error'),
        );
        continue;
      }
      if (type == FileSystemEntityType.directory) {
        final name = p.basename(entity.path);
        if (!ignoredDirectoryNames.contains(name) && !name.startsWith('.')) {
          pending.add(Directory(entity.path));
        }
        continue;
      }
      if (type == FileSystemEntityType.link && !options.followLinks) {
        continue;
      }
      if (type != FileSystemEntityType.file ||
          !isWorkspaceTreePath(entity.path)) {
        continue;
      }
      entities.add(entity);
      if (entities.length >= options.maxTreeEntries) {
        diagnostics.add(
          _scanWarning(
            rootPath,
            'Large workspace detected. Some files were skipped to keep the app responsive.',
          ),
        );
        break;
      }
    }
  }
  entities.sort((a, b) => a.path.compareTo(b.path));
  return WorkspaceScanResult(
    entities: entities,
    diagnostics: sortDiagnostics(diagnostics),
  );
}

Diagnostic _scanWarning(String path, String message) {
  return Diagnostic(
    code: 'workspace.scan.skipped',
    severity: DiagnosticSeverity.warning,
    message: message,
    filePath: path,
  );
}

String slugForHeading(String text) {
  final buffer = StringBuffer();
  var previousHyphen = false;
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final isAlphaNumeric = RegExp('[a-z0-9]').hasMatch(char);
    if (isAlphaNumeric) {
      buffer.write(char);
      previousHyphen = false;
    } else if (!previousHyphen) {
      buffer.write('-');
      previousHyphen = true;
    }
  }
  return buffer.toString().replaceAll(RegExp('^-+|-+\$'), '');
}

import 'dart:io';

import 'package:path/path.dart' as p;

const ignoredDirectoryNames = {
  '.git',
  '.dart_tool',
  '.idea',
  'build',
  'node_modules',
  'out',
};

String normalizePath(String path) => p.normalize(p.absolute(path));

String normalizedRelative(String root, String path) {
  return p.normalize(p.relative(path, from: root)).replaceAll(r'\', '/');
}

bool isMarkdownPath(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.md' || extension == '.markdown';
}

bool isTextDocumentationPath(String path) {
  final extension = p.extension(path).toLowerCase();
  return isMarkdownPath(path) ||
      extension == '.topic' ||
      extension == '.tree' ||
      extension == '.cfg' ||
      extension == '.xml' ||
      extension == '.list';
}

Future<List<FileSystemEntity>> listWorkspaceEntities(String rootPath) async {
  final directory = Directory(rootPath);
  if (!await directory.exists()) {
    return const [];
  }
  final result = <FileSystemEntity>[];
  await for (final entity in directory.list(recursive: true)) {
    final relative = normalizedRelative(rootPath, entity.path);
    final parts = p.split(relative);
    if (parts.any(ignoredDirectoryNames.contains)) {
      continue;
    }
    result.add(entity);
  }
  result.sort((a, b) => a.path.compareTo(b.path));
  return result;
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

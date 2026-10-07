import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

Future<String> loadDocumentMediaText(
  DocumentMediaContext media,
  String reference, {
  int maximumBytes = 4 * 1024 * 1024,
}) async {
  final path = await media.resolve(reference);
  if (path == null) {
    throw const FileSystemException('This note attachment is unavailable.');
  }
  final file = File(path);
  if (await file.length() > maximumBytes) {
    throw const FileSystemException(
      'This note attachment exceeds the text limit.',
    );
  }
  final bytes = await file.readAsBytes();
  if (bytes.length > maximumBytes) {
    throw const FileSystemException(
      'This note attachment exceeds the text limit.',
    );
  }
  return utf8.decode(bytes);
}

/// Access to media belongs to the document provider, never to authored paths.
/// A remote context deliberately has no local-filesystem fallback.
class DocumentMediaContext {
  static final unavailable = DocumentMediaContext(
    identity: 'remote-unavailable',
    resolve: (_) async => null,
    resolveCached: (_) => null,
  );
  const DocumentMediaContext({
    required this.identity,
    required this.resolve,
    required this.resolveCached,
  });

  final String identity;
  final Future<String?> Function(String reference) resolve;
  final String? Function(String reference) resolveCached;
}

class DocumentReadOnlyScope extends InheritedWidget {
  const DocumentReadOnlyScope({
    super.key,
    required this.readOnly,
    required super.child,
  });
  final bool readOnly;
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DocumentReadOnlyScope>()
          ?.readOnly ??
      false;
  @override
  bool updateShouldNotify(DocumentReadOnlyScope oldWidget) =>
      oldWidget.readOnly != readOnly;
}

class DocumentMediaScope extends InheritedWidget {
  const DocumentMediaScope({
    super.key,
    required this.media,
    required super.child,
  });

  final DocumentMediaContext? media;

  static DocumentMediaContext? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocumentMediaScope>()?.media;

  @override
  bool updateShouldNotify(DocumentMediaScope oldWidget) =>
      media != oldWidget.media;
}

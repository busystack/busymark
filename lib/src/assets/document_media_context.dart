import 'package:flutter/widgets.dart';
import 'document_media_resolver.dart';
export 'document_media_resolver.dart';

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

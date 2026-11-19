import 'package:flutter/widgets.dart';

import '../core/source_span.dart';

typedef MarkdownImagePermissionResolver =
    MarkdownImageActions Function(
      String source,
      SourceSpan? span,
      String? renderedSource,
    );

class MarkdownImageActions {
  const MarkdownImageActions({
    required this.allowed,
    this.loadImage,
    this.moreOptions,
  });

  final bool allowed;
  final VoidCallback? loadImage;
  final VoidCallback? moreOptions;
}

class MarkdownImagePermissionScope extends InheritedWidget {
  const MarkdownImagePermissionScope({
    super.key,
    required this.resolve,
    required super.child,
  });

  final MarkdownImagePermissionResolver resolve;

  static MarkdownImageActions? of(
    BuildContext context,
    String source,
    SourceSpan? span,
  ) => context
      .dependOnInheritedWidgetOfExactType<MarkdownImagePermissionScope>()
      ?.resolve(
        source,
        span,
        context
            .dependOnInheritedWidgetOfExactType<MarkdownImageProjection>()
            ?.source,
      );

  @override
  bool updateShouldNotify(MarkdownImagePermissionScope oldWidget) =>
      resolve != oldWidget.resolve;
}

/// The source snapshot from which this renderer obtained its source ranges.
class MarkdownImageProjection extends InheritedWidget {
  const MarkdownImageProjection({
    super.key,
    required this.source,
    required super.child,
  });

  final String? source;

  @override
  bool updateShouldNotify(MarkdownImageProjection oldWidget) =>
      source != oldWidget.source;
}

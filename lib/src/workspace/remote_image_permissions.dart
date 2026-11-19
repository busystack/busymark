import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../core/source_span.dart';
import '../core/uri_utils.dart';
import '../editor/wysiwyg/writerside_editing_adapter.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_parser.dart';
import 'document_buffer.dart';
import 'workspace_model.dart';

String? remoteImageWorkspaceId(Workspace? workspace) =>
    switch (workspace?.kind) {
      WorkspaceKind.markdownFolder || WorkspaceKind.writersideModule =>
        '${workspace!.kind.name}:${p.normalize(workspace.id)}',
      WorkspaceKind.nextcloudNotes => switch (workspace!.nextcloudAccountId) {
        final accountId? => 'nextcloud:$accountId',
        null => null,
      },
      _ => null,
    };

bool allowsWorkspaceRemoteImages(AppSettings settings, Workspace? workspace) {
  // Old grants stored only a path. A standalone file could have created a
  // grant for its parent, so keep the legacy lookup separate from typed IDs.
  final root = workspace?.filesystemRootPath;
  final legacyPath = root != null && root.trim().isNotEmpty
      ? root
      : workspace?.activeFilePath ?? workspace?.markdown?.filePath;
  return settings.allowsRemoteImagesForWorkspace(legacyPath) ||
      settings.remoteImageAllowedWorkspaceIds.contains(
        remoteImageWorkspaceId(workspace),
      );
}

enum RemoteImagePermission { image, document, workspace, global }

typedef _Occurrence = ({int start, int end, String source});

class RemoteImagePermissionTarget {
  RemoteImagePermissionTarget._(
    this._document,
    this._occurrence,
    this.workspaceId,
  );

  final Object _document;
  _Occurrence? _occurrence;
  final String? workspaceId;
  bool _valid = true;
}

/// Session state lives with the workspace controller. The opening token
/// survives buffer copies and Save As without becoming part of session JSON.
class RemoteImagePermissions extends ChangeNotifier {
  final _documents = <Object, _DocumentPermissions>{};

  bool allows(
    DocumentBuffer buffer,
    String? renderedSource,
    SourceSpan? span,
    String source,
  ) {
    final document = _documents[buffer.opening];
    if (document == null) return false;
    if (document.allowAll) return true;
    final occurrence = _occurrenceFor(buffer, renderedSource, span, source);
    return occurrence != null && document.allowed.contains(occurrence);
  }

  RemoteImagePermissionTarget? capture(
    WorkspaceState state,
    DocumentBuffer renderedBuffer,
    String? renderedSource,
    SourceSpan? span,
    String source,
    String? workspaceId,
  ) {
    final current = state.documentBuffers
        .where((buffer) => identical(buffer.opening, renderedBuffer.opening))
        .firstOrNull;
    if (current == null ||
        current.revision != renderedBuffer.revision ||
        current.text != renderedBuffer.text ||
        current.text != renderedSource ||
        workspaceId != remoteImageWorkspaceId(state.workspace) ||
        !isRemoteImageSource(source)) {
      return null;
    }
    final occurrence = _occurrenceFor(current, renderedSource, span, source);
    final document = _documents.putIfAbsent(
      current.opening,
      _DocumentPermissions.new,
    );
    final target = RemoteImagePermissionTarget._(
      current.opening,
      occurrence,
      workspaceId,
    );
    document.pending.add(target);
    return target;
  }

  bool apply(
    RemoteImagePermissionTarget target,
    RemoteImagePermission permission,
    WorkspaceState state,
  ) {
    final document = _documents[target._document];
    if (document == null ||
        !document.pending.remove(target) ||
        !target._valid ||
        target.workspaceId != remoteImageWorkspaceId(state.workspace) ||
        !state.documentBuffers.any(
          (buffer) => identical(buffer.opening, target._document),
        )) {
      return false;
    }
    switch (permission) {
      case RemoteImagePermission.image:
        final occurrence = target._occurrence;
        if (occurrence == null) return false;
        document.allowed.add(occurrence);
        notifyListeners();
      case RemoteImagePermission.document:
        document.allowAll = true;
        notifyListeners();
      case RemoteImagePermission.workspace:
        return target.workspaceId != null;
      case RemoteImagePermission.global:
        break;
    }
    return true;
  }

  void release(RemoteImagePermissionTarget target) {
    final document = _documents[target._document];
    document?.pending.remove(target);
    if (document != null && document.isEmpty) {
      _documents.remove(target._document);
    }
  }

  void update(WorkspaceState? previous, WorkspaceState next) {
    // A cancelled open may restore the suspended buffers. Keep their grants
    // through the loading state and remove them when an outcome is published.
    if (_documents.isEmpty || (next.isLoading && next.workspace == null)) {
      return;
    }
    final open = {
      for (final buffer in next.documentBuffers) buffer.opening: buffer,
    };
    _documents.removeWhere((opening, _) => !open.containsKey(opening));
    for (final before
        in previous?.documentBuffers ?? const <DocumentBuffer>[]) {
      final document = _documents[before.opening];
      final after = open[before.opening];
      if (document == null || after == null || before.text == after.text) {
        continue;
      }

      if (document.allowed.isEmpty && document.pending.isEmpty) continue;
      final map = _UnchangedSource(before.text, after.text);
      final candidates = <_Occurrence>{};
      final context = next.workspace == null
          ? null
          : resolveWorkspaceDocumentContext(next.workspace!, after);
      if (context != null &&
          (document.allowed.isNotEmpty || document.pending.isNotEmpty)) {
        candidates.addAll(_authoredOccurrences(context, after.text));
      }

      _Occurrence? relocate(_Occurrence? occurrence) {
        if (occurrence == null) return null;
        final mapped = map.relocate(occurrence);
        return candidates.contains(mapped) ? mapped : null;
      }

      final retained = document.allowed.map(relocate).nonNulls.toSet();
      document.allowed
        ..clear()
        ..addAll(retained);
      for (final target in document.pending) {
        target._occurrence = relocate(target._occurrence);
        target._valid &= target._occurrence != null;
      }
    }
  }

  @override
  void dispose() {
    _documents.clear();
    super.dispose();
  }

  _Occurrence? _occurrenceFor(
    DocumentBuffer buffer,
    String? renderedSource,
    SourceSpan? span,
    String source,
  ) {
    if (renderedSource != buffer.text ||
        span == null ||
        span.startOffset < 0 ||
        span.endOffset <= span.startOffset ||
        span.endOffset > buffer.text.length) {
      return null;
    }
    return (
      start: span.startOffset,
      end: span.endOffset,
      source: source.trim(),
    );
  }
}

class _DocumentPermissions {
  final allowed = <_Occurrence>{};
  final pending = <RemoteImagePermissionTarget>{};
  bool allowAll = false;
  bool get isEmpty => !allowAll && allowed.isEmpty && pending.isEmpty;
}

/// The maximal unchanged prefix and suffix may overlap when identical markup
/// is inserted or removed. Use only the portions invariant under both edit
/// alignments. An edit spanning several disjoint ranges can discard grants.
class _UnchangedSource {
  _UnchangedSource(String before, String after)
    : delta = after.length - before.length {
    final shortest = math.min(before.length, after.length);
    var prefix = 0;
    while (prefix < shortest &&
        before.codeUnitAt(prefix) == after.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest &&
        before.codeUnitAt(before.length - suffix - 1) ==
            after.codeUnitAt(after.length - suffix - 1)) {
      suffix++;
    }
    prefixEnd = math.min(prefix, shortest - suffix);
    suffixStart = before.length - math.min(suffix, shortest - prefix);
  }

  final int delta;
  late final int prefixEnd;
  late final int suffixStart;

  _Occurrence? relocate(_Occurrence occurrence) {
    if (occurrence.end <= prefixEnd) return occurrence;
    if (occurrence.start < suffixStart) return null;
    return (
      start: occurrence.start + delta,
      end: occurrence.end + delta,
      source: occurrence.source,
    );
  }
}

Iterable<_Occurrence> _authoredOccurrences(
  WorkspaceDocumentContext context,
  String source,
) sync* {
  final path = context.parserPath;
  final BusyDocument? document;
  try {
    document = context.kind == DocumentKind.writersideXmlTopic
        ? const WritersideEditingAdapter().parseXml(
            filePath: path,
            source: source,
          )
        : const MarkdownParser()
              .parse(
                filePath: path,
                source: source,
                mode: context.markdownMode,
                validateLocalReferences: false,
              )
              .busyDocument;
  } on Object {
    return;
  }
  if (document == null) return;

  _Occurrence? occurrence(SourceSpan? span, String? source) {
    if (span == null || span.filePath != path || !isRemoteImageSource(source)) {
      return null;
    }
    return (
      start: span.startOffset,
      end: span.endOffset,
      source: source!.trim(),
    );
  }

  Iterable<_Occurrence> inlines(
    Iterable<BusyInline> items, {
    String? blockSource,
  }) sync* {
    for (final inline in items) {
      if (occurrence(inline.imageSpan, blockSource ?? inline.destination)
          case final image? when inline.kind == BusyInlineKind.image) {
        yield image;
      }
      yield* inlines(inline.children, blockSource: blockSource);
    }
  }

  Iterable<_Occurrence> blocks(List<BusyBlock> items) sync* {
    for (final block in items) {
      if (occurrence(block.posterSpan, block.attributes['preview-src'])
          case final poster? when block.kind == BusyBlockKind.video) {
        yield poster;
      }
      yield* inlines(
        block.inlines,
        blockSource: block.kind == BusyBlockKind.image
            ? block.attributes['src']
            : null,
      );
      yield* blocks(block.children);
    }
  }

  yield* blocks(document.blocks);
}

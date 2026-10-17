import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../editor/wysiwyg/writerside_editing_adapter.dart';
import '../markdown/document_outline.dart';
import '../markdown/preview_model.dart';
import 'workspace_controller.dart';
import 'workspace_model.dart';

final outlineNavigationTargetProvider =
    NotifierProvider<
      OutlineNavigationTargetController,
      OutlineNavigationTarget?
    >(OutlineNavigationTargetController.new);
final outlineViewportTargetProvider =
    NotifierProvider<OutlineViewportTargetController, OutlineViewportTarget?>(
      OutlineViewportTargetController.new,
    );

class OutlineNavigationTargetController
    extends Notifier<OutlineNavigationTarget?> {
  @override
  OutlineNavigationTarget? build() => null;

  void set(OutlineNavigationTarget? target) {
    state = target;
  }
}

class OutlineViewportTargetController extends Notifier<OutlineViewportTarget?> {
  @override
  OutlineViewportTarget? build() => null;

  void set(OutlineViewportTarget target) {
    if (state?.sameLocationAs(target) ?? false) {
      return;
    }
    state = target;
  }
}

class OutlineNavigationTarget {
  const OutlineNavigationTarget({
    required this.workspaceId,
    required this.bufferId,
    required this.filePath,
    required this.headingId,
    required this.line,
    this.editorBlockId,
  });

  final String workspaceId;
  final String bufferId;
  final String? filePath;
  final String headingId;
  final int? line;
  final String? editorBlockId;
}

class OutlineViewportTarget {
  const OutlineViewportTarget({
    required this.workspaceId,
    required this.bufferId,
    required this.filePath,
    required this.headingId,
    required this.sourceStartOffset,
    required this.editorBlockId,
  });

  final String workspaceId;
  final String bufferId;
  final String? filePath;
  final String? headingId;
  final int? sourceStartOffset;
  final String? editorBlockId;

  bool sameLocationAs(OutlineViewportTarget other) {
    return workspaceId == other.workspaceId &&
        bufferId == other.bufferId &&
        filePath == other.filePath &&
        headingId == other.headingId &&
        sourceStartOffset == other.sourceStartOffset &&
        editorBlockId == other.editorBlockId;
  }
}

void setOutlineViewportTarget(
  WidgetRef ref, {
  required Workspace workspace,
  required String? bufferId,
  required DocumentOutlineHeading? heading,
}) {
  ref
      .read(outlineViewportTargetProvider.notifier)
      .set(
        OutlineViewportTarget(
          workspaceId: workspace.id,
          bufferId: bufferId ?? '',
          filePath: workspace.activeFilePath,
          headingId: heading?.id,
          sourceStartOffset: heading?.sourceStartOffset,
          editorBlockId: heading?.editorBlockId,
        ),
      );
}

List<DocumentOutlineHeading> activeDocumentOutline(WorkspaceState state) {
  final liveOutline = state.liveOutline;
  final workspace = state.workspace;
  if (liveOutline != null &&
      workspace != null &&
      liveOutline.matches(workspace, state.activeBuffer, state.activeText)) {
    return liveOutline.headings;
  }
  final preview = state.preview;
  if (preview != null) {
    return preview.outline;
  }
  final buffer = state.activeBuffer;
  if (workspace != null &&
      buffer != null &&
      resolveWorkspaceDocumentContext(workspace, buffer).kind ==
          DocumentKind.writersideXmlTopic) {
    return const WritersideEditingAdapter()
            .parseXml(
              filePath: buffer.filePath ?? workspace.activeFilePath ?? '',
              source: buffer.text,
            )
            ?.outline ??
        const [];
  }
  final markdown = workspace?.markdown;
  if (workspace == null || markdown == null) return const [];
  if (buffer == null) {
    if (state.documentBuffers.isNotEmpty) return const [];
    return [
      for (final heading in markdown.headings)
        DocumentOutlineHeading.fromMarkdown(heading),
    ];
  }
  final context = resolveWorkspaceDocumentContext(workspace, buffer);
  if (!p.equals(markdown.filePath, context.parserPath) ||
      markdown.source != buffer.text ||
      markdown.mode != context.markdownMode) {
    return const [];
  }
  return [
    for (final heading in markdown.headings)
      DocumentOutlineHeading.fromMarkdown(heading),
  ];
}

/// Navigate a heading only against the source/model that produced it.
bool navigateOutlineHeading(
  WidgetRef ref, {
  required String workspaceId,
  required String? bufferId,
  required String source,
  required DocumentOutlineHeading heading,
}) {
  final current = ref.read(workspaceControllerProvider);
  final workspace = current.workspace;
  if (workspace == null ||
      workspace.id != workspaceId ||
      current.activeBufferId != bufferId ||
      current.activeText != source ||
      !activeDocumentOutline(current).any(
        (h) =>
            h.id == heading.id &&
            h.editorBlockId == heading.editorBlockId &&
            h.sourceStartOffset == heading.sourceStartOffset &&
            h.sourceStartLine == heading.sourceStartLine &&
            h.text == heading.text,
      )) {
    return false;
  }
  setOutlineViewportTarget(
    ref,
    workspace: workspace,
    bufferId: bufferId,
    heading: heading,
  );
  ref
      .read(outlineNavigationTargetProvider.notifier)
      .set(
        OutlineNavigationTarget(
          workspaceId: workspaceId,
          bufferId: bufferId ?? '',
          filePath: workspace.activeFilePath,
          headingId: heading.id,
          line: heading.sourceStartLine,
          editorBlockId: heading.editorBlockId,
        ),
      );
  return true;
}

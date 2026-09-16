import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/localization.dart';
import '../../writerside/writerside_instance_service.dart';
import '../../writerside/writerside_topic_creator.dart';
import '../workspace_controller.dart';
import '../workspace_message.dart';

class WritersideMarkdownImportDialog extends ConsumerStatefulWidget {
  const WritersideMarkdownImportDialog({
    super.key,
    required this.sourceRootPath,
    required this.candidates,
    required this.treePath,
    required this.placement,
    this.referenceTocPath,
    this.referenceTocIdentity,
  });

  final String sourceRootPath;
  final List<WritersideMarkdownImportCandidate> candidates;
  final String treePath;
  final WritersideTopicCreatePlacement placement;
  final List<int>? referenceTocPath;
  final WritersideTocNodeIdentity? referenceTocIdentity;

  @override
  ConsumerState<WritersideMarkdownImportDialog> createState() =>
      _WritersideMarkdownImportDialogState();
}

class _WritersideMarkdownImportDialogState
    extends ConsumerState<WritersideMarkdownImportDialog> {
  late final Set<String> _selectedPaths = {
    for (final candidate in widget.candidates) candidate.absolutePath,
  };
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return BusyMarkDialogShell(
      title: context.l10n.addLocalMarkdownFiles,
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: _saving ? null : () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.tocOk,
          suggested: true,
          onPressed: _saving || _selectedPaths.isEmpty ? null : _import,
        ),
      ],
      children: [
        BusyMarkGroupedList(
          title: context.l10n.markdownImportFiles,
          filled: true,
          children: [
            YaruListTile.square(
              title: Wrap(
                spacing: BusyMarkSpacing.sm,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _selectedPaths
                              ..clear()
                              ..addAll(
                                widget.candidates.map(
                                  (candidate) => candidate.absolutePath,
                                ),
                              );
                            _error = null;
                          }),
                    child: Text(context.l10n.selectAll),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _selectedPaths.clear();
                            _error = null;
                          }),
                    child: Text(context.l10n.selectNone),
                  ),
                ],
              ),
            ),
            for (final candidate in widget.candidates)
              BusyMarkActionRow(
                title: candidate.title,
                subtitle: candidate.relativePath,
                trailing: BusyMarkCheckbox(
                  value: _selectedPaths.contains(candidate.absolutePath),
                  onChanged: _saving
                      ? null
                      : (_) => _toggle(candidate.absolutePath),
                ),
                onTap: _saving ? null : () => _toggle(candidate.absolutePath),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkStatusBox(message: _error!, kind: BusyMarkStatusKind.error),
        ],
      ],
    );
  }

  void _toggle(String path) {
    setState(() {
      if (!_selectedPaths.remove(path)) _selectedPaths.add(path);
      _error = null;
    });
  }

  Future<void> _import() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final succeeded = await ref
        .read(workspaceControllerProvider.notifier)
        .addWritersideMarkdownTopics(
          WritersideMarkdownTopicImportRequest(
            sourceRootPath: widget.sourceRootPath,
            selectedMarkdownPaths: [
              for (final candidate in widget.candidates)
                if (_selectedPaths.contains(candidate.absolutePath))
                  candidate.absolutePath,
            ],
            treePath: widget.treePath,
            placement: widget.placement,
            referenceTocPath: widget.referenceTocPath,
            referenceTocIdentity: widget.referenceTocIdentity,
          ),
        );
    if (!mounted) return;
    if (succeeded) {
      Navigator.pop(context, true);
      return;
    }
    final message = ref.read(workspaceControllerProvider).message;
    setState(() {
      _saving = false;
      _error = message == null
          ? context.l10n.workspaceErrorFileOperationFailed('')
          : localizeWorkspaceMessage(context, message);
    });
  }
}

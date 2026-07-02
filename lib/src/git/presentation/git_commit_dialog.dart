import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/localization.dart';
import '../domain/git_models.dart';

class GitCommitDialog extends StatefulWidget {
  const GitCommitDialog({
    super.key,
    required this.stagedFiles,
    required this.onCommit,
  });

  final List<GitFileStatus> stagedFiles;
  final Future<void> Function(String message) onCommit;

  @override
  State<GitCommitDialog> createState() => _GitCommitDialogState();
}

class _GitCommitDialogState extends State<GitCommitDialog> {
  late final TextEditingController _controller;
  var _committing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCommit =
        !_committing &&
        widget.stagedFiles.isNotEmpty &&
        _controller.text.trim().isNotEmpty;
    return BusyMarkDialogShell(
      title: context.l10n.gitCommit,
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        TextButton(
          onPressed: _committing ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: canCommit ? _submit : null,
          child: Text(context.l10n.gitCommit),
        ),
      ],
      children: [
        Text(
          context.l10n.gitCommitStagedFiles,
          style: busyMarkSectionHeaderStyle(context),
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        SizedBox(
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BusyMarkSurfaceColors.of(context).control,
              borderRadius: BorderRadius.circular(BusyMarkRadius.md),
              border: Border.all(
                color: BusyMarkSurfaceColors.of(context).subtleBorder,
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(BusyMarkSpacing.sm),
              itemCount: widget.stagedFiles.length,
              itemBuilder: (context, index) {
                return Text(
                  widget.stagedFiles[index].repoRelativePath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: BusyMarkTypography.monoFontFamily,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
        TextField(
          controller: _controller,
          autofocus: true,
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: context.l10n.gitCommitMessage,
            errorText: _commitMessageError(context),
          ),
        ),
      ],
    );
  }

  String? _commitMessageError(BuildContext context) {
    if (widget.stagedFiles.isEmpty) {
      return context.l10n.gitCommitNoStagedFiles;
    }
    if (_controller.text.isNotEmpty && _controller.text.trim().isEmpty) {
      return context.l10n.gitCommitMessageRequired;
    }
    return null;
  }

  void _handleChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    if (_committing ||
        widget.stagedFiles.isEmpty ||
        _controller.text.trim().isEmpty) {
      return;
    }
    setState(() => _committing = true);
    await widget.onCommit(_controller.text);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }
}

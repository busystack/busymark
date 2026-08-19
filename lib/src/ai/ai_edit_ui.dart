import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/app_settings.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../workspace/workspace_controller.dart';
import 'ai_configuration.dart';
import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_providers.dart';

String aiFeatureLabel(BuildContext context, AiFeature feature) {
  return switch (feature) {
    AiFeature.rewrite => context.l10n.aiRewrite,
    AiFeature.shorten => context.l10n.aiShorten,
    AiFeature.summarize => context.l10n.aiSummarize,
    AiFeature.tone => context.l10n.aiChangeTone,
    AiFeature.translate => context.l10n.aiTranslate,
    AiFeature.proofread => context.l10n.aiProofread,
    AiFeature.draft => context.l10n.aiDraft,
    AiFeature.explainCode => context.l10n.aiExplainCode,
    AiFeature.improveCode => context.l10n.aiImproveCode,
    AiFeature.draftCommitMessage => context.l10n.aiDraftCommitMessage,
  };
}

List<PopupMenuEntry<AiFeature>> aiFeatureMenuItems(BuildContext context) {
  return [
    for (final feature in AiFeature.values)
      if (feature != AiFeature.draftCommitMessage)
        BusyMarkPopupMenuItem(
          value: feature,
          label: aiFeatureLabel(context, feature),
          icon: BusyMarkGlyphs.ai,
        ),
  ];
}

Future<String?> showBusyMarkAiProposal(
  BuildContext context,
  WidgetRef ref,
  AiEditInvocation invocation,
) async {
  final settings = ref.read(appSettingsControllerProvider);
  final providerKind = settings.aiProviderKind;
  if (providerKind == null) {
    await _showAiMessage(context, context.l10n.aiConfigureFirst);
    return null;
  }
  if (!settings.hasCloudConsent(providerKind)) {
    await _showAiMessage(
      context,
      context.l10n.aiCloudConsentRequired(providerKind.displayName),
    );
    return null;
  }
  final provider = ref.read(aiProviderRegistryProvider).require(providerKind);
  final modelCandidates = settings.modelCandidatesFor(
    invocation.feature,
    provider,
  );
  if (modelCandidates.isEmpty) {
    await _showAiMessage(context, context.l10n.aiConfigureFirst);
    return null;
  }
  try {
    if (providerKind == AiProviderKind.ollamaLocal) {
      AiPolicy.validateLocalOllamaEndpoint(settings.aiOllamaEndpoint);
    }
  } on AiException catch (error) {
    await _showAiMessage(context, error.message);
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  var configured = invocation;
  if (invocation.feature.requiresInstruction) {
    final instruction = await _showAiInstructionDialog(
      context,
      invocation.feature,
    );
    if (instruction == null || !context.mounted) {
      return null;
    }
    configured = invocation.copyWith(instruction: instruction);
  }
  final AiRequest request;
  try {
    request = AiPromptBuilder.build(
      id: const Uuid().v4(),
      targetId: configured.targetId,
      provider: providerKind,
      feature: configured.feature,
      scope: configured.scope,
      input: configured.input,
      modelCandidates: modelCandidates,
      sourceRevision: configured.sourceRevision,
      contentFormat: configured.contentFormat,
      instruction: configured.instruction,
      replacementOriginal: configured.replacementOriginal,
      documentSource: configured.documentSource,
      replacementStart: configured.replacementStart,
      replacementEnd: configured.replacementEnd,
      deadline: providerKind == AiProviderKind.ollamaLocal
          ? const Duration(minutes: 5)
          : const Duration(minutes: 2),
    );
  } on AiException catch (error) {
    if (context.mounted) {
      await _showAiMessage(context, error.message);
    }
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  return showBusyMarkModalDialog<String>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        _AiProposalDialog(request: request, invocation: configured),
  );
}

Future<void> _showAiMessage(BuildContext context, String message) {
  return showBusyMarkModalDialog<void>(
    context,
    builder: (dialogContext) => BusyMarkDialogShell(
      title: context.l10n.ai,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.close,
          onPressed: () => Navigator.pop(dialogContext),
        ),
      ],
      children: [
        BusyMarkStatusBox(message: message, kind: BusyMarkStatusKind.warning),
      ],
    ),
  );
}

Future<String?> _showAiInstructionDialog(
  BuildContext context,
  AiFeature feature,
) {
  final label = switch (feature) {
    AiFeature.tone => context.l10n.aiTonePrompt,
    AiFeature.translate => context.l10n.aiLanguagePrompt,
    AiFeature.draft => context.l10n.aiDraftPrompt,
    _ => aiFeatureLabel(context, feature),
  };
  return showBusyMarkModalDialog<String>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) => _AiInstructionDialog(
      title: aiFeatureLabel(context, feature),
      label: label,
    ),
  );
}

class _AiInstructionDialog extends StatefulWidget {
  const _AiInstructionDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_AiInstructionDialog> createState() => _AiInstructionDialogState();
}

class _AiInstructionDialogState extends State<_AiInstructionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkDialogShell(
      title: widget.title,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: context.l10n.apply,
          suggested: true,
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
        ),
      ],
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: widget.label,
              controller: _controller,
              autofocus: true,
              minLines: widget.title == context.l10n.aiDraft ? 3 : 1,
              maxLines: widget.title == context.l10n.aiDraft ? 6 : 1,
              textInputAction: widget.title == context.l10n.aiDraft
                  ? TextInputAction.newline
                  : TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(context, value.trim());
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AiProposalDialog extends ConsumerStatefulWidget {
  const _AiProposalDialog({required this.request, required this.invocation});

  final AiRequest request;
  final AiEditInvocation invocation;

  @override
  ConsumerState<_AiProposalDialog> createState() => _AiProposalDialogState();
}

class _AiProposalDialogState extends ConsumerState<_AiProposalDialog> {
  StreamSubscription<AiStreamEvent>? _subscription;
  final _output = StringBuffer();
  AiUsage? _usage;
  String? _error;
  String? _providerId;
  String? _model;
  var _complete = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref
        .read(aiCoordinatorProvider)
        .stream(widget.request)
        .listen(
          _handleEvent,
          onError: _handleError,
          onDone: () {
            if (mounted && !_complete && _error == null) {
              setState(() => _error = context.l10n.aiConnectionFailed);
            }
          },
        );
  }

  @override
  void dispose() {
    ref.read(aiCoordinatorProvider).cancelRequest(widget.request.id);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _handleEvent(AiStreamEvent event) {
    if (!mounted) {
      return;
    }
    setState(() {
      switch (event) {
        case AiTextDelta(:final text):
          _output.write(text);
        case AiUsageEvent(:final usage):
          _usage = usage;
        case AiCompleted():
          _complete = true;
        case AiStarted(:final providerId, :final model):
          _providerId = providerId ?? _providerId;
          _model = model ?? _model;
      }
    });
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = error is AiException
          ? error.message
          : context.l10n.aiConnectionFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspace = workspaceState.workspace;
    final currentPath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    final revisionCurrent =
        !widget.invocation.enforceDocumentRevision ||
        (ref.read(workspaceControllerProvider.notifier).editRevision ==
                widget.invocation.sourceRevision &&
            currentPath == widget.invocation.documentPath);
    final proposal = _output.toString();
    return BusyMarkDialogShell(
      title: context.l10n.aiProposal,
      maxWidth: 960,
      closable: false,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () {
            ref.read(aiCoordinatorProvider).cancelRequest(widget.request.id);
            Navigator.pop(context);
          },
        ),
        BusyMarkDialogButton(
          label: context.l10n.copy,
          icon: BusyMarkGlyphs.copy,
          onPressed: proposal.isEmpty
              ? null
              : () =>
                    unawaited(Clipboard.setData(ClipboardData(text: proposal))),
        ),
        BusyMarkDialogButton(
          label: context.l10n.aiApplyProposal,
          icon: BusyMarkGlyphs.check,
          suggested: true,
          onPressed:
              _complete &&
                  _error == null &&
                  revisionCurrent &&
                  proposal.isNotEmpty
              ? () => Navigator.pop(context, proposal)
              : null,
        ),
      ],
      children: [
        BusyMarkStatusBox(
          message:
              '${context.l10n.aiProvider}: ${_providerName()}'
              ' · ${context.l10n.aiPreferredModel}: ${_model ?? widget.request.model}\n'
              '${context.l10n.aiContextDisclosure(widget.request.input.length)}',
          kind: BusyMarkStatusKind.information,
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        ExpansionTile(
          title: Text(context.l10n.aiViewContext),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.request.input,
                  style: _monospaceStyle(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        if (_error != null)
          BusyMarkStatusBox(message: _error!, kind: BusyMarkStatusKind.error)
        else if (!revisionCurrent)
          BusyMarkStatusBox(
            message: context.l10n.aiStaleProposal,
            kind: BusyMarkStatusKind.warning,
          )
        else if (!_complete)
          Row(
            children: [
              const SizedBox.square(
                dimension: BusyMarkSizes.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: BusyMarkSpacing.sm),
              Text(context.l10n.aiGenerating),
            ],
          ),
        const SizedBox(height: BusyMarkSpacing.md),
        SizedBox(
          height: 420,
          child: _complete
              ? _AiUnifiedDiff(
                  original: widget.invocation.replacementOriginal,
                  suggested: proposal,
                )
              : _AiStreamingProposal(text: proposal),
        ),
        if (_usage case final usage?) ...[
          const SizedBox(height: BusyMarkSpacing.sm),
          Text(
            _usageLabel(usage),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  String _usageLabel(AiUsage usage) {
    final input = usage.inputTokens;
    final output = usage.outputTokens;
    if (input == null && output == null) {
      return '';
    }
    return context.l10n.aiTokenUsage(input ?? 0, output ?? 0);
  }

  String _providerName() {
    for (final provider in AiProviderKind.values) {
      if (provider.id == _providerId) {
        return provider.displayName;
      }
    }
    return widget.request.provider.displayName;
  }
}

class _AiStreamingProposal extends StatelessWidget {
  const _AiStreamingProposal({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: BusyMarkSurfaceColors.of(context).subtleBorder,
        ),
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: SelectableText(text, style: _monospaceStyle(context)),
      ),
    );
  }
}

class _AiUnifiedDiff extends StatelessWidget {
  const _AiUnifiedDiff({required this.original, required this.suggested});

  final String original;
  final String suggested;

  @override
  Widget build(BuildContext context) {
    final lines = _lineDiff(original, suggested);
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.subtleBorder),
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: Wrap(
              spacing: BusyMarkSpacing.lg,
              children: [
                Text('− ${context.l10n.aiOriginal}'),
                Text('+ ${context.l10n.aiSuggested}'),
              ],
            ),
          ),
          Divider(height: 1, color: colors.subtleBorder),
          Expanded(
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) =>
                  _AiDiffLineView(line: lines[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiDiffLineView extends StatelessWidget {
  const _AiDiffLineView({required this.line});

  final _AiDiffLine line;

  @override
  Widget build(BuildContext context) {
    final background = switch (line.kind) {
      _AiDiffKind.added => BusyMarkLinuxPalette.green.withValues(alpha: 0.18),
      _AiDiffKind.removed => Theme.of(
        context,
      ).colorScheme.error.withValues(alpha: 0.16),
      _AiDiffKind.context => BusyMarkLinuxPalette.transparent,
    };
    final prefix = switch (line.kind) {
      _AiDiffKind.added => '+',
      _AiDiffKind.removed => '−',
      _AiDiffKind.context => ' ',
    };
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.sm,
          vertical: BusyMarkSpacing.xxs,
        ),
        child: SelectableText(
          '$prefix ${line.text}',
          style: _monospaceStyle(context),
        ),
      ),
    );
  }
}

TextStyle? _monospaceStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    fontFamily: BusyMarkTypography.monoFontFamily,
    fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
  );
}

enum _AiDiffKind { context, added, removed }

class _AiDiffLine {
  const _AiDiffLine(this.kind, this.text);

  final _AiDiffKind kind;
  final String text;
}

List<_AiDiffLine> _lineDiff(String before, String after) {
  final oldLines = before.split('\n');
  final newLines = after.split('\n');
  final product = oldLines.length * newLines.length;
  if (product > 250000) {
    return _boundedLineDiff(oldLines, newLines);
  }
  final width = newLines.length + 1;
  final table = Uint32List((oldLines.length + 1) * width);
  for (var oldIndex = oldLines.length - 1; oldIndex >= 0; oldIndex -= 1) {
    for (var newIndex = newLines.length - 1; newIndex >= 0; newIndex -= 1) {
      final offset = oldIndex * width + newIndex;
      table[offset] = oldLines[oldIndex] == newLines[newIndex]
          ? table[(oldIndex + 1) * width + newIndex + 1] + 1
          : _max(
              table[(oldIndex + 1) * width + newIndex],
              table[oldIndex * width + newIndex + 1],
            );
    }
  }
  final result = <_AiDiffLine>[];
  var oldIndex = 0;
  var newIndex = 0;
  while (oldIndex < oldLines.length && newIndex < newLines.length) {
    if (oldLines[oldIndex] == newLines[newIndex]) {
      result.add(_AiDiffLine(_AiDiffKind.context, oldLines[oldIndex]));
      oldIndex += 1;
      newIndex += 1;
    } else if (table[(oldIndex + 1) * width + newIndex] >=
        table[oldIndex * width + newIndex + 1]) {
      result.add(_AiDiffLine(_AiDiffKind.removed, oldLines[oldIndex++]));
    } else {
      result.add(_AiDiffLine(_AiDiffKind.added, newLines[newIndex++]));
    }
  }
  while (oldIndex < oldLines.length) {
    result.add(_AiDiffLine(_AiDiffKind.removed, oldLines[oldIndex++]));
  }
  while (newIndex < newLines.length) {
    result.add(_AiDiffLine(_AiDiffKind.added, newLines[newIndex++]));
  }
  return result;
}

List<_AiDiffLine> _boundedLineDiff(
  List<String> oldLines,
  List<String> newLines,
) {
  var prefix = 0;
  while (prefix < oldLines.length &&
      prefix < newLines.length &&
      oldLines[prefix] == newLines[prefix]) {
    prefix += 1;
  }
  var suffix = 0;
  while (suffix < oldLines.length - prefix &&
      suffix < newLines.length - prefix &&
      oldLines[oldLines.length - suffix - 1] ==
          newLines[newLines.length - suffix - 1]) {
    suffix += 1;
  }
  return [
    for (var index = 0; index < prefix; index += 1)
      _AiDiffLine(_AiDiffKind.context, oldLines[index]),
    for (var index = prefix; index < oldLines.length - suffix; index += 1)
      _AiDiffLine(_AiDiffKind.removed, oldLines[index]),
    for (var index = prefix; index < newLines.length - suffix; index += 1)
      _AiDiffLine(_AiDiffKind.added, newLines[index]),
    for (var index = suffix; index > 0; index -= 1)
      _AiDiffLine(_AiDiffKind.context, oldLines[oldLines.length - index]),
  ];
}

int _max(int first, int second) => first > second ? first : second;

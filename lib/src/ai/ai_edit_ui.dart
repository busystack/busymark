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
import 'ai_coordinator.dart';
import 'ai_markdown_edit_resolver.dart';
import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_providers.dart';

Future<AiEditApplication?> showBusyMarkAiEdit(
  BuildContext context,
  WidgetRef ref,
  AiEditorSnapshot snapshot, {
  AiEditTargetKind? fixedTarget,
}) async {
  final defaultProvider = ref
      .read(appSettingsControllerProvider)
      .defaultAiProviderKind;
  final configuration =
      await showBusyMarkModalEditorDialog<_AiEditConfiguration>(
        context,
        builder: (dialogContext) => _AiEditConfigurationDialog(
          snapshot: snapshot,
          fixedTarget: fixedTarget,
          initialProvider: defaultProvider ?? AiProviderKind.ollamaLocal,
        ),
      );
  if (configuration == null || !context.mounted) {
    return null;
  }
  final target = configuration.resolvedTarget;
  final invocation = AiEditInvocation(
    feature: AiFeature.editDocument,
    scope: target.scope,
    input: target.input,
    replacementOriginal: target.replacementOriginal,
    sourceRevision: snapshot.sourceRevision,
    targetId:
        '${snapshot.targetId}:${target.replacementStart}:${target.replacementEnd}',
    documentPath: snapshot.documentPath,
    instruction: configuration.instruction,
    editTarget: target.editTarget,
    editContext: target.editContext,
    documentSource: snapshot.documentSource,
    replacementStart: target.replacementStart,
    replacementEnd: target.replacementEnd,
    replacementPrefix: target.replacementPrefix,
    replacementSuffix: target.replacementSuffix,
    trimReplacementOutput: target.trimReplacementOutput,
  );
  final output = await showBusyMarkAiProposal(
    context,
    ref,
    invocation,
    providerKind: configuration.provider,
  );
  return output == null
      ? null
      : AiEditApplication(invocation: invocation, output: output);
}

Future<String?> showBusyMarkAiProposal(
  BuildContext context,
  WidgetRef ref,
  AiEditInvocation invocation, {
  AiProviderKind? providerKind,
  Future<bool> Function()? validateBeforeApply,
  String? staleMessage,
}) async {
  final settings = ref.read(appSettingsControllerProvider);
  final defaultProvider = settings.defaultAiProviderKind;
  if (defaultProvider == null) {
    await _showAiMessage(context, context.l10n.aiConfigureFirst);
    return null;
  }
  final selectedProvider = providerKind ?? defaultProvider;
  if (!settings.hasCloudConsent(selectedProvider)) {
    await _showAiMessage(
      context,
      context.l10n.aiCloudConsentRequired(selectedProvider.displayName),
    );
    return null;
  }
  final provider = ref
      .read(aiProviderRegistryProvider)
      .require(selectedProvider);
  final modelCandidates = settings.modelCandidatesFor(
    invocation.feature,
    provider,
  );
  if (modelCandidates.isEmpty) {
    await _showAiMessage(context, context.l10n.aiConfigureFirst);
    return null;
  }
  try {
    if (selectedProvider == AiProviderKind.ollamaLocal) {
      AiPolicy.validateLocalOllamaEndpoint(settings.aiOllamaEndpoint);
    }
  } on AiException catch (error) {
    await _showAiMessage(context, error.message);
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  final AiRequest request;
  try {
    request = AiPromptBuilder.build(
      id: const Uuid().v4(),
      targetId: invocation.targetId,
      provider: selectedProvider,
      feature: invocation.feature,
      scope: invocation.scope,
      input: invocation.input,
      modelCandidates: modelCandidates,
      sourceRevision: invocation.sourceRevision,
      contentFormat: invocation.contentFormat,
      editTarget: invocation.editTarget,
      editContext: invocation.editContext,
      instruction: invocation.instruction,
      replacementOriginal: invocation.replacementOriginal,
      documentSource: invocation.documentSource,
      replacementStart: invocation.replacementStart,
      replacementEnd: invocation.replacementEnd,
      replacementPrefix: invocation.replacementPrefix,
      replacementSuffix: invocation.replacementSuffix,
      trimReplacementOutput: invocation.trimReplacementOutput,
      deadline: selectedProvider == AiProviderKind.ollamaLocal
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
    builder: (dialogContext) => _AiProposalDialog(
      request: request,
      invocation: invocation,
      validateBeforeApply: validateBeforeApply,
      staleMessage: staleMessage,
    ),
  );
}

Future<AiProviderKind?> chooseBusyMarkAiProvider(
  BuildContext context,
  WidgetRef ref,
) async {
  final defaultProvider = ref
      .read(appSettingsControllerProvider)
      .defaultAiProviderKind;
  if (defaultProvider == null) {
    await _showAiMessage(context, context.l10n.aiConfigureFirst);
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  return showBusyMarkModalDialog<AiProviderKind>(
    context,
    builder: (dialogContext) =>
        _AiProviderChoiceDialog(initialProvider: defaultProvider),
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

class _AiEditConfiguration {
  const _AiEditConfiguration({
    required this.instruction,
    required this.resolvedTarget,
    required this.provider,
  });

  final String instruction;
  final AiMarkdownEditTarget resolvedTarget;
  final AiProviderKind provider;
}

class _AiEditConfigurationDialog extends StatefulWidget {
  const _AiEditConfigurationDialog({
    required this.snapshot,
    required this.initialProvider,
    this.fixedTarget,
  });

  final AiEditorSnapshot snapshot;
  final AiProviderKind initialProvider;
  final AiEditTargetKind? fixedTarget;

  @override
  State<_AiEditConfigurationDialog> createState() =>
      _AiEditConfigurationDialogState();
}

class _AiEditConfigurationDialogState
    extends State<_AiEditConfigurationDialog> {
  final _controller = TextEditingController();
  late AiEditTargetKind _target;
  late AiEditContextKind _context;
  late AiProviderKind _provider;
  AiMarkdownEditTarget? _resolvedTarget;
  String? _resolutionError;

  bool get _blockTargetAvailable =>
      widget.snapshot.blockTargetAvailable &&
      widget.snapshot.documentSource.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
    if (widget.fixedTarget case final fixedTarget?) {
      _target = fixedTarget;
      _context = fixedTarget == AiEditTargetKind.document
          ? AiEditContextKind.document
          : widget.snapshot.hasSelection
          ? AiEditContextKind.selection
          : AiEditContextKind.document;
    } else if (widget.snapshot.hasSelection) {
      _target = AiEditTargetKind.selection;
      _context = AiEditContextKind.selection;
    } else if (_blockTargetAvailable) {
      _target = AiEditTargetKind.block;
      _context = AiEditContextKind.block;
    } else {
      _target = AiEditTargetKind.document;
      _context = widget.snapshot.documentSource.isEmpty
          ? AiEditContextKind.none
          : AiEditContextKind.document;
    }
    _resolveChoices(notify: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTarget = _resolvedTarget;
    return BusyMarkModalEditorScaffold(
      title: context.l10n.aiRefineWithAi,
      cancelLabel: context.l10n.cancel,
      saveLabel: context.l10n.aiGenerateProposal,
      onCancel: () => Navigator.pop(context),
      onSave: _controller.text.trim().isEmpty || _resolvedTarget == null
          ? null
          : () => Navigator.pop(
              context,
              _AiEditConfiguration(
                instruction: _controller.text.trim(),
                resolvedTarget: _resolvedTarget!,
                provider: _provider,
              ),
            ),
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkComboRow<AiProviderKind>(
              key: const ValueKey('ai-edit-provider'),
              title: context.l10n.aiProvider,
              values: AiProviderKind.values,
              selected: _provider,
              labelFor: (provider) => _providerLabel(context, provider),
              onSelected: (provider) => setState(() => _provider = provider),
            ),
            BusyMarkGroupedTextEntry(
              key: const ValueKey('ai-edit-instruction'),
              label: context.l10n.aiInstruction,
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkComboRow<AiEditTargetKind>(
              key: const ValueKey('ai-edit-target'),
              title: context.l10n.aiChangeTarget,
              values: _availableTargets,
              selected: _target,
              labelFor: (value) => _targetLabel(context, value),
              onSelected: (value) {
                _target = value;
                _resolveChoices();
              },
            ),
            if (resolvedTarget != null)
              Semantics(
                container: true,
                label: context.l10n.aiContentToChange,
                child: Padding(
                  key: const ValueKey('ai-content-to-change'),
                  padding: const EdgeInsets.all(BusyMarkSpacing.md),
                  child: _AiContentPreview(
                    content: resolvedTarget.replacementOriginal,
                  ),
                ),
              ),
            BusyMarkComboRow<AiEditContextKind>(
              key: const ValueKey('ai-edit-context'),
              title: context.l10n.aiSharedContext,
              values: _availableContexts,
              selected: _context,
              labelFor: (value) => _contextLabel(context, value),
              onSelected: (value) {
                _context = value;
                _resolveChoices();
              },
            ),
            if (resolvedTarget != null)
              Semantics(
                container: true,
                label: context.l10n.aiContentSentToAi,
                child: Padding(
                  key: const ValueKey('ai-content-sent-to-ai'),
                  padding: const EdgeInsets.all(BusyMarkSpacing.md),
                  child: _AiContentPreview(content: resolvedTarget.input),
                ),
              ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        if (_resolutionError case final error?)
          BusyMarkStatusBox(message: error, kind: BusyMarkStatusKind.warning)
        else if (resolvedTarget != null) ...[
          BusyMarkStatusBox(
            message: context.l10n.aiContextDisclosure(
              resolvedTarget.input.length,
            ),
            kind: BusyMarkStatusKind.information,
          ),
        ],
      ],
    );
  }

  List<AiEditTargetKind> get _availableTargets => [
    for (final value in AiEditTargetKind.values)
      if ((widget.fixedTarget == null || widget.fixedTarget == value) &&
          switch (value) {
            AiEditTargetKind.selection => widget.snapshot.hasSelection,
            AiEditTargetKind.insertAfterBlock ||
            AiEditTargetKind.block ||
            AiEditTargetKind.section => _blockTargetAvailable,
            AiEditTargetKind.document => true,
          })
        value,
  ];

  List<AiEditContextKind> get _availableContexts => [
    for (final value in AiEditContextKind.values)
      if (switch (value) {
        AiEditContextKind.selection => widget.snapshot.hasSelection,
        AiEditContextKind.block ||
        AiEditContextKind.section => _blockTargetAvailable,
        AiEditContextKind.none || AiEditContextKind.document => true,
      })
        value,
  ];

  void _resolveChoices({bool notify = true}) {
    late final VoidCallback update;
    try {
      final snapshot = widget.snapshot;
      final resolved = const AiMarkdownEditResolver().resolve(
        editTarget: _target,
        editContext: _context,
        source: snapshot.documentSource,
        selectionStart: snapshot.selectionStart,
        selectionEnd: snapshot.selectionEnd,
        anchorOffset: snapshot.anchorOffset,
        filePath: snapshot.documentPath ?? 'untitled.md',
      );
      update = () {
        _resolvedTarget = resolved;
        _resolutionError = null;
      };
    } on AiException catch (error) {
      update = () {
        _resolvedTarget = null;
        _resolutionError = error.message;
      };
    }
    if (notify) {
      setState(update);
    } else {
      update();
    }
  }
}

class _AiProviderChoiceDialog extends StatefulWidget {
  const _AiProviderChoiceDialog({required this.initialProvider});

  final AiProviderKind initialProvider;

  @override
  State<_AiProviderChoiceDialog> createState() =>
      _AiProviderChoiceDialogState();
}

class _AiProviderChoiceDialogState extends State<_AiProviderChoiceDialog> {
  late AiProviderKind _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkDialogShell(
      title: context.l10n.aiChooseProvider,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: context.l10n.aiGenerateProposal,
          suggested: true,
          onPressed: () => Navigator.pop(context, _provider),
        ),
      ],
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkComboRow<AiProviderKind>(
              key: const ValueKey('ai-provider-choice'),
              title: context.l10n.aiProvider,
              values: AiProviderKind.values,
              selected: _provider,
              labelFor: (provider) => _providerLabel(context, provider),
              onSelected: (provider) => setState(() => _provider = provider),
            ),
          ],
        ),
      ],
    );
  }
}

String _providerLabel(BuildContext context, AiProviderKind provider) =>
    switch (provider) {
      AiProviderKind.ollamaLocal => context.l10n.aiLocalOllama,
      AiProviderKind.openAi => 'OpenAI',
      AiProviderKind.gemini => 'Google Gemini',
    };

class _AiContentDisclosure extends StatefulWidget {
  const _AiContentDisclosure({required this.title, required this.content});

  final String title;
  final String content;

  @override
  State<_AiContentDisclosure> createState() => _AiContentDisclosureState();
}

class _AiContentDisclosureState extends State<_AiContentDisclosure> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return BusyMarkGroupedList(
      filled: true,
      children: [
        BusyMarkActionRow(
          title: widget.title,
          leading: const Icon(BusyMarkGlyphs.preview),
          trailing: Icon(
            _expanded ? BusyMarkGlyphs.upArrow : BusyMarkGlyphs.downArrow,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: _AiContentPreview(content: widget.content),
          ),
      ],
    );
  }
}

class _AiContentPreview extends StatelessWidget {
  const _AiContentPreview({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140),
          child: SingleChildScrollView(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SelectableText(
                content.isEmpty ? '\u2014' : content,
                style: _monospaceStyle(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _targetLabel(BuildContext context, AiEditTargetKind target) =>
    switch (target) {
      AiEditTargetKind.selection => context.l10n.aiTargetSelection,
      AiEditTargetKind.insertAfterBlock =>
        context.l10n.aiTargetInsertAfterBlock,
      AiEditTargetKind.block => context.l10n.aiTargetCurrentBlock,
      AiEditTargetKind.section => context.l10n.aiTargetCurrentSection,
      AiEditTargetKind.document => context.l10n.aiTargetCompleteDocument,
    };

String _contextLabel(BuildContext context, AiEditContextKind value) =>
    switch (value) {
      AiEditContextKind.none => context.l10n.aiContextNone,
      AiEditContextKind.selection => context.l10n.aiContextSelection,
      AiEditContextKind.block => context.l10n.aiContextCurrentBlock,
      AiEditContextKind.section => context.l10n.aiContextCurrentSection,
      AiEditContextKind.document => context.l10n.aiContextCompleteDocument,
    };

class _AiProposalDialog extends ConsumerStatefulWidget {
  const _AiProposalDialog({
    required this.request,
    required this.invocation,
    this.validateBeforeApply,
    this.staleMessage,
  });

  final AiRequest request;
  final AiEditInvocation invocation;
  final Future<bool> Function()? validateBeforeApply;
  final String? staleMessage;

  @override
  ConsumerState<_AiProposalDialog> createState() => _AiProposalDialogState();
}

class _AiProposalDialogState extends ConsumerState<_AiProposalDialog> {
  late final AiCoordinator _coordinator;
  StreamSubscription<AiStreamEvent>? _subscription;
  final _output = StringBuffer();
  AiUsage? _usage;
  String? _error;
  String? _providerId;
  String? _model;
  var _complete = false;
  var _checkingApply = false;
  var _externalSourceStale = false;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(aiCoordinatorProvider);
    _subscription = _coordinator
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
    _coordinator.cancelRequest(widget.request.id);
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
        !_externalSourceStale &&
        (!widget.invocation.enforceDocumentRevision ||
            (ref.read(workspaceControllerProvider.notifier).editRevision ==
                    widget.invocation.sourceRevision &&
                currentPath == widget.invocation.documentPath));
    final proposal = _output.toString();
    return BusyMarkDialogShell(
      title: context.l10n.aiProposal,
      maxWidth: 960,
      closable: false,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () {
            _coordinator.cancelRequest(widget.request.id);
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
                  !_checkingApply &&
                  proposal.isNotEmpty
              ? () => unawaited(_applyProposal(proposal))
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
        _AiContentDisclosure(
          title: context.l10n.aiViewContext,
          content: widget.request.input,
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        if (_error != null)
          BusyMarkStatusBox(message: _error!, kind: BusyMarkStatusKind.error)
        else if (!revisionCurrent)
          BusyMarkStatusBox(
            message: widget.staleMessage ?? context.l10n.aiStaleProposal,
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

  Future<void> _applyProposal(String proposal) async {
    final validate = widget.validateBeforeApply;
    if (validate != null) {
      setState(() => _checkingApply = true);
      var current = false;
      try {
        current = await validate();
      } on Object {
        current = false;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _checkingApply = false;
        _externalSourceStale = !current;
      });
      if (!current) {
        return;
      }
    }
    if (mounted) {
      Navigator.pop(context, proposal);
    }
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

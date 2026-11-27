import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../app/save_destination_picker.dart';
import '../core/atomic_file_writer.dart';
import '../editor/audio_playback.dart';
import '../editor/document_audio_view.dart';
import 'narration.dart';
import 'speech.dart';
import 'speech_usage.dart';

final _speechDialogs = <_SpeechDialogState>{};

Future<void> settleSpeechDialogsForWindowClose() async {
  await Future.wait([
    for (final dialog in _speechDialogs.toList()) dialog._retire(),
  ]);
}

String speechBackendLabel(BuildContext context, SpeechBackend backend) =>
    switch (backend) {
      SpeechBackend.system => context.l10n.speechSystem,
      SpeechBackend.espeak => 'eSpeak NG',
      SpeechBackend.piper => 'Piper',
      SpeechBackend.gemini => 'Gemini',
      SpeechBackend.openai => 'OpenAI',
      SpeechBackend.elevenLabs => 'ElevenLabs',
      SpeechBackend.ollama => 'Ollama',
    };

String _scopeLabel(BuildContext context, NarrationScope scope) =>
    switch (scope) {
      NarrationScope.selection => context.l10n.speechSelection,
      NarrationScope.block => context.l10n.speechBlock,
      NarrationScope.section => context.l10n.speechSection,
      NarrationScope.document => context.l10n.speechDocument,
    };

class SpeechDialog extends StatefulWidget {
  const SpeechDialog({
    super.key,
    required this.options,
    required this.planForScope,
    required this.initialScope,
    required this.scopes,
    required this.suggestedFilename,
    this.readAloud = false,
    this.sample = false,
    this.insert,
  });

  final SpeechOptions options;
  final NarrationPlan Function(NarrationScope scope) planForScope;
  final NarrationScope initialScope;
  final List<NarrationScope> scopes;
  final String suggestedFilename;
  final bool readAloud;
  final bool sample;
  final Future<bool> Function(NarrationPlan plan, Uint8List bytes)? insert;

  @override
  State<SpeechDialog> createState() => _SpeechDialogState();
}

class _SpeechDialogState extends State<SpeechDialog> {
  final _audio = AudioPlayback.shared;
  final _service = SpeechService();
  late var _scope = widget.initialScope;
  late var _plan = widget.planForScope(_scope);
  AiCancellationToken? _job;
  SpeechResult? _result;
  Directory? _temporary;
  String? _error;
  int _finished = 0;
  int _total = 0;
  bool _publishing = false;
  bool _systemPaused = false;
  bool _systemCompleted = false;
  bool _resumeChunks = false;
  bool _uncertainCloud = false;
  Future<void>? _synthesis;
  Future<void>? _openingPlayback;
  Future<void>? _stoppingPlayback;
  Future<void>? _retirement;

  bool get _system => widget.options.backend == SpeechBackend.system;

  @override
  void initState() {
    super.initState();
    _speechDialogs.add(this);
  }

  @override
  void dispose() {
    unawaited(_retire());
    super.dispose();
  }

  Future<void> _retire() => _retirement ??= _finishWork();

  Future<void> _finishWork() async {
    _job?.cancel();
    try {
      await _synthesis;
    } finally {
      try {
        await _stopPlayback();
      } finally {
        _speechDialogs.remove(this);
      }
    }
  }

  Future<void> _dismiss() async {
    if (_publishing || _retirement != null) return;
    await _retire();
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.pop(context);
    }
  }

  Future<void> _stopPlayback() =>
      _stoppingPlayback ??= _releasePlayback().whenComplete(() {
        _stoppingPlayback = null;
      });

  Future<void> _releasePlayback() async {
    await _openingPlayback;
    await _audio.close(this);
    final directory = _temporary;
    _temporary = null;
    if (directory == null) return;
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // The temporary directory may have already been removed.
    }
  }

  void _startGeneration() {
    if (_retirement != null) return;
    _synthesis = _generate();
    unawaited(_synthesis);
  }

  Future<void> _generate() async {
    if (_job != null || _result != null || _plan.passages.isEmpty) return;
    final job = AiCancellationToken();
    final plan = _plan;
    setState(() {
      _job = job;
      _error = null;
      _finished = _total = 0;
      _systemPaused = _systemCompleted = false;
    });
    SpeechResult? completed;
    try {
      await _audio.pause();
      if (_system) {
        await _service.readSystem(
          plan.segments,
          widget.options,
          cancellationToken: job,
          allowUnverifiedModule: true,
          onProgress: (finished, total) => _progress(job, finished, total),
        );
        if (mounted && identical(_job, job) && !job.isCancelled) {
          setState(() => _systemCompleted = true);
        }
        return;
      }
      final result = await _service.generate(
        plan.segments,
        widget.options,
        cancellationToken: job,
        resumeCompletedChunks: _resumeChunks,
        onProgress: (finished, total) => _progress(job, finished, total),
      );
      completed = result;
      if (!mounted || !identical(_job, job) || job.isCancelled) return;
      setState(() => _result = result);
      if (widget.readAloud) await _play();
    } on AiException catch (error) {
      if (mounted) {
        setState(() {
          _resumeChunks = true;
          _uncertainCloud =
              widget.options.backend.isCloud &&
              (job.isCancelled ||
                  error.code == AiFailureCode.timeout ||
                  error.code == AiFailureCode.connection ||
                  error.code == AiFailureCode.malformedResponse);
          if (!job.isCancelled) _error = error.message;
        });
      }
    } on IOException {
      if (mounted) {
        setState(() {
          _uncertainCloud = widget.options.backend.isCloud;
          _error = context.l10n.speechUnavailable;
        });
      }
    } finally {
      if (widget.options.backend.isCloud) {
        try {
          await SpeechUsageLedger.shared.record(
            widget.options.backend,
            completed,
          );
        } on Exception {
          // The synthesis result remains available if the local ledger is unavailable.
        }
      }
      await job.dispose();
      if (mounted && identical(_job, job)) setState(() => _job = null);
    }
  }

  void _progress(AiCancellationToken job, int finished, int total) {
    if (mounted && identical(_job, job) && !job.isCancelled) {
      setState(() {
        _finished = finished;
        _total = total;
      });
    }
  }

  Future<void> _toggleSystem() async {
    try {
      if (_systemPaused) {
        await _service.resumeSystem();
      } else {
        await _service.pauseSystem();
      }
      if (mounted) setState(() => _systemPaused = !_systemPaused);
    } on AiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _play() async {
    if (_retirement != null || _stoppingPlayback != null) return;
    await (_openingPlayback ??= _preparePlayback().whenComplete(() {
      _openingPlayback = null;
    }));
  }

  Future<void> _preparePlayback() async {
    final result = _result;
    if (result == null) return;
    try {
      final existing = _temporary;
      final directory =
          existing ?? await Directory.systemTemp.createTemp('busymark-speech-');
      if (!mounted) {
        await directory.delete(recursive: true);
        return;
      }
      _temporary = directory;
      final file = File(p.join(directory.path, 'narration.wav'));
      if (!await file.exists()) {
        await file.writeAsBytes(result.wavBytes, flush: true);
      }
      if (mounted) await _audio.open(this, file);
    } on FileSystemException {
      if (mounted) setState(() => _error = context.l10n.audioPlaybackFailure);
    }
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null) return;
    final destination = await pickSaveDestination(
      context,
      suggestedName: widget.suggestedFilename,
      actionLabel: context.l10n.speechSaveAudio,
      filterLabel: context.l10n.speechWav,
      patterns: const ['*.wav'],
      suffix: '.wav',
    );
    if (destination == null || !mounted) return;
    try {
      await const AtomicFileWriter().writeBytes(
        destination.path,
        result.wavBytes,
        overwrite: destination.replacesExisting,
        authorization: destination,
      );
    } on Exception {
      if (mounted) {
        setState(() => _error = context.l10n.errorFileOperationInvalidTarget);
      }
    }
  }

  Future<void> _insert() async {
    final result = _result;
    final publish = widget.insert;
    if (result == null || publish == null || _publishing) return;
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final inserted = await publish(_plan, result.wavBytes);
      if (!mounted) return;
      if (inserted) {
        await _retire();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _error = context.l10n.audioStaleTarget);
      }
    } on AssetPublicationUiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _usageLabel(List<SpeechUsage> usage) {
    int? total(int? Function(SpeechUsage) unit) {
      final values = usage.map(unit).whereType<int>().toList();
      return values.length == usage.length && values.isNotEmpty
          ? values.reduce((a, b) => a + b)
          : null;
    }

    final values = [
      if (total((part) => part.inputTokens) case final input?)
        context.l10n.speechInputTokens(input),
      if (total((part) => part.outputTokens) case final output?)
        context.l10n.speechOutputTokens(output),
      if (total((part) => part.characters) case final chars?)
        context.l10n.speechInputCharacters(chars),
    ];
    return values.isEmpty
        ? context.l10n.speechNoUsage
        : '${context.l10n.speechReportedUsage} · ${values.join(' · ')}';
  }

  String _omission(NarrationOmission omission) => switch (omission) {
    NarrationOmission.headings => context.l10n.speechHeadings,
    NarrationOmission.code => context.l10n.speechCodeBlocks,
    NarrationOmission.tables => context.l10n.speechTables,
    NarrationOmission.quotes => context.l10n.speechQuotes,
    NarrationOmission.images => context.l10n.speechImages,
    NarrationOmission.footnotes => context.l10n.speechFootnotes,
    NarrationOmission.math => context.l10n.speechMathOmitted,
    NarrationOmission.media => context.l10n.speechMediaOmitted,
    NarrationOmission.hidden => context.l10n.speechHiddenOmitted,
    NarrationOmission.unmappedSelection => context.l10n.speechSelectionUnmapped,
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_dismiss());
    },
    child: _buildDialog(context),
  );

  Widget _buildDialog(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    final job = _job;
    final available = widget.readAloud || widget.options.backend.supportsFiles;
    final title = widget.sample
        ? l10n.speechSample
        : widget.readAloud
        ? l10n.readAloud
        : l10n.generateAudio;
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 570,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.sample)
                DropdownButtonFormField<NarrationScope>(
                  initialValue: _scope,
                  decoration: InputDecoration(labelText: l10n.speechScope),
                  items: [
                    for (final scope in widget.scopes)
                      DropdownMenuItem(
                        value: scope,
                        child: Text(_scopeLabel(context, scope)),
                      ),
                  ],
                  onChanged: job != null || result != null
                      ? null
                      : (scope) {
                          if (scope == null) return;
                          setState(() {
                            _scope = scope;
                            _plan = widget.planForScope(scope);
                            _error = null;
                          });
                        },
                ),
              const SizedBox(height: 12),
              Text(
                speechBackendLabel(context, widget.options.backend),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (widget.options.backend.isCloud && result == null) ...[
                const SizedBox(height: 8),
                Text(l10n.speechCloudConsent),
                Text(l10n.speechInputCharacters(_plan.text.runes.length)),
                if (speechPricingPage(widget.options.backend) case final uri?)
                  TextButton(
                    onPressed: () => unawaited(launchUrl(uri)),
                    child: Text(l10n.speechProviderPricing),
                  ),
                if (_uncertainCloud) Text(l10n.speechBillingUncertain),
              ],
              if (_system && widget.readAloud && job == null)
                Text(l10n.speechUnknownLocality),
              if (!available) Text(l10n.speechUnavailable),
              if (_systemCompleted) Text(l10n.speechReadComplete),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 230),
                child: SingleChildScrollView(
                  primary: false,
                  child: SelectableText(
                    _plan.text.isEmpty ? l10n.speechNoText : _plan.text,
                  ),
                ),
              ),
              if (_plan.omissions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.speechOmissions,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(_plan.omissions.map(_omission).join(' · ')),
              ],
              if (job != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _total == 0 ? null : _finished / _total,
                  semanticsLabel: l10n.speechProgress,
                ),
                Text(l10n.speechSynthesizing),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (result != null) ...[
                const SizedBox(height: 12),
                Text(l10n.speechGenerated),
                if (widget.options.backend.isCloud)
                  Text(_usageLabel(result.usage)),
                ListenableBuilder(
                  listenable: _audio,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BusyMarkAudioTransport(
                        owner: this,
                        label: l10n.speechGenerated,
                        start: _play,
                      ),
                      if (widget.readAloud && _audio.owns(this))
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () => unawaited(_stopPlayback()),
                              child: Text(l10n.speechStop),
                            ),
                            if (_audio.seekable) ...[
                              IconButton(
                                tooltip: l10n.speechPreviousSegment,
                                icon: Icon(
                                  BusyMarkGlyphs.previousSegment,
                                  semanticLabel: l10n.speechPreviousSegment,
                                ),
                                onPressed: () {
                                  final target =
                                      result.segmentOffsets
                                          .where(
                                            (offset) =>
                                                offset.inMilliseconds / 1000 <
                                                _audio.position - 0.35,
                                          )
                                          .lastOrNull ??
                                      Duration.zero;
                                  unawaited(
                                    _audio.seek(
                                      this,
                                      target.inMilliseconds / 1000,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: l10n.speechNextSegment,
                                icon: Icon(
                                  BusyMarkGlyphs.nextSegment,
                                  semanticLabel: l10n.speechNextSegment,
                                ),
                                onPressed: () {
                                  final target = result.segmentOffsets
                                      .where(
                                        (offset) =>
                                            offset.inMilliseconds / 1000 >
                                            _audio.position + 0.1,
                                      )
                                      .firstOrNull;
                                  if (target != null) {
                                    unawaited(
                                      _audio.seek(
                                        this,
                                        target.inMilliseconds / 1000,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _publishing ? null : _dismiss,
          child: Text(l10n.close),
        ),
        if (job != null) ...[
          if (_system && _total > 0)
            TextButton(
              onPressed: _toggleSystem,
              child: Text(_systemPaused ? l10n.audioPlay : l10n.audioPause),
            ),
          TextButton(
            onPressed: job.isCancelled ? null : () => setState(job.cancel),
            child: Text(_system ? l10n.speechStop : l10n.speechCancelJob),
          ),
        ] else if (result == null)
          FilledButton(
            onPressed: !available || _plan.passages.isEmpty
                ? null
                : _startGeneration,
            child: Text(title),
          )
        else if (!widget.readAloud && !widget.sample) ...[
          TextButton(
            onPressed: _publishing ? null : _save,
            child: Text(l10n.speechSaveAudio),
          ),
          if (widget.insert != null)
            FilledButton(
              onPressed: _publishing ? null : _insert,
              child: Text(l10n.insertAudio),
            ),
        ],
      ],
    );
  }
}

class AssetPublicationUiException implements Exception {
  const AssetPublicationUiException(this.message);
  final String message;
}

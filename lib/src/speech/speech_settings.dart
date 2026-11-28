import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import 'narration.dart';
import 'speech.dart';
import 'speech_dialog.dart';

class SpeechSettings extends ConsumerStatefulWidget {
  const SpeechSettings({super.key, this.createService = SpeechService.new});

  final SpeechService Function() createService;

  @override
  ConsumerState<SpeechSettings> createState() => _SpeechSettingsState();
}

class _SpeechSettingsState extends ConsumerState<SpeechSettings> {
  late final _service = widget.createService();
  final _key = TextEditingController();
  final _catalogs = <SpeechBackend, SpeechCatalog>{};
  AiCancellationToken? _operation;
  String? _operationLabel;
  ({String message, BusyMarkStatusKind kind})? _status;
  double? _progress;
  bool _invalidSpeed = false;

  @override
  void dispose() {
    _operation?.cancel();
    _key.dispose();
    super.dispose();
  }

  Future<void> _run(
    String label,
    Future<void> Function(AiCancellationToken) action,
  ) async {
    if (_operation != null) return;
    final token = AiCancellationToken();
    setState(() {
      _operation = token;
      _operationLabel = label;
      _status = null;
      _progress = null;
    });
    try {
      await action(token);
    } on AiException catch (error) {
      if (mounted && !token.isCancelled) {
        setState(() {
          _status = (message: error.message, kind: BusyMarkStatusKind.error);
        });
      }
    } on IOException {
      if (mounted && !token.isCancelled) {
        setState(() {
          _status = (
            message: context.l10n.speechUnavailable,
            kind: BusyMarkStatusKind.error,
          );
        });
      }
    } finally {
      await token.dispose();
      if (mounted) {
        setState(() {
          _operation = null;
          _operationLabel = null;
        });
      }
    }
  }

  Future<void> _discover(SpeechOptions options) => _run(
    context.l10n.speechRefresh,
    (token) => _refreshCatalog(options, token),
  );

  Future<void> _refreshCatalog(
    SpeechOptions options,
    AiCancellationToken token,
  ) async {
    final catalog = await _service.discover(options, cancellationToken: token);
    if (!mounted || token.isCancelled) return;
    setState(() {
      _catalogs[options.backend] = catalog;
      if (catalog.unavailableReason case final reason?) {
        _status = (message: reason, kind: BusyMarkStatusKind.warning);
      }
    });
  }

  Future<void> _installPiper(
    SpeechOptions options,
    PiperDownload voice,
    ValueChanged<String> selectVoice,
  ) => _run(context.l10n.speechPiperInstall, (token) async {
    await _service.piperVoices.install(
      voice,
      cancellationToken: token,
      onProgress: (received, total) {
        if (mounted && !token.isCancelled && total > 0) {
          setState(() => _progress = (received / total).clamp(0, 1));
        }
      },
    );
    if (!mounted || token.isCancelled) return;
    await _refreshCatalog(options, token);
    if (mounted && !token.isCancelled) selectVoice(voice.id);
  });

  Future<void> _importPiper(SpeechOptions options) =>
      _run(context.l10n.speechPiperImport, (token) async {
        final model = await openFile(
          acceptedTypeGroups: const [
            XTypeGroup(extensions: ['onnx']),
          ],
        );
        if (model == null || !mounted || token.isCancelled) return;
        await _service.piperVoices.importVoice(
          File(model.path),
          File('${model.path}.json'),
          File(p.join(p.dirname(model.path), 'MODEL_CARD')),
          cancellationToken: token,
        );
        await _refreshCatalog(options, token);
      });

  void _sample(SpeechOptions options) {
    final l10n = context.l10n;
    final plan = NarrationPlan(
      documentId: 'voice-sample',
      providerId: options.backend.name,
      revision: 0,
      scope: NarrationScope.document,
      insertionOffset: 0,
      passages: [
        (
          speech: SpeechSegment(
            l10n.speechSampleText,
            language: nonBlankSpeechSetting(options.language),
          ),
          source: null,
        ),
      ],
      omissions: const [],
    );
    final service = widget.createService();
    unawaited(
      showSpeechNarrationDialog(
        context,
        options: options,
        planForScope: (_) => plan,
        initialScope: NarrationScope.document,
        scopes: const [NarrationScope.document],
        suggestedFilename: 'busymark-sample.wav',
        sample: true,
        readAloud: options.backend == SpeechBackend.system,
        service: service,
      ),
    );
  }

  Future<void> _keyAction(SpeechBackend provider, {required bool delete}) =>
      _run(
        delete ? context.l10n.speechDeleteKey : context.l10n.speechStoreKey,
        (_) async {
          const vault = SpeechCredentials();
          if (delete) {
            await vault.delete(provider);
          } else {
            await vault.write(provider, _key.text);
          }
          if (!mounted) return;
          _key.clear();
          setState(() {
            _catalogs.remove(provider);
            _status = (
              message: delete
                  ? context.l10n.speechKeyDeleted
                  : context.l10n.speechKeyStored,
              kind: BusyMarkStatusKind.success,
            );
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(
      appSettingsControllerProvider.select((value) => value.speech),
    );
    final save = ref
        .read(appSettingsControllerProvider.notifier)
        .setSpeechPreferences;
    final options = settings.options;
    final engine = options.backend;
    final rules = settings.narration;
    final busy = _operation != null;
    final catalog = _catalogs[engine];
    final speedRange = engine.synthesisSpeed;
    final speedInvalid =
        speedRange != null &&
        (_invalidSpeed || !speedRange.allows(options.speed));
    void update({
      String? model,
      String? voice,
      String? language,
      double? speed,
      int? pitch,
      String? style,
    }) {
      final latest = ref.read(appSettingsControllerProvider).speech;
      if (latest.backend != engine) return;
      final current = latest.options;
      unawaited(
        save(
          latest.copyWith(
            options: SpeechOptions(
              backend: engine,
              model: model ?? current.model,
              voice: voice ?? current.voice,
              language: language ?? current.language,
              speed: speed ?? current.speed,
              pitch: pitch ?? current.pitch,
              style: style ?? current.style,
            ),
          ),
        ),
      );
    }

    void updateNarration(String field, Object? value) {
      final latest = ref.read(appSettingsControllerProvider).speech;
      unawaited(
        save(
          latest.copyWith(
            narration: NarrationRules.fromJson({
              ...latest.narration.toJson(),
              field: value,
            }),
          ),
        ),
      );
    }

    final voices = [
      for (final voice in catalog?.voices ?? const <SpeechChoice>[])
        if (voice.model == null ||
            options.model.isEmpty ||
            voice.model == options.model)
          voice,
    ];
    final models = catalog?.models ?? const <SpeechChoice>[];
    final speedBounds = speedRange == null
        ? null
        : '${speedRange.minimum}–${speedRange.maximum}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkGroupedList(
          title: l10n.speech,
          filled: true,
          children: [
            BusyMarkComboRow<SpeechBackend>(
              title: l10n.speechProvider,
              values: SpeechBackend.values,
              selected: engine,
              labelFor: (backend) => speechBackendLabel(context, backend),
              leading: const Icon(BusyMarkGlyphs.speaker),
              enabled: !busy,
              onSelected: (backend) {
                _key.clear();
                setState(() {
                  _status = null;
                  _invalidSpeed = false;
                });
                unawaited(save(settings.copyWith(backend: backend)));
              },
            ),
            if (models.isNotEmpty)
              _SpeechChoiceRow(
                title: l10n.speechModel,
                choices: models,
                selected: options.model,
                enabled: !busy,
                onSelected: (value) => update(model: value),
              ),
            if (voices.isNotEmpty)
              _SpeechChoiceRow(
                title: l10n.speechVoice,
                choices: voices,
                selected: options.voice,
                enabled: !busy,
                onSelected: (value) => update(voice: value),
              ),
            BusyMarkGroupedTextEntry(
              key: ValueKey((engine, 'language')),
              label: l10n.speechLanguage,
              initialValue: options.language,
              enabled: !busy,
              onChanged: (value) => update(language: value.trim()),
            ),
            if (engine == SpeechBackend.gemini)
              BusyMarkGroupedTextEntry(
                key: ValueKey((engine, 'style')),
                label: l10n.speechStyle,
                initialValue: options.style,
                enabled: !busy,
                onChanged: (value) => update(style: value.trim()),
              ),
            if (speedRange != null)
              BusyMarkGroupedTextEntry(
                key: ValueKey((engine, 'speed')),
                label: l10n.speechSpeed,
                initialValue: options.speed.toString(),
                errorText: speedInvalid ? speedBounds : null,
                trailing: speedInvalid
                    ? null
                    : Text(speedBounds!, textDirection: TextDirection.ltr),
                enabled: !busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final speed = double.tryParse(value.trim());
                  final valid = speedRange.allows(speed);
                  setState(() => _invalidSpeed = !valid);
                  if (valid) update(speed: speed);
                },
              ),
            if (engine.supportsPitch)
              BusyMarkGroupedTextEntry(
                key: ValueKey((engine, 'pitch')),
                label: l10n.speechPitch,
                initialValue: options.pitch.toString(),
                enabled: !busy,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (int.tryParse(value.trim()) case final pitch?) {
                    update(pitch: pitch.clamp(0, 99));
                  }
                },
              ),
          ],
        ),
        if (engine.isCloud)
          BusyMarkGroupedList(
            title: l10n.speechCloud,
            description: l10n.speechCloudConsent,
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                key: ValueKey((engine, 'credential')),
                label: l10n.speechKey,
                controller: _key,
                enabled: !busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
              ),
              BusyMarkActionRow(
                title: l10n.speechStoreKey,
                leading: const Icon(BusyMarkGlyphs.check),
                enabled: !busy,
                onTap: () => unawaited(_keyAction(engine, delete: false)),
              ),
              BusyMarkActionRow(
                title: l10n.speechDeleteKey,
                leading: const Icon(BusyMarkGlyphs.delete),
                destructive: true,
                enabled: !busy,
                onTap: () => unawaited(_keyAction(engine, delete: true)),
              ),
            ],
          ),
        if (engine == SpeechBackend.piper)
          BusyMarkGroupedList(
            title: l10n.speechPiperModel,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: l10n.speechPiperImport,
                leading: const Icon(BusyMarkGlyphs.folderOpen),
                enabled: !busy,
                onTap: () => unawaited(_importPiper(options)),
              ),
              for (final voice in PiperVoiceStore.downloads)
                BusyMarkActionRow(
                  title: '${l10n.speechPiperInstall} · ${voice.label}',
                  titleWidget: Text(
                    '${l10n.speechPiperInstall} · ${voice.label}',
                  ),
                  subtitleWidget: Text(
                    '${l10n.settingsMebibytesValue((voice.size / 1048576).round())} · ${voice.license}',
                  ),
                  leading: const Icon(BusyMarkGlyphs.pull),
                  enabled: !busy,
                  onTap: () => unawaited(
                    _installPiper(options, voice, (id) => update(voice: id)),
                  ),
                ),
            ],
          ),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkActionRow(
              title: l10n.speechRefresh,
              leading: const Icon(BusyMarkGlyphs.refresh),
              enabled: !busy,
              onTap: () => unawaited(_discover(options)),
            ),
            BusyMarkActionRow(
              title: l10n.speechSample,
              leading: const Icon(BusyMarkGlyphs.play),
              enabled: !busy && !speedInvalid,
              onTap: () => _sample(options),
            ),
            if (_operation case final operation?) ...[
              Padding(
                padding: const EdgeInsets.all(BusyMarkSpacing.md),
                child: BusyMarkProgressIndicator(
                  value: _progress,
                  semanticsLabel: _operationLabel,
                ),
              ),
              BusyMarkActionRow(
                title: l10n.cancel,
                enabled: !operation.isCancelled,
                onTap: () => setState(operation.cancel),
              ),
            ],
          ],
        ),
        if (_status case final status?)
          Padding(
            padding: const EdgeInsets.only(top: BusyMarkSpacing.md),
            child: BusyMarkStatusBox(
              message: status.message,
              kind: status.kind,
            ),
          ),
        BusyMarkGroupedList(
          title: l10n.readAloud,
          filled: true,
          children: [
            for (final (name, label, enabled) in [
              ('headings', l10n.speechHeadings, rules.headings),
              ('codeBlocks', l10n.speechCodeBlocks, rules.codeBlocks),
              ('inlineCode', l10n.speechInlineCode, rules.inlineCode),
              ('tables', l10n.speechTables, rules.tables),
              ('quotes', l10n.speechQuotes, rules.quotes),
              ('images', l10n.speechImages, rules.images),
              ('footnotes', l10n.speechFootnotes, rules.footnotes),
            ])
              BusyMarkSwitchRow(
                title: label,
                value: enabled,
                onChanged: (value) => updateNarration(name, value),
              ),
            BusyMarkComboRow<NarrationLinks>(
              title: l10n.speechLinks,
              values: NarrationLinks.values,
              selected: rules.links,
              labelFor: (value) => switch (value) {
                NarrationLinks.label => l10n.speechLinksLabel,
                NarrationLinks.labelAndUrl => l10n.speechLinksUrl,
                NarrationLinks.skip => l10n.speechLinksSkip,
              },
              onSelected: (value) => updateNarration('links', value.name),
            ),
            for (final (name, label, duration) in [
              ('blockPause', l10n.speechBlockPause, rules.blockPause),
              ('sectionPause', l10n.speechSectionPause, rules.sectionPause),
            ])
              BusyMarkGroupedTextEntry(
                key: ValueKey(name),
                label: label,
                initialValue: duration.inMilliseconds.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    updateNarration(name, int.tryParse(value.trim())),
              ),
          ],
        ),
        BusyMarkGroupedList(
          title: l10n.generateAudio,
          filled: true,
          children: [
            if (engine.supportsFiles)
              BusyMarkActionRow(
                title: l10n.speechWav,
                leading: const Icon(BusyMarkGlyphs.audioFile),
              ),
            BusyMarkGroupedTextEntry(
              label: l10n.audioDestination,
              initialValue: settings.audioDirectory,
              onChanged: (value) => unawaited(
                save(settings.copyWith(audioDirectory: value.trim())),
              ),
            ),
            BusyMarkGroupedTextEntry(
              label: l10n.speechFilename,
              initialValue: settings.outputName,
              onChanged: (value) =>
                  unawaited(save(settings.copyWith(outputName: value.trim()))),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeechChoiceRow extends StatelessWidget {
  const _SpeechChoiceRow({
    required this.title,
    required this.choices,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String title;
  final List<SpeechChoice> choices;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final available = {for (final choice in choices) choice.id: choice.label};
    return BusyMarkComboRow<String>(
      title: title,
      values: [
        if (!available.containsKey(selected)) selected,
        ...available.keys,
      ],
      selected: selected,
      labelFor: (id) =>
          available[id] ??
          (id.isEmpty ? '—' : '$id · ${context.l10n.speechUnavailable}'),
      enabled: enabled,
      onSelected: onSelected,
    );
  }
}

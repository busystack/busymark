import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
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
  String? _status;
  double? _progress;
  bool _invalidSpeed = false;

  @override
  void dispose() {
    _operation?.cancel();
    _key.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AiCancellationToken) action) async {
    if (_operation != null) return;
    final token = AiCancellationToken();
    setState(() {
      _operation = token;
      _status = null;
      _progress = null;
    });
    try {
      await action(token);
    } on AiException catch (error) {
      if (mounted && !token.isCancelled) {
        setState(() => _status = error.message);
      }
    } on IOException {
      if (mounted && !token.isCancelled) {
        setState(() => _status = context.l10n.speechUnavailable);
      }
    } finally {
      await token.dispose();
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<void> _discover(SpeechOptions options) => _run((token) async {
    final catalog = await _service.discover(options, cancellationToken: token);
    if (!mounted || token.isCancelled) return;
    setState(() {
      _catalogs[options.backend] = catalog;
      _status = catalog.unavailableReason;
    });
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
      showDialog<void>(
        context: context,
        builder: (_) => SpeechDialog(
          options: options,
          planForScope: (_) => plan,
          initialScope: NarrationScope.document,
          scopes: const [NarrationScope.document],
          suggestedFilename: 'busymark-sample.wav',
          sample: true,
          readAloud: options.backend == SpeechBackend.system,
          service: service,
        ),
      ),
    );
  }

  Future<void> _keyAction(SpeechBackend provider, {required bool delete}) =>
      _run((_) async {
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
          _status = delete
              ? context.l10n.speechKeyDeleted
              : context.l10n.speechKeyStored;
        });
      });

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
      unawaited(
        save(
          settings.copyWith(
            options: SpeechOptions(
              backend: engine,
              model: model ?? options.model,
              voice: voice ?? options.voice,
              language: language ?? options.language,
              speed: speed ?? options.speed,
              pitch: pitch ?? options.pitch,
              style: style ?? options.style,
            ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<SpeechBackend>(
          initialValue: engine,
          decoration: InputDecoration(labelText: l10n.speechProvider),
          items: [
            for (final backend in SpeechBackend.values)
              DropdownMenuItem(
                value: backend,
                child: Text(speechBackendLabel(context, backend)),
              ),
          ],
          onChanged: busy
              ? null
              : (backend) {
                  if (backend == null) return;
                  _key.clear();
                  setState(() {
                    _status = null;
                    _invalidSpeed = false;
                  });
                  unawaited(save(settings.copyWith(backend: backend)));
                },
        ),
        if (engine.isCloud) ...[
          const SizedBox(height: 12),
          Text(l10n.speechCloudConsent),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: l10n.speechKey),
          ),
          Wrap(
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => _keyAction(engine, delete: false),
                child: Text(l10n.speechStoreKey),
              ),
              TextButton(
                onPressed: busy ? null : () => _keyAction(engine, delete: true),
                child: Text(l10n.speechDeleteKey),
              ),
            ],
          ),
        ],
        if (engine == SpeechBackend.piper) ...[
          Wrap(
            children: [
              for (final voice in PiperVoiceStore.downloads)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => _run((token) async {
                          await _service.piperVoices.install(
                            voice,
                            cancellationToken: token,
                            onProgress: (received, total) {
                              if (mounted && total > 0) {
                                setState(
                                  () => _progress = (received / total).clamp(
                                    0,
                                    1,
                                  ),
                                );
                              }
                            },
                          );
                          if (mounted && !token.isCancelled) {
                            final fresh = await _service.discover(
                              options,
                              cancellationToken: token,
                            );
                            if (mounted) {
                              setState(() => _catalogs[engine] = fresh);
                            }
                            update(voice: voice.id);
                          }
                        }),
                  child: Text(
                    '${l10n.speechPiperInstall} · ${voice.label} · ${(voice.size / 1048576).toStringAsFixed(0)} MiB · ${voice.license}',
                  ),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final model = await openFile(
                          acceptedTypeGroups: const [
                            XTypeGroup(extensions: ['onnx']),
                          ],
                        );
                        if (model == null || !mounted) return;
                        final directory = p.dirname(model.path);
                        await _run((token) async {
                          await _service.piperVoices.importVoice(
                            File(model.path),
                            File('${model.path}.json'),
                            File(p.join(directory, 'MODEL_CARD')),
                            cancellationToken: token,
                          );
                          final fresh = await _service.discover(
                            options,
                            cancellationToken: token,
                          );
                          if (mounted) {
                            setState(() => _catalogs[engine] = fresh);
                          }
                        });
                      },
                child: Text(l10n.speechPiperImport),
              ),
            ],
          ),
        ],
        Wrap(
          children: [
            TextButton(
              onPressed: busy ? null : () => _discover(options),
              child: Text(l10n.speechRefresh),
            ),
            TextButton(
              onPressed: busy || speedInvalid ? null : () => _sample(options),
              child: Text(l10n.speechSample),
            ),
            if (busy)
              TextButton(
                onPressed: () => _operation?.cancel(),
                child: Text(l10n.cancel),
              ),
          ],
        ),
        if (busy) LinearProgressIndicator(value: _progress),
        if (_status case final status?) Text(status),
        if (engine.supportsFiles) Text(l10n.speechWav),
        if (models.isNotEmpty)
          _ChoiceField(
            key: ValueKey((engine, 'model', options.model)),
            label: l10n.speechModel,
            choices: models,
            selected: options.model,
            onChanged: (value) => update(model: value),
          ),
        if (voices.isNotEmpty)
          _ChoiceField(
            key: ValueKey((engine, 'voice', options.voice)),
            label: l10n.speechVoice,
            choices: voices,
            selected: options.voice,
            onChanged: (value) => update(voice: value),
          ),
        _settingField(
          key: ValueKey((engine, 'language')),
          label: l10n.speechLanguage,
          value: options.language,
          save: (value) => update(language: value),
        ),
        if (engine == SpeechBackend.gemini)
          _settingField(
            key: ValueKey((engine, 'style')),
            label: l10n.speechStyle,
            value: options.style,
            save: (value) => update(style: value),
          ),
        if (speedRange != null)
          _settingField(
            key: ValueKey((engine, 'speed')),
            label: l10n.speechSpeed,
            value: options.speed.toString(),
            range: '${speedRange.minimum}–${speedRange.maximum}',
            invalid: speedInvalid,
            save: (value) {
              final speed = double.tryParse(value);
              final valid = speedRange.allows(speed);
              setState(() => _invalidSpeed = !valid);
              if (valid) update(speed: speed);
            },
          ),
        if (engine.supportsPitch)
          _settingField(
            key: ValueKey((engine, 'pitch')),
            label: l10n.speechPitch,
            value: options.pitch.toString(),
            save: (value) {
              if (int.tryParse(value) case final pitch?) {
                update(pitch: pitch.clamp(0, 99));
              }
            },
          ),
        for (final (name, label, enabled) in [
          ('headings', l10n.speechHeadings, rules.headings),
          ('codeBlocks', l10n.speechCodeBlocks, rules.codeBlocks),
          ('inlineCode', l10n.speechInlineCode, rules.inlineCode),
          ('tables', l10n.speechTables, rules.tables),
          ('quotes', l10n.speechQuotes, rules.quotes),
          ('images', l10n.speechImages, rules.images),
          ('footnotes', l10n.speechFootnotes, rules.footnotes),
        ])
          SwitchListTile(
            title: Text(label),
            contentPadding: EdgeInsets.zero,
            value: enabled,
            onChanged: (value) => unawaited(
              save(
                settings.copyWith(
                  narration: NarrationRules.fromJson({
                    ...rules.toJson(),
                    name: value,
                  }),
                ),
              ),
            ),
          ),
        DropdownButtonFormField<NarrationLinks>(
          initialValue: rules.links,
          decoration: InputDecoration(labelText: l10n.speechLinks),
          items: [
            for (final (rule, label) in [
              (NarrationLinks.label, l10n.speechLinksLabel),
              (NarrationLinks.labelAndUrl, l10n.speechLinksUrl),
              (NarrationLinks.skip, l10n.speechLinksSkip),
            ])
              DropdownMenuItem(value: rule, child: Text(label)),
          ],
          onChanged: (value) {
            if (value != null) {
              unawaited(
                save(
                  settings.copyWith(
                    narration: NarrationRules.fromJson({
                      ...rules.toJson(),
                      'links': value.name,
                    }),
                  ),
                ),
              );
            }
          },
        ),
        for (final (name, label, duration) in [
          ('blockPause', l10n.speechBlockPause, rules.blockPause),
          ('sectionPause', l10n.speechSectionPause, rules.sectionPause),
        ])
          _settingField(
            key: ValueKey(name),
            label: label,
            value: duration.inMilliseconds.toString(),
            save: (value) => unawaited(
              save(
                settings.copyWith(
                  narration: NarrationRules.fromJson({
                    ...rules.toJson(),
                    name: int.tryParse(value),
                  }),
                ),
              ),
            ),
          ),
        _settingField(
          label: l10n.audioDestination,
          value: settings.audioDirectory,
          save: (value) =>
              unawaited(save(settings.copyWith(audioDirectory: value))),
        ),
        _settingField(
          label: l10n.speechFilename,
          value: settings.outputName,
          save: (value) =>
              unawaited(save(settings.copyWith(outputName: value))),
        ),
      ],
    );
  }
}

Widget _settingField({
  Key? key,
  required String label,
  required String value,
  required ValueChanged<String> save,
  String? range,
  bool invalid = false,
}) => Padding(
  key: key,
  padding: const EdgeInsets.only(top: 12),
  child: TextFormField(
    initialValue: value,
    keyboardType: range == null
        ? null
        : const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      helperText: invalid ? null : range,
      errorText: invalid ? range : null,
    ),
    onChanged: (value) => save(value.trim()),
  ),
);

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    super.key,
    required this.label,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<SpeechChoice> choices;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = {for (final choice in choices) choice.id: choice.label};
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          if (selected.isEmpty)
            const DropdownMenuItem(value: '', child: Text('—')),
          if (selected.isNotEmpty && !available.containsKey(selected))
            DropdownMenuItem(
              value: selected,
              child: Text('$selected · ${context.l10n.speechUnavailable}'),
            ),
          for (final item in available.entries)
            DropdownMenuItem(
              value: item.key,
              child: Text(item.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

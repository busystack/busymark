import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/localization.dart';
import '../../writerside/writerside_template_service.dart';
import '../../writerside/writerside_topic_file_name.dart';

typedef WritersideTemplatePreviewBuilder =
    Widget Function(
      BuildContext context,
      WritersideTemplate template,
      String title,
      String filename,
    );

class WritersideTemplateDialog extends ConsumerStatefulWidget {
  const WritersideTemplateDialog({
    super.key,
    required this.previewBuilder,
    required this.onCreate,
    required this.existingIds,
  });
  final WritersideTemplatePreviewBuilder previewBuilder;
  final Future<String?> Function(
    WritersideTemplate template,
    String title,
    String filename,
  )
  onCreate;
  final Set<String> existingIds;

  @override
  ConsumerState<WritersideTemplateDialog> createState() =>
      _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<WritersideTemplateDialog> {
  final _search = TextEditingController();
  final _title = TextEditingController();
  final _filename = TextEditingController();
  List<WritersideTemplate>? _templates;
  WritersideTemplate? _selected;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final templates = await ref
          .read(writersideTemplateServiceProvider)
          .catalog();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _error = null;
        final next =
            templates.where((item) => item.id == _selected?.id).firstOrNull ??
            (templates.where((item) => item.category == 'default').toList()
                  ..sort((a, b) => a.name.compareTo(b.name)))
                .firstOrNull;
        if (next != null && next.id != _selected?.id) {
          _select(next);
        } else {
          _selected = next;
        }
      });
    } on Object {
      if (mounted) setState(() => _error = context.l10n.tocTemplateLoadError);
    }
  }

  void _select(WritersideTemplate template) {
    _selected = template;
    _title.text = template.name;
    final base = WritersideTemplateService.filenameFromTitle(template.name);
    var filename = base;
    for (var index = 1; widget.existingIds.contains(filename); index++) {
      filename = '$base-$index';
    }
    _filename.text = filename;
    _error = null;
  }

  @override
  void dispose() {
    _search.dispose();
    _title.dispose();
    _filename.dispose();
    super.dispose();
  }

  String? get _filenameError {
    final value = _filename.text.trim();
    if (value.isEmpty) return context.l10n.fileNameRequired;
    if (!isValidWritersideTopicId(value)) {
      return context.l10n.useIdentifierCharacters;
    }
    if (widget.existingIds.contains(value)) {
      return context.l10n.topicIdAlreadyExists;
    }
    return null;
  }

  Future<void> _edit({bool create = false}) async {
    await showBusyMarkModalDialog<void>(
      context,
      builder: (_) => WritersideTemplatesEditor(
        createNew: create,
        selectedId: _selected?.category == 'tgdp' ? null : _selected?.id,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _create() async {
    if (_busy ||
        _selected == null ||
        _filenameError != null ||
        _title.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onCreate(
        _selected!,
        _title.text.trim(),
        _filename.text.trim(),
      );
    } on Object {
      if (mounted) error = context.l10n.createWritersideTopicFailed;
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final groups = <String, WritersideTemplate>{};
    for (final template in _templates ?? <WritersideTemplate>[]) {
      if (template.name.toLowerCase().contains(_search.text.toLowerCase())) {
        groups.putIfAbsent(template.groupKey, () => template);
      }
    }
    return PopScope(
      canPop: !_busy,
      child: BusyMarkDialogShell(
        title: context.l10n.tocTemplateDialog,
        maxWidth: 1060,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: _busy ? null : () => Navigator.pop(context),
          ),
          BusyMarkDialogButton(
            label: context.l10n.create,
            suggested: true,
            onPressed:
                !_busy &&
                    selected != null &&
                    _filenameError == null &&
                    _title.text.trim().isNotEmpty
                ? _create
                : null,
          ),
        ],
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .65).clamp(280, 630),
            child: AbsorbPointer(
              absorbing: _busy,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 230,
                    child: Column(
                      children: [
                        TextField(
                          key: const ValueKey('template-search'),
                          controller: _search,
                          decoration: InputDecoration(
                            hintText: context.l10n.search,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final category in [
                                'default',
                                'custom',
                                'tgdp',
                              ])
                                ExpansionTile(
                                  key: ValueKey(
                                    'template-category-$category-${_search.text.isNotEmpty}',
                                  ),
                                  initiallyExpanded:
                                      category != 'tgdp' ||
                                      _search.text.isNotEmpty,
                                  title: Text(
                                    _categoryLabel(context, category),
                                  ),
                                  children: [
                                    for (final template
                                        in (groups.values
                                            .where(
                                              (entry) =>
                                                  entry.category == category,
                                            )
                                            .toList()
                                          ..sort(
                                            (a, b) => a.name.compareTo(b.name),
                                          )))
                                      ListTile(
                                        dense: true,
                                        key: ValueKey(
                                          'template-${template.id}',
                                        ),
                                        selected:
                                            selected?.groupKey ==
                                            template.groupKey,
                                        title: Text(template.name),
                                        onTap: () =>
                                            setState(() => _select(template)),
                                      ),
                                    if (category == 'custom')
                                      TextButton(
                                        onPressed: () => _edit(create: true),
                                        child: Text(
                                          context.l10n.tocCreateCustomTemplate,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_templates == null && _error == null)
                          const LinearProgressIndicator(),
                        if (selected != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('template-title'),
                                  controller: _title,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.tocTopicTitleField,
                                    errorText: _title.text.trim().isEmpty
                                        ? context.l10n.topicTitleRequired
                                        : null,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              TextButton(
                                onPressed: selected.url == null
                                    ? _edit
                                    : () => launchUrl(
                                        Uri.parse(selected.url!),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                child: Text(
                                  selected.url == null
                                      ? context.l10n.tocEditTemplates
                                      : context.l10n.source,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const ValueKey('template-filename'),
                            controller: _filename,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: context.l10n.tocTemplateFilename,
                              suffixText: '.${selected.extension}',
                              errorText: _filenameError,
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _create(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(context.l10n.tocTemplateFormat),
                              const SizedBox(width: 12),
                              for (final extension in ['md', 'topic'])
                                YaruRadioButton<String>(
                                  value: extension,
                                  groupValue: selected.extension,
                                  title: Text(
                                    extension == 'md'
                                        ? context.l10n.tocTemplateMarkdown
                                        : context.l10n.tocTemplateXml,
                                  ),
                                  onChanged:
                                      !_templates!.any(
                                        (entry) =>
                                            entry.groupKey ==
                                                selected.groupKey &&
                                            entry.extension == extension,
                                      )
                                      ? null
                                      : (value) => setState(() {
                                          _selected = _templates!.firstWhere(
                                            (entry) =>
                                                entry.groupKey ==
                                                    selected.groupKey &&
                                                entry.extension == value,
                                          );
                                        }),
                                ),
                            ],
                          ),
                          const Divider(),
                          Expanded(
                            child: ClipRect(
                              child: widget.previewBuilder(
                                context,
                                selected,
                                _title.text,
                                _filename.text,
                              ),
                            ),
                          ),
                        ],
                        if (_error != null)
                          BusyMarkStatusBox(
                            message: _error!,
                            kind: BusyMarkStatusKind.error,
                          ),
                        if (_templates == null && _error != null)
                          TextButton(
                            onPressed: _load,
                            child: Text(context.l10n.tocTemplateRetry),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryLabel(BuildContext context, String category) =>
    switch (category) {
      'default' => context.l10n.tocTemplateDefault,
      'custom' => context.l10n.tocTemplateCustom,
      _ => 'The Good Docs Project',
    };

/// A scoped adaptation of File and Code Templates, not an IDE-wide settings
/// clone. Files edits user templates; Internal edits built-in source overrides.
/// All fields are staged until OK. Cancel never publishes edits or deletions.
class WritersideTemplatesEditor extends ConsumerStatefulWidget {
  const WritersideTemplatesEditor({
    super.key,
    this.createNew = false,
    this.selectedId,
  });
  final bool createNew;
  final String? selectedId;
  @override
  ConsumerState<WritersideTemplatesEditor> createState() =>
      _TemplatesEditorState();
}

class _TemplatesEditorState extends ConsumerState<WritersideTemplatesEditor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  WritersideTemplateSnapshot? _snapshot;
  List<WritersideTemplate> _base = [];
  List<WritersideTemplate> _draft = [];
  WritersideTemplate? _selected;
  final _name = TextEditingController();
  final _source = TextEditingController();
  bool _internal = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ref.read(writersideTemplateServiceProvider);
      final snapshot = await service.read();
      final base = await service.bundled();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _base = base;
        _draft = [...snapshot.entries];
        _error = null;
        final selected = _all
            .where((entry) => entry.id == widget.selectedId)
            .firstOrNull;
        _internal = !widget.createNew && selected?.category == 'default';
        _tabs.index = _internal ? 1 : 0;
        _select(selected ?? _visible.firstOrNull);
        if (widget.createNew) _add();
      });
    } on Object {
      if (mounted) setState(() => _error = context.l10n.tocTemplateLoadError);
    }
  }

  List<WritersideTemplate> get _all =>
      WritersideTemplateService.effectiveCatalog(_base, _draft);
  List<WritersideTemplate> get _visible =>
      _all
          .where(
            (entry) => entry.category == (_internal ? 'default' : 'custom'),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  void _select(WritersideTemplate? entry) {
    _selected = entry;
    _name.text = entry?.name ?? '';
    _source.text = entry?.source ?? '';
  }

  void _update({String? extension}) {
    final selected = _selected;
    if (selected == null) return;
    final next = selected.copyWith(
      name: _name.text,
      source: _source.text,
      extension: extension,
    );
    _draft.removeWhere((entry) => entry.id == next.id);
    _draft.add(next);
    _selected = next;
    _error = null;
  }

  void _add({WritersideTemplate? copy}) {
    final entry = WritersideTemplate(
      id: const Uuid().v4(),
      name: WritersideTemplateService.uniqueName(
        copy?.name ?? context.l10n.tocTemplateUnnamed,
        _all.map((entry) => entry.name),
      ),
      category: 'custom',
      extension: copy?.extension ?? 'md',
      source: copy?.source ?? '',
    );
    _internal = false;
    _tabs.index = 0;
    _draft.add(entry);
    _select(entry);
  }

  String? get _validationError {
    final names = <String>{};
    for (final entry in _all) {
      if (entry.name.trim().isEmpty) return context.l10n.fileNameRequired;
      if (!names.add('${entry.category}:${entry.name}.${entry.extension}')) {
        return context.l10n.tocTemplateDuplicateName;
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_snapshot == null || _busy || _validationError != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(writersideTemplateServiceProvider)
          .save(_snapshot!, _draft);
      if (mounted) Navigator.pop(context);
    } on WritersideTemplateConflict {
      if (mounted) setState(() => _error = context.l10n.tocTemplateConflict);
    } on Object {
      if (mounted) setState(() => _error = context.l10n.tocTemplateSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _source.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: BusyMarkDialogShell(
      title: context.l10n.tocTemplatesEditor,
      maxWidth: 1000,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: context.l10n.tocOk,
          suggested: true,
          onPressed: _snapshot != null && !_busy && _validationError == null
              ? _save
              : null,
        ),
      ],
      children: [
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * .6).clamp(260, 600),
          child: AbsorbPointer(
            absorbing: _busy,
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: YaruTabBar(
                        tabController: _tabs,
                        tabs: [
                          YaruTab(label: context.l10n.files),
                          YaruTab(label: context.l10n.tocTemplatesInternal),
                        ],
                        onTap: (index) => setState(() {
                          _internal = index == 1;
                          _select(_visible.firstOrNull);
                        }),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _snapshot == null
                          ? null
                          : () => setState(() => _add()),
                      child: Text(context.l10n.tocTemplateNew),
                    ),
                    TextButton(
                      onPressed: _selected == null
                          ? null
                          : () => setState(() => _add(copy: _selected)),
                      child: Text(context.l10n.tocDuplicate),
                    ),
                    TextButton(
                      onPressed: _selected == null
                          ? null
                          : () => setState(() {
                              _draft.removeWhere(
                                (entry) => entry.id == _selected!.id,
                              );
                              _select(
                                _internal
                                    ? _base.firstWhere(
                                        (entry) => entry.id == _selected!.id,
                                      )
                                    : _visible.firstOrNull,
                              );
                            }),
                      child: Text(
                        _internal
                            ? context.l10n.tocTemplateReset
                            : context.l10n.delete,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 230,
                        child: ListView(
                          children: [
                            for (final entry in _visible)
                              ListTile(
                                dense: true,
                                selected: entry.id == _selected?.id,
                                title: Text('${entry.name}.${entry.extension}'),
                                onTap: () => setState(() => _select(entry)),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: _selected == null
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          key: const ValueKey(
                                            'template-editor-name',
                                          ),
                                          controller: _name,
                                          readOnly: _internal,
                                          decoration: InputDecoration(
                                            labelText:
                                                context.l10n.tocTemplateName,
                                          ),
                                          onChanged: (_) => setState(_update),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 110,
                                        child: BusyMarkPopupSelector<String>(
                                          key: ValueKey(
                                            'template-extension-${_selected!.id}-${_selected!.extension}',
                                          ),
                                          value: _selected!.extension,
                                          label: _selected!.extension,
                                          tooltip:
                                              context.l10n.tocTemplateExtension,
                                          enabled: !_internal,
                                          fullWidth: true,
                                          options: [
                                            for (final ext in ['md', 'topic'])
                                              BusyMarkPopupSelectorOption(
                                                value: ext,
                                                label: ext,
                                              ),
                                          ],
                                          onSelected: (value) => setState(
                                            () => _update(extension: value),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: TextField(
                                      key: const ValueKey(
                                        'template-editor-source',
                                      ),
                                      controller: _source,
                                      expands: true,
                                      minLines: null,
                                      maxLines: null,
                                      textAlignVertical: TextAlignVertical.top,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: context.l10n.source,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (_) => setState(_update),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                if (_error ?? _validationError case final error?)
                  BusyMarkStatusBox(
                    message: error,
                    kind: BusyMarkStatusKind.error,
                  ),
                if (_snapshot == null && _error == null)
                  const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

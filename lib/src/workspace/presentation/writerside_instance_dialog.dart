import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:yaru/yaru.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../writerside/writerside_instance_service.dart';
import '../../writerside/writerside_model.dart';
import '../../writerside/writerside_project_creator.dart';
import '../workspace_controller.dart';
import '../workspace_message.dart';
import '../workspace_model.dart';

enum BusyMarkWritersideInstanceDialogMode { create, createLibrary, edit }

enum _WritersideInstanceContentSource { empty, markdownFiles }

class BusyMarkWritersideInstanceDialogResult {
  const BusyMarkWritersideInstanceDialogResult({
    required this.mutation,
    required this.iconColor,
  });

  final WritersideInstanceMutationResult mutation;
  final WritersideInstanceIconColor iconColor;
}

class BusyMarkWritersideInstanceDialog extends ConsumerStatefulWidget {
  const BusyMarkWritersideInstanceDialog({
    super.key,
    required this.workspace,
    required this.mode,
    this.instance,
  });

  final Workspace workspace;
  final BusyMarkWritersideInstanceDialogMode mode;
  final WritersideInstance? instance;

  @override
  ConsumerState<BusyMarkWritersideInstanceDialog> createState() =>
      _BusyMarkWritersideInstanceDialogState();
}

class _BusyMarkWritersideInstanceDialogState
    extends ConsumerState<BusyMarkWritersideInstanceDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _versionController;
  late final TextEditingController _webPathController;
  late WritersideInstanceStatus _status;
  late bool _allowIndexing;
  late bool _offlineArtifact;
  late WritersideInstanceIconColor _iconColor;
  var _contentSource = _WritersideInstanceContentSource.empty;
  String? _importRootPath;
  List<WritersideMarkdownImportCandidate> _importCandidates = const [];
  late Set<String> _selectedImportPaths;
  var _copyReferencedMedia = true;
  var _discoveringMarkdown = false;
  var _idEdited = false;
  var _syncingId = false;
  var _saving = false;
  String? _error;
  var _defaultsApplied = false;

  bool get _isEdit => widget.mode == BusyMarkWritersideInstanceDialogMode.edit;

  bool get _isLibrary =>
      widget.mode == BusyMarkWritersideInstanceDialogMode.createLibrary ||
      (_isEdit && widget.instance?.isLibrary == true);

  bool get _isImport =>
      !_isEdit &&
      !_isLibrary &&
      _contentSource == _WritersideInstanceContentSource.markdownFiles;

  @override
  void initState() {
    super.initState();
    final instance = widget.instance;
    _nameController = TextEditingController(text: instance?.name ?? '')
      ..addListener(_handleNameChanged);
    _idController = TextEditingController(text: instance?.id ?? '')
      ..addListener(_handleIdChanged);
    _versionController = TextEditingController(text: instance?.version ?? '')
      ..addListener(_handleFieldChanged);
    _webPathController = TextEditingController(text: instance?.webPath ?? '')
      ..addListener(_handleFieldChanged);
    _status = WritersideInstanceStatusValue.fromXml(
      instance?.status ?? 'release',
    );
    _allowIndexing = instance?.allowSearchEngineIndexing ?? false;
    _offlineArtifact = instance?.offlineArtifact ?? false;
    _iconColor = instance == null
        ? WritersideInstanceIconColor.automatic
        : ref
              .read(appSettingsControllerProvider)
              .writersideInstanceIconColor(
                widget.workspace.rootPath,
                instance.id,
              );
    _selectedImportPaths = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied || _isEdit) {
      return;
    }
    _defaultsApplied = true;
    final name = _isLibrary
        ? context.l10n.defaultTocLibraryName
        : context.l10n.defaultInstanceName;
    _nameController.text = name;
    _idController.text = WritersideProjectCreator.slugInstanceId(name);
    _idEdited = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _versionController.dispose();
    _webPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameError = _nameError();
    final idError = _idError();
    final importError = _importError();
    final canSave =
        !_saving && nameError == null && idError == null && importError == null;
    return PopScope(
      canPop: !_saving,
      child: BusyMarkModalEditorScaffold(
        title: _title,
        cancelLabel: context.l10n.cancel,
        saveLabel: _isEdit ? context.l10n.save : context.l10n.create,
        onCancel: () => Navigator.pop(context),
        cancelEnabled: !_saving,
        onSave: canSave ? _submit : null,
        saving: _saving,
        saveKey: const ValueKey('writerside-instance-save'),
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                key: const ValueKey('writerside-instance-name'),
                label: context.l10n.instanceName,
                controller: _nameController,
                autofocus: !_isEdit,
                textInputAction: TextInputAction.next,
                errorText: nameError,
              ),
              BusyMarkGroupedTextEntry(
                key: const ValueKey('writerside-instance-id'),
                label: context.l10n.instanceId,
                controller: _idController,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                errorText: idError,
              ),
            ],
          ),
          if (!_isEdit && !_isLibrary)
            BusyMarkGroupedList(
              title: context.l10n.instanceContent,
              filled: true,
              children: [
                BusyMarkComboRow<_WritersideInstanceContentSource>(
                  title: context.l10n.instanceContentSource,
                  values: _WritersideInstanceContentSource.values,
                  selected: _contentSource,
                  labelFor: (source) => switch (source) {
                    _WritersideInstanceContentSource.empty =>
                      context.l10n.emptyInstance,
                    _WritersideInstanceContentSource.markdownFiles =>
                      context.l10n.markdownFiles,
                  },
                  onSelected: (source) {
                    setState(() {
                      _contentSource = source;
                      _error = null;
                    });
                    if (source ==
                            _WritersideInstanceContentSource.markdownFiles &&
                        _importRootPath == null) {
                      unawaited(_chooseMarkdownDirectory());
                    }
                  },
                ),
              ],
            ),
          if (_isLibrary) ...[
            const SizedBox(height: BusyMarkSpacing.md),
            BusyMarkStatusBox(
              message: context.l10n.tocLibraryDescription,
              kind: BusyMarkStatusKind.information,
            ),
          ] else ...[
            BusyMarkGroupedList(
              title: context.l10n.instanceOutputSettings,
              filled: true,
              children: [
                BusyMarkGroupedTextEntry(
                  key: const ValueKey('writerside-instance-version'),
                  label: context.l10n.instanceVersion,
                  controller: _versionController,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                ),
                BusyMarkGroupedTextEntry(
                  key: const ValueKey('writerside-instance-web-path'),
                  label: context.l10n.instanceWebPath,
                  controller: _webPathController,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                ),
                BusyMarkComboRow<WritersideInstanceStatus>(
                  title: context.l10n.instanceStatus,
                  values: WritersideInstanceStatus.values,
                  selected: _status,
                  labelFor: (status) => _statusLabel(context, status),
                  onSelected: (status) => setState(() {
                    _status = status;
                    _error = null;
                  }),
                ),
                BusyMarkSwitchRow(
                  title: context.l10n.allowSearchEngineIndexing,
                  subtitle: context.l10n.allowSearchEngineIndexingDescription,
                  value: _allowIndexing,
                  onChanged: (value) => setState(() {
                    _allowIndexing = value;
                    _error = null;
                  }),
                ),
                BusyMarkSwitchRow(
                  title: context.l10n.offlineArtifact,
                  subtitle: context.l10n.offlineArtifactDescription,
                  value: _offlineArtifact,
                  onChanged: (value) => setState(() {
                    _offlineArtifact = value;
                    _error = null;
                  }),
                ),
              ],
            ),
            if (_isEdit &&
                widget.instance?.globalVersion?.isNotEmpty == true) ...[
              const SizedBox(height: BusyMarkSpacing.sm),
              Text(
                context.l10n.instanceVersionInherited(
                  widget.instance!.globalVersion!,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (_isImport) ...[
            BusyMarkGroupedList(
              title: context.l10n.markdownImportSource,
              description: _importRootPath == null
                  ? null
                  : context.l10n.markdownFilesFound(_importCandidates.length),
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: _importRootPath == null
                      ? context.l10n.chooseMarkdownFolder
                      : p.basename(_importRootPath!),
                  subtitle: _importRootPath,
                  leading: _discoveringMarkdown
                      ? const SizedBox.square(
                          dimension: BusyMarkSizes.iconSm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(BusyMarkGlyphs.folderOpen),
                  onTap: _discoveringMarkdown ? null : _chooseMarkdownDirectory,
                ),
                BusyMarkSwitchRow(
                  title: context.l10n.copyReferencedMedia,
                  subtitle: context.l10n.copyReferencedMediaDescription,
                  value: _copyReferencedMedia,
                  onChanged: (value) => setState(() {
                    _copyReferencedMedia = value;
                    _error = null;
                  }),
                ),
              ],
            ),
            if (!_discoveringMarkdown) _importFileSelection(importError),
          ],
          BusyMarkGroupedList(
            title: context.l10n.instanceAppearance,
            filled: true,
            children: [
              BusyMarkComboRow<WritersideInstanceIconColor>(
                title: context.l10n.instanceColor,
                values: WritersideInstanceIconColor.values,
                selected: _iconColor,
                labelFor: (color) =>
                    writersideInstanceColorLabel(context, color),
                leading: Icon(
                  BusyMarkGlyphs.tree,
                  color: writersideInstanceIconColorValue(context, _iconColor),
                ),
                onSelected: (color) => setState(() {
                  _iconColor = color;
                  _error = null;
                }),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: BusyMarkSpacing.md),
            BusyMarkStatusBox(message: _error!, kind: BusyMarkStatusKind.error),
          ],
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  Widget _importFileSelection(String? importError) {
    if (_importRootPath == null) {
      return BusyMarkStatusBox(
        message: context.l10n.chooseMarkdownFolder,
        kind: BusyMarkStatusKind.information,
      );
    }
    if (_importCandidates.isEmpty) {
      return BusyMarkStatusBox(
        message: context.l10n.noMarkdownFilesFound,
        kind: BusyMarkStatusKind.warning,
      );
    }
    return BusyMarkGroupedList(
      title: context.l10n.markdownImportFiles,
      description: importError,
      filled: true,
      children: [
        YaruListTile.square(
          title: Wrap(
            spacing: BusyMarkSpacing.sm,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _selectedImportPaths = {
                    for (final candidate in _importCandidates)
                      candidate.absolutePath,
                  };
                  _error = null;
                }),
                child: Text(context.l10n.selectAll),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _selectedImportPaths.clear();
                  _error = null;
                }),
                child: Text(context.l10n.selectNone),
              ),
            ],
          ),
        ),
        for (final candidate in _importCandidates)
          BusyMarkActionRow(
            title: candidate.title,
            subtitle: candidate.relativePath,
            trailing: BusyMarkCheckbox(
              value: _selectedImportPaths.contains(candidate.absolutePath),
              onChanged: (_) => _toggleImport(candidate.absolutePath),
            ),
            onTap: () => _toggleImport(candidate.absolutePath),
          ),
      ],
    );
  }

  String get _title => switch (widget.mode) {
    BusyMarkWritersideInstanceDialogMode.create => context.l10n.createInstance,
    BusyMarkWritersideInstanceDialogMode.createLibrary =>
      context.l10n.createTocLibrary,
    BusyMarkWritersideInstanceDialogMode.edit => context.l10n.editInstance,
  };

  String? _nameError() {
    return _nameController.text.trim().isEmpty
        ? context.l10n.errorWritersideInstanceNameRequired
        : null;
  }

  String? _idError() {
    final id = _idController.text.trim();
    if (!WritersideProjectCreator.isValidInstanceId(id)) {
      return context.l10n.useLowercaseIdentifier;
    }
    final currentTree = widget.instance?.sourceTreePath;
    final duplicate =
        widget.workspace.writersideModule?.instances.any(
          (instance) =>
              instance.id == id &&
              (currentTree == null ||
                  !p.equals(instance.sourceTreePath, currentTree)),
        ) ??
        false;
    return duplicate ? context.l10n.errorWritersideInstanceIdExists(id) : null;
  }

  String? _importError() {
    if (!_isImport) {
      return null;
    }
    if (_importRootPath == null) {
      return context.l10n.errorWritersideInstanceImportSourceRequired;
    }
    return _selectedImportPaths.isEmpty
        ? context.l10n.errorWritersideInstanceImportSelectionRequired
        : null;
  }

  void _handleNameChanged() {
    _error = null;
    if (!_isEdit && !_idEdited) {
      _syncingId = true;
      _idController.text = WritersideProjectCreator.slugInstanceId(
        _nameController.text,
      );
      _syncingId = false;
    }
    setState(() {});
  }

  void _handleIdChanged() {
    _error = null;
    if (!_syncingId && !_isEdit) {
      _idEdited = true;
    }
    setState(() {});
  }

  void _handleFieldChanged() {
    _error = null;
    setState(() {});
  }

  void _toggleImport(String path) {
    setState(() {
      if (!_selectedImportPaths.remove(path)) {
        _selectedImportPaths.add(path);
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_saving ||
        _nameError() != null ||
        _idError() != null ||
        _importError() != null) {
      return;
    }
    final settings = WritersideInstanceSettings(
      name: _nameController.text.trim(),
      id: _idController.text.trim(),
      version: _versionController.text.trim(),
      webPath: _webPathController.text.trim(),
      status: _status,
      allowSearchEngineIndexing: _allowIndexing,
      offlineArtifact: _offlineArtifact,
    );
    final existing = widget.instance;
    if (existing != null && existing.id != settings.id) {
      final confirmed = await _confirmIdRename(existing.id, settings.id);
      if (!confirmed || !mounted) {
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(workspaceControllerProvider.notifier);
    final WritersideInstanceMutationResult? result;
    if (_isEdit) {
      result = await controller.updateWritersideInstance(
        WritersideInstanceUpdateRequest(
          treePath: widget.instance!.sourceTreePath,
          settings: settings,
        ),
      );
    } else {
      result = await controller.createWritersideInstance(
        WritersideInstanceCreateRequest(
          settings: settings,
          isLibrary: _isLibrary,
          importRootPath: _isImport ? _importRootPath : null,
          importedMarkdownPaths: [
            if (_isImport)
              for (final candidate in _importCandidates)
                if (_selectedImportPaths.contains(candidate.absolutePath))
                  candidate.absolutePath,
          ],
          copyReferencedMedia: _copyReferencedMedia,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    if (result != null) {
      Navigator.pop(
        context,
        BusyMarkWritersideInstanceDialogResult(
          mutation: result,
          iconColor: _iconColor,
        ),
      );
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

  Future<void> _chooseMarkdownDirectory() async {
    final sourcePath = await getDirectoryPath(
      initialDirectory: _importRootPath ?? widget.workspace.rootPath,
      confirmButtonText: context.l10n.open,
      canCreateDirectories: false,
    );
    if (sourcePath == null || !mounted) {
      return;
    }
    setState(() {
      _discoveringMarkdown = true;
      _error = null;
    });
    final candidates = await ref
        .read(workspaceControllerProvider.notifier)
        .discoverWritersideMarkdownImport(sourcePath);
    if (!mounted) {
      return;
    }
    if (candidates == null) {
      final message = ref.read(workspaceControllerProvider).message;
      setState(() {
        _discoveringMarkdown = false;
        _error = message == null
            ? context.l10n.workspaceErrorFileOperationFailed(sourcePath)
            : localizeWorkspaceMessage(context, message);
      });
      return;
    }
    setState(() {
      _discoveringMarkdown = false;
      _importRootPath = sourcePath;
      _importCandidates = candidates;
      _selectedImportPaths = {
        for (final candidate in candidates) candidate.absolutePath,
      };
      _error = null;
    });
  }

  Future<bool> _confirmIdRename(String oldId, String newId) async {
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final result = await showBusyMarkModalDialog<bool>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      barrierDismissible: false,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.instanceIdRenameWarningTitle,
        maxWidth: BusyMarkSizes.dialog,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.renameAndUpdateReferences,
            icon: BusyMarkGlyphs.edit,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text(context.l10n.instanceIdRenameWarning(oldId, newId))],
      ),
    );
    return result ?? false;
  }
}

Color? writersideInstanceIconColorValue(
  BuildContext context,
  WritersideInstanceIconColor color,
) {
  final yaru = YaruColors.of(context);
  return switch (color) {
    WritersideInstanceIconColor.automatic => null,
    WritersideInstanceIconColor.blue => yaru.link,
    WritersideInstanceIconColor.green => yaru.success,
    WritersideInstanceIconColor.orange =>
      BusyMarkLinuxPalette.ubuntuOrangeAccent,
    WritersideInstanceIconColor.purple =>
      BusyMarkLinuxPalette.ubuntuPurpleAccent,
    WritersideInstanceIconColor.red => yaru.error,
    WritersideInstanceIconColor.teal => BusyMarkLinuxPalette.ubuntuTealAccent,
    WritersideInstanceIconColor.yellow =>
      BusyMarkLinuxPalette.ubuntuYellowAccent,
  };
}

String writersideInstanceColorLabel(
  BuildContext context,
  WritersideInstanceIconColor color,
) {
  return switch (color) {
    WritersideInstanceIconColor.automatic =>
      context.l10n.instanceColorAutomatic,
    WritersideInstanceIconColor.blue => context.l10n.instanceColorBlue,
    WritersideInstanceIconColor.green => context.l10n.instanceColorGreen,
    WritersideInstanceIconColor.orange => context.l10n.instanceColorOrange,
    WritersideInstanceIconColor.purple => context.l10n.instanceColorPurple,
    WritersideInstanceIconColor.red => context.l10n.instanceColorRed,
    WritersideInstanceIconColor.teal => context.l10n.instanceColorTeal,
    WritersideInstanceIconColor.yellow => context.l10n.instanceColorYellow,
  };
}

String _statusLabel(BuildContext context, WritersideInstanceStatus status) {
  return switch (status) {
    WritersideInstanceStatus.release => context.l10n.instanceStatusRelease,
    WritersideInstanceStatus.eap => context.l10n.instanceStatusEap,
    WritersideInstanceStatus.deprecated =>
      context.l10n.instanceStatusDeprecated,
  };
}

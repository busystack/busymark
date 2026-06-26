import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../core/path_utils.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../writerside/writerside_project_creator.dart';
import '../workspace_controller.dart';
import '../workspace_safety.dart';

enum _WelcomeMenuAction { settings, keyboardShortcuts, aboutBusyMark }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _markdownTypes = XTypeGroup(
    label: 'Markdown',
    extensions: <String>['md', 'markdown'],
    mimeTypes: <String>['text/markdown', 'text/x-markdown'],
  );
  var _startupPathConsumed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(workspaceControllerProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final colors = BusyMarkSurfaceColors.of(context);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((action) {
        _handleHeaderBarAction(context, action);
      });
    });
    if (headerBar.isAvailable) {
      _configureHeaderBar(headerBar);
    }
    final startupPath = ref.watch(startupPathProvider);
    if (!_startupPathConsumed &&
        startupPath != null &&
        startupPath.isNotEmpty) {
      _startupPathConsumed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_openPath(startupPath));
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.view,
      appBar: useNativeHeaderBar
          ? null
          : AppBar(
              leadingWidth: 0,
              titleSpacing: BusyMarkSpacing.lg,
              title: Text(
                'BusyMark',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: [
                BusyMarkHeaderPopupMenuButton<_WelcomeMenuAction>(
                  tooltip: l10n.mainMenuTooltip,
                  icon: BusyMarkGlyphs.menuVertical,
                  itemBuilder: (context) => [
                    BusyMarkPopupMenuItem(
                      value: _WelcomeMenuAction.settings,
                      label: l10n.settingsMenuItem,
                      icon: BusyMarkGlyphs.settings,
                    ),
                    BusyMarkPopupMenuItem(
                      value: _WelcomeMenuAction.keyboardShortcuts,
                      label: l10n.keyboardShortcutsMenuItem,
                      icon: BusyMarkGlyphs.keyboard,
                    ),
                    BusyMarkPopupMenuItem(
                      value: _WelcomeMenuAction.aboutBusyMark,
                      label: l10n.aboutBusyMarkMenuItem,
                      icon: BusyMarkGlyphs.info,
                    ),
                  ],
                  onSelected: (action) =>
                      _handleWelcomeMenuAction(context, action),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
            ),
      body: BusyMarkClamp(
        maxWidth: 760,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BusyMarkGroupedList(
              title: 'Create',
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: 'Create Markdown File',
                  subtitle: 'Start an unsaved local Markdown document',
                  leading: const Icon(BusyMarkGlyphs.newDocument),
                  trailing: const Icon(BusyMarkGlyphs.rightArrow),
                  onTap: _createMarkdownFile,
                ),
                BusyMarkActionRow(
                  title: 'Create Writerside Project',
                  subtitle: 'Starter project with one Writerside help instance',
                  leading: const Icon(BusyMarkGlyphs.writersideProject),
                  trailing: const Icon(BusyMarkGlyphs.rightArrow),
                  onTap: _createWritersideProject,
                ),
              ],
            ),
            BusyMarkGroupedList(
              title: 'Open',
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: 'Open Markdown File',
                  subtitle: '.md or .markdown',
                  leading: const Icon(BusyMarkGlyphs.markdownFile),
                  trailing: const Icon(BusyMarkGlyphs.rightArrow),
                  onTap: _chooseMarkdownFile,
                ),
                BusyMarkActionRow(
                  title: 'Open Folder or Writerside Project',
                  subtitle: 'Markdown folder or Writerside-compatible project',
                  leading: const Icon(BusyMarkGlyphs.folder),
                  trailing: const Icon(BusyMarkGlyphs.rightArrow),
                  onTap: () => _chooseDirectory('Open'),
                ),
              ],
            ),
            if (state.isLoading) ...[
              const SizedBox(height: BusyMarkSpacing.lg),
              const LinearProgressIndicator(),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: BusyMarkSpacing.lg),
              _WelcomeMessage(message: state.errorMessage!),
            ],
            if (settings.recentWorkspaces.isNotEmpty)
              BusyMarkGroupedList(
                title: 'Recent',
                filled: true,
                children: [
                  for (final recent in settings.recentWorkspaces)
                    BusyMarkActionRow(
                      title: _displayPath(recent.path),
                      subtitle: recent.path,
                      leading: const Icon(BusyMarkGlyphs.history),
                      trailing: const Icon(BusyMarkGlyphs.rightArrow),
                      onTap: () async {
                        await _openPath(recent.path);
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _configureHeaderBar(LinuxHeaderBarService headerBar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await headerBar.setTitleRange('BusyMark');
        await headerBar.setSidebarVisible(false);
        await headerBar.setSidebarToggleVisible(false);
        await headerBar.setBackVisible(false);
        await headerBar.setDocumentControlsVisible(false);
        await headerBar.setCanRefresh(false);
        await headerBar.setCanSave(false);
        await headerBar.setSearchActive(false);
      }());
    });
  }

  void _handleHeaderBarAction(BuildContext context, HeaderBarAction action) {
    switch (action) {
      case HeaderBarAction.settings:
        context.go('/settings');
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case HeaderBarAction.back:
      case HeaderBarAction.sidebarToggle:
      case HeaderBarAction.search:
      case HeaderBarAction.refresh:
      case HeaderBarAction.save:
      case HeaderBarAction.menu:
      case HeaderBarAction.viewModeEditor:
      case HeaderBarAction.viewModeSource:
      case HeaderBarAction.viewModePreview:
      case HeaderBarAction.viewModeSplit:
        break;
    }
  }

  void _handleWelcomeMenuAction(
    BuildContext context,
    _WelcomeMenuAction action,
  ) {
    switch (action) {
      case _WelcomeMenuAction.settings:
        context.go('/settings');
      case _WelcomeMenuAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case _WelcomeMenuAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
    }
  }

  String _displayPath(String path) {
    final name = p.basename(path);
    return name.isEmpty ? path : name;
  }

  Future<void> _chooseMarkdownFile() async {
    final selected = await openFile(
      acceptedTypeGroups: const [_markdownTypes],
      initialDirectory: _initialDirectory(),
      confirmButtonText: 'Open',
    );
    final path = selected?.path;
    if (path == null) {
      return;
    }
    _logSelectedPickerPath(path);
    await _openPath(path);
  }

  Future<void> _chooseDirectory(String confirmButtonText) async {
    final path = await getDirectoryPath(
      initialDirectory: _initialDirectory(),
      confirmButtonText: confirmButtonText,
      canCreateDirectories: false,
    );
    if (path == null) {
      return;
    }
    _logSelectedPickerPath(path);
    await _openPath(path);
  }

  void _logSelectedPickerPath(String rawPath) {
    try {
      final normalizedPath = normalizePath(rawPath);
      final fileType = FileSystemEntity.typeSync(normalizedPath);
      stderr.writeln('[BusyMark] Picker selected path');
      stderr.writeln('[BusyMark]   raw: $rawPath');
      stderr.writeln('[BusyMark]   normalized: $normalizedPath');
      stderr.writeln(
        '[BusyMark]   raw startsWith file://: ${isFileUriPath(rawPath)}',
      );
      stderr.writeln(
        '[BusyMark]   raw startsWith /run/user/: ${rawPath.startsWith('/run/user/')}',
      );
      stderr.writeln(
        '[BusyMark]   normalized startsWith /run/user/: ${normalizedPath.startsWith('/run/user/')}',
      );
      stderr.writeln('[BusyMark]   entity type: ${_fileTypeLabel(fileType)}');
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Picker path logging failed');
      stderr.writeln('[BusyMark]   raw: $rawPath');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
    }
  }

  String _fileTypeLabel(FileSystemEntityType type) {
    if (type == FileSystemEntityType.file) {
      return 'file';
    }
    if (type == FileSystemEntityType.directory) {
      return 'directory';
    }
    if (type == FileSystemEntityType.link) {
      return 'link';
    }
    if (type == FileSystemEntityType.notFound) {
      return 'notFound';
    }
    return type.toString();
  }

  Future<void> _createMarkdownFile() async {
    final safe = await confirmSafeToContinue(context, ref);
    if (!safe) {
      return;
    }
    await ref.read(workspaceControllerProvider.notifier).createMarkdownFile();
    if (mounted) {
      context.go('/workspace');
    }
  }

  Future<void> _createWritersideProject() async {
    final safe = await confirmSafeToContinue(context, ref);
    if (!safe || !mounted) {
      return;
    }
    final parentPath = await getDirectoryPath(
      initialDirectory: _initialDirectory(),
      confirmButtonText: 'Choose Location',
      canCreateDirectories: true,
    );
    if (parentPath == null || !mounted) {
      return;
    }
    _logSelectedPickerPath(parentPath);

    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final created = await showBusyMarkModalDialog<bool>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => _CreateWritersideProjectDialog(
        parentDirectoryPath: parentPath,
        onCreate: (request) => ref
            .read(workspaceControllerProvider.notifier)
            .createWritersideProject(request),
        errorMessage: () => ref.read(workspaceControllerProvider).errorMessage,
      ),
    );
    if (!mounted) {
      return;
    }
    if (created == true) {
      context.go('/workspace');
    }
  }

  String? _initialDirectory() {
    final settings = ref.read(appSettingsControllerProvider);
    final lastPath = settings.lastOpenedPath;
    if (lastPath == null || lastPath.isEmpty) {
      return null;
    }
    final extension = p.extension(lastPath);
    return extension.isEmpty ? lastPath : p.dirname(lastPath);
  }

  Future<void> _openPath(String path) async {
    if (path.isEmpty) {
      return;
    }
    final safe = await confirmSafeToContinue(context, ref);
    if (!safe) {
      return;
    }
    await ref.read(workspaceControllerProvider.notifier).openPath(path);
    if (!mounted) {
      return;
    }
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace != null) {
      context.go('/workspace');
    }
  }
}

class _CreateWritersideProjectDialog extends StatefulWidget {
  const _CreateWritersideProjectDialog({
    required this.parentDirectoryPath,
    required this.onCreate,
    required this.errorMessage,
  });

  final String parentDirectoryPath;
  final Future<bool> Function(WritersideProjectCreateRequest request) onCreate;
  final String? Function() errorMessage;

  @override
  State<_CreateWritersideProjectDialog> createState() =>
      _CreateWritersideProjectDialogState();
}

class _CreateWritersideProjectDialogState
    extends State<_CreateWritersideProjectDialog> {
  late final TextEditingController _projectNameController;
  late final TextEditingController _directoryNameController;
  late final TextEditingController _instanceNameController;
  late final TextEditingController _instanceIdController;
  late final TextEditingController _topicTitleController;
  var _directoryEdited = false;
  var _syncingDirectory = false;
  var _creating = false;
  String? _creationError;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController()
      ..addListener(_handleProjectNameChanged);
    _directoryNameController = TextEditingController(
      text: _slugDirectoryName(''),
    )..addListener(_handleDirectoryNameChanged);
    _instanceNameController = TextEditingController(text: 'User Guide')
      ..addListener(_handleFieldChanged);
    _instanceIdController = TextEditingController(text: 'user-guide')
      ..addListener(_handleFieldChanged);
    _topicTitleController = TextEditingController(text: 'Getting started')
      ..addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _directoryNameController.dispose();
    _instanceNameController.dispose();
    _instanceIdController.dispose();
    _topicTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final projectError = _projectNameError;
    final directoryError = _directoryNameError;
    final instanceIdError = _instanceIdError;
    final topicTitleError = _topicTitleError;
    final canCreate =
        !_creating &&
        projectError == null &&
        directoryError == null &&
        instanceIdError == null &&
        topicTitleError == null;
    return BusyMarkDialogShell(
      title: 'Create Writerside Project',
      maxWidth: 560,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canCreate ? _submit : null,
          child: Text(_creating ? 'Creating...' : 'Create'),
        ),
      ],
      children: [
        TextField(
          controller: _projectNameController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Project name',
            errorText: projectError,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        TextField(
          controller: _directoryNameController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canCreate) {
              _submit();
            }
          },
          decoration: InputDecoration(
            labelText: 'Directory name',
            errorText: directoryError,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        TextField(
          controller: _instanceNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Instance name'),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        TextField(
          controller: _instanceIdController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Instance ID',
            errorText: instanceIdError,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        TextField(
          controller: _topicTitleController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canCreate) {
              _submit();
            }
          },
          decoration: InputDecoration(
            labelText: 'Start topic title',
            errorText: topicTitleError,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
        if (_creationError != null) ...[
          _WelcomeMessage(message: _creationError!),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
        Text(
          'Location',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: BusyMarkSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.control,
            borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            border: Border.all(color: colors.subtleBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: SelectableText(
              _targetPath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  String? get _projectNameError {
    if (_projectNameController.text.trim().isEmpty) {
      return 'Project name is required.';
    }
    return null;
  }

  String? get _directoryNameError {
    final value = _directoryNameController.text.trim();
    if (value.isEmpty) {
      return 'Directory name is required.';
    }
    if (value == '.' ||
        value == '..' ||
        p.isAbsolute(value) ||
        value.contains('..') ||
        value.contains('/') ||
        value.contains(r'\')) {
      return 'Use a single safe directory name.';
    }
    return null;
  }

  String? get _instanceIdError {
    final value = _instanceIdController.text.trim();
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(value)) {
      return 'Use lowercase letters, numbers, underscores, or hyphens.';
    }
    return null;
  }

  String? get _topicTitleError {
    if (_topicTitleController.text.trim().isEmpty) {
      return 'Start topic title is required.';
    }
    return null;
  }

  String get _targetPath {
    final directoryName = _directoryNameController.text.trim();
    final safeDirectoryName = directoryName.isEmpty
        ? _slugDirectoryName(_projectNameController.text)
        : directoryName;
    return p.join(normalizePath(widget.parentDirectoryPath), safeDirectoryName);
  }

  void _handleProjectNameChanged() {
    _creationError = null;
    if (!_directoryEdited) {
      _syncingDirectory = true;
      _directoryNameController.text = _slugDirectoryName(
        _projectNameController.text,
      );
      _syncingDirectory = false;
    }
    setState(() {});
  }

  void _handleDirectoryNameChanged() {
    _creationError = null;
    if (!_syncingDirectory) {
      _directoryEdited = true;
    }
    setState(() {});
  }

  void _handleFieldChanged() {
    _creationError = null;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_creating ||
        _projectNameError != null ||
        _directoryNameError != null ||
        _instanceIdError != null ||
        _topicTitleError != null) {
      return;
    }
    setState(() {
      _creating = true;
      _creationError = null;
    });
    final created = await widget.onCreate(
      WritersideProjectCreateRequest(
        parentDirectoryPath: normalizePath(widget.parentDirectoryPath),
        projectName: _projectNameController.text.trim(),
        directoryName: _directoryNameController.text.trim(),
        instanceName: _instanceNameController.text.trim().isEmpty
            ? 'User Guide'
            : _instanceNameController.text.trim(),
        instanceId: _instanceIdController.text.trim(),
        topicTitle: _topicTitleController.text.trim(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (created) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _creating = false;
      _creationError =
          widget.errorMessage() ?? 'Create Writerside project failed.';
    });
  }

  String _slugDirectoryName(String value) {
    final slug = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'writerside-project' : slug;
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(BusyMarkGlyphs.warning),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

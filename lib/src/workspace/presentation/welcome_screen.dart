import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:yaru/yaru.dart';

import '../../app/app_settings.dart';
import '../../app/app_router.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_main_menu.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../app/window_control_service.dart';
import '../../core/debug_log.dart';
import '../../core/path_utils.dart';
import '../../feedback/presentation/feedback_dialog.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../writerside/writerside_project_creator.dart';
import '../workspace_controller.dart';
import '../workspace_glyphs.dart';
import '../workspace_message.dart';
import '../workspace_safety.dart';
import 'workspace_identity_row.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  XTypeGroup _markdownTypes(BuildContext context) => XTypeGroup(
    label: context.l10n.fileTypeMarkdown,
    extensions: <String>['md', 'markdown'],
    mimeTypes: <String>['text/markdown', 'text/x-markdown'],
  );
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final colors = BusyMarkSurfaceColors.of(context);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    final sidebarVisible = settings.sidebarVisible;
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        _handleHeaderBarAction(context, event.action);
      });
    });
    final startupPath = ref.watch(startupPathProvider);
    final startupNavigation = ref.read(startupNavigationGuardProvider);
    if (startupNavigation.claimStartupPath(startupPath)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_openPath(startupPath!));
        }
      });
    } else if (startupNavigation.claimSessionRestore(startupPath)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        final restored = await ref
            .read(workspaceControllerProvider.notifier)
            .restorePreviousSession();
        if (restored && mounted) {
          this.context.go('/workspace');
        }
      });
    }

    final welcomeMainColor = colors.view;
    final welcomeSidebar = SizedBox(
      width: BusyMarkSizes.sidebarWidth,
      child: _WelcomeSidebar(
        recentWorkspaces: settings.recentWorkspaces,
        onOpenRecent: _openPath,
      ),
    );
    final welcomeContent = Expanded(
      child: ColoredBox(
        color: welcomeMainColor,
        child: BusyMarkClamp(
          maxWidth: BusyMarkSizes.contentWidth,
          margin: EdgeInsets.zero,
          padding: BusyMarkInsets.welcomePage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BusyMarkGroupedList(
                title: context.l10n.create,
                filled: true,
                children: [
                  BusyMarkActionRow(
                    title: context.l10n.createMarkdownFile,
                    subtitle: context.l10n.createMarkdownFileDescription,
                    leading: const Icon(BusyMarkGlyphs.newDocument),
                    trailing: Icon(
                      BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                    ),
                    onTap: _createMarkdownFile,
                  ),
                  BusyMarkActionRow(
                    title: context.l10n.createWritersideProject,
                    subtitle: context.l10n.createWritersideProjectDescription,
                    leading: const Icon(BusyMarkGlyphs.writersideProject),
                    trailing: Icon(
                      BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                    ),
                    onTap: _createWritersideProject,
                  ),
                ],
              ),
              BusyMarkGroupedList(
                title: context.l10n.open,
                filled: true,
                children: [
                  BusyMarkActionRow(
                    title: context.l10n.openMarkdownFile,
                    subtitle: context.l10n.markdownFileExtensions,
                    leading: const Icon(BusyMarkGlyphs.markdownFile),
                    trailing: Icon(
                      BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                    ),
                    onTap: _chooseMarkdownFile,
                  ),
                  BusyMarkActionRow(
                    title: context.l10n.openFolderOrWritersideProject,
                    subtitle: context.l10n.markdownFolderOrWritersideProject,
                    leading: const Icon(BusyMarkGlyphs.folder),
                    trailing: Icon(
                      BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                    ),
                    onTap: () => _chooseDirectory(context.l10n.open),
                  ),
                ],
              ),
              if (state.isLoading) ...[
                const SizedBox(height: BusyMarkSpacing.lg),
                const LinearProgressIndicator(),
              ],
              if (state.message != null) ...[
                const SizedBox(height: BusyMarkSpacing.lg),
                BusyMarkStatusBox(
                  message: localizeWorkspaceMessage(context, state.message!),
                  kind: busyMarkWorkspaceMessageStatusKind(state.message!.code),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final sidebarOnRight = Directionality.of(context) == TextDirection.rtl;
    final bodyChildren = [
      if (!sidebarOnRight && sidebarVisible) welcomeSidebar,
      welcomeContent,
      if (sidebarOnRight && sidebarVisible) welcomeSidebar,
    ];
    final headerConfiguration = HeaderBarConfigurationDefaults.of(context)
        .copyWith(
          title: context.l10n.appTitle,
          viewMode: AppViewMode.editor,
          searchQuery: '',
          canRefresh: false,
          documentControlsVisible: false,
          searchActive: false,
          searchVisible: false,
          sidebarVisible: sidebarVisible,
          sidebarToggleVisible: true,
          backVisible: false,
        );

    return HeaderBarConfigurationPublisher(
      synchronizer: headerBar.configurationSynchronizer,
      configuration: headerConfiguration,
      enabled: headerBar.isAvailable,
      child: Scaffold(
        backgroundColor: welcomeMainColor,
        appBar: useNativeHeaderBar
            ? null
            : AppBar(
                title: Text(
                  context.l10n.appTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                actions: [
                  BusyMarkHeaderIconButton(
                    tooltip: sidebarVisible
                        ? context.l10n.hideSidebar
                        : context.l10n.showSidebar,
                    icon: BusyMarkGlyphs.sidebar,
                    selected: sidebarVisible,
                    shortcut: BusyMarkSidebarShortcutLabels.toggleSidebar,
                    onPressed: _toggleSidebar,
                  ),
                  BusyMarkMainMenuButton(
                    onSelected: (action) =>
                        _handleMainMenuAction(context, headerBar, action),
                  ),
                  const SizedBox(width: BusyMarkSpacing.sm),
                ],
              ),
        body: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: bodyChildren,
        ),
      ),
    );
  }

  void _handleHeaderBarAction(BuildContext context, HeaderBarAction action) {
    switch (action) {
      case HeaderBarAction.settings:
        context.go(settingsLocation(SettingsReturnTarget.welcome));
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case HeaderBarAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
      case HeaderBarAction.reportIssue:
        showBusyMarkFeedbackDialog(
          context,
          headerBarService: ref.read(linuxHeaderBarServiceProvider),
        );
      case HeaderBarAction.sidebarToggle:
        _toggleSidebar();
      case HeaderBarAction.back:
      case HeaderBarAction.search:
      case HeaderBarAction.refresh:
      case HeaderBarAction.save:
      case HeaderBarAction.exportPdf:
      case HeaderBarAction.fullScreen:
      case HeaderBarAction.menu:
      case HeaderBarAction.viewModeEditor:
      case HeaderBarAction.viewModeSource:
      case HeaderBarAction.viewModePreview:
      case HeaderBarAction.viewModeSplit:
      case HeaderBarAction.sidebarFiles:
      case HeaderBarAction.sidebarToc:
      case HeaderBarAction.sidebarOutline:
      case HeaderBarAction.sidebarGit:
        break;
    }
  }

  void _toggleSidebar() {
    final settings = ref.read(appSettingsControllerProvider);
    unawaited(
      ref
          .read(appSettingsControllerProvider.notifier)
          .setSidebarVisible(!settings.sidebarVisible),
    );
  }

  void _handleMainMenuAction(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    BusyMarkMainMenuAction action,
  ) {
    switch (action) {
      case BusyMarkMainMenuAction.exportPdf:
      case BusyMarkMainMenuAction.generateMarkdownToc:
        break;
      case BusyMarkMainMenuAction.fullScreen:
        unawaited(ref.read(windowControlServiceProvider).toggleFullScreen());
      case BusyMarkMainMenuAction.settings:
        context.go(settingsLocation(SettingsReturnTarget.welcome));
      case BusyMarkMainMenuAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case BusyMarkMainMenuAction.commandPalette:
        return;
      case BusyMarkMainMenuAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
      case BusyMarkMainMenuAction.reportIssue:
        showBusyMarkFeedbackDialog(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
        );
      case BusyMarkMainMenuAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
    }
  }

  Future<void> _chooseMarkdownFile() async {
    final selected = await openFile(
      acceptedTypeGroups: [_markdownTypes(context)],
      initialDirectory: _initialDirectory(),
      confirmButtonText: context.l10n.open,
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
      busyMarkDebugLogLines([
        '[BusyMark] Picker selected path',
        '[BusyMark]   raw: ${busyMarkLogPath(rawPath)}',
        '[BusyMark]   normalized: ${busyMarkLogPath(normalizedPath)}',
        '[BusyMark]   raw startsWith file://: ${isFileUriPath(rawPath)}',
        '[BusyMark]   raw startsWith /run/user/: ${rawPath.startsWith('/run/user/')}',
        '[BusyMark]   normalized startsWith /run/user/: ${normalizedPath.startsWith('/run/user/')}',
        '[BusyMark]   entity type: ${_fileTypeLabel(fileType)}',
      ]);
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Picker path logging failed',
        error,
        stackTrace,
        context: {'raw': busyMarkLogPath(rawPath)},
      );
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
      confirmButtonText: context.l10n.chooseLocation,
      canCreateDirectories: true,
    );
    if (parentPath == null || !mounted) {
      return;
    }
    _logSelectedPickerPath(parentPath);

    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final created = await showBusyMarkModalEditorDialog<bool>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      maxWidth: BusyMarkSizes.dialogWide,
      builder: (context) => BusyMarkCreateWritersideProjectDialog(
        parentDirectoryPath: parentPath,
        onCreate: (request) => ref
            .read(workspaceControllerProvider.notifier)
            .createWritersideProject(request),
        message: () => ref.read(workspaceControllerProvider).message,
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

class _WelcomeSidebar extends StatelessWidget {
  const _WelcomeSidebar({
    required this.recentWorkspaces,
    required this.onOpenRecent,
  });

  final List<RecentWorkspace> recentWorkspaces;
  final Future<void> Function(String path) onOpenRecent;

  @override
  Widget build(BuildContext context) {
    return BusyMarkSidebarSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: BusyMarkInsets.sidebarList,
              children: [
                if (recentWorkspaces.isNotEmpty)
                  _WelcomeSidebarSection(
                    title: context.l10n.recent,
                    children: <Widget>[
                      for (final recent in recentWorkspaces)
                        _WelcomeRecentRow(
                          recent: recent,
                          onTap: () => unawaited(onOpenRecent(recent.path)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSidebarSection extends StatelessWidget {
  const _WelcomeSidebarSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BusyMarkSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
            child: Text(title, style: busyMarkSectionHeaderStyle(context)),
          ),
          const SizedBox(height: BusyMarkSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _WelcomeRecentRow extends StatelessWidget {
  const _WelcomeRecentRow({required this.recent, required this.onTap});

  final RecentWorkspace recent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        color: BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: busyMarkRowHoverColor(context),
          onTap: onTap,
          child: WorkspaceIdentityRow(
            height: BusyMarkSizes.sidebarTreeRowHeight * 2,
            icon: WorkspaceGlyphs.forRecent(recent),
            name: busyMarkLtrIsolateFor(context, _displayPath(recent.path)),
            path: busyMarkLtrIsolateFor(context, recent.path),
          ),
        ),
      ),
    );
  }
}

String _displayPath(String path) {
  final name = p.basename(path);
  return name.isEmpty ? path : name;
}

class BusyMarkCreateWritersideProjectDialog extends StatefulWidget {
  const BusyMarkCreateWritersideProjectDialog({
    super.key,
    required this.parentDirectoryPath,
    required this.onCreate,
    required this.message,
  });

  final String parentDirectoryPath;
  final Future<bool> Function(WritersideProjectCreateRequest request) onCreate;
  final WorkspaceMessage? Function() message;

  @override
  State<BusyMarkCreateWritersideProjectDialog> createState() =>
      _BusyMarkCreateWritersideProjectDialogState();
}

class _BusyMarkCreateWritersideProjectDialogState
    extends State<BusyMarkCreateWritersideProjectDialog> {
  static final _directorySlugCharacterPattern = RegExp(
    r'[\p{L}\p{M}\p{N}_-]',
    unicode: true,
  );

  late final TextEditingController _projectNameController;
  late final TextEditingController _directoryNameController;
  late final TextEditingController _instanceNameController;
  late final TextEditingController _instanceIdController;
  late final TextEditingController _topicTitleController;
  late String _lastGeneratedDirectoryName;
  late String _lastGeneratedInstanceId;
  var _directoryEdited = false;
  var _syncingDirectory = false;
  var _instanceIdEdited = false;
  var _syncingInstanceId = false;
  var _creating = false;
  String? _creationError;
  var _localizedDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController()
      ..addListener(_handleProjectNameChanged);
    _lastGeneratedDirectoryName = _slugDirectoryName('');
    _directoryNameController = TextEditingController(
      text: _lastGeneratedDirectoryName,
    )..addListener(_handleDirectoryNameChanged);
    _instanceNameController = TextEditingController()
      ..addListener(_handleInstanceNameChanged);
    _lastGeneratedInstanceId = 'user-guide';
    _instanceIdController = TextEditingController(
      text: _lastGeneratedInstanceId,
    )..addListener(_handleInstanceIdChanged);
    _topicTitleController = TextEditingController()
      ..addListener(_handleFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) {
      return;
    }
    _localizedDefaultsApplied = true;
    _instanceNameController.text = context.l10n.defaultInstanceName;
    _topicTitleController.text = context.l10n.defaultStartTopicTitle;
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
    final projectError = _projectNameError(context);
    final directoryError = _directoryNameError(context);
    final instanceIdError = _instanceIdError(context);
    final topicTitleError = _topicTitleError(context);
    final canCreate =
        !_creating &&
        projectError == null &&
        directoryError == null &&
        instanceIdError == null &&
        topicTitleError == null;
    return PopScope(
      canPop: !_creating,
      child: BusyMarkModalEditorScaffold(
        title: context.l10n.createWritersideProject,
        cancelLabel: context.l10n.cancel,
        saveLabel: context.l10n.create,
        onCancel: () => Navigator.pop(context),
        cancelEnabled: !_creating,
        onSave: canCreate ? _submit : null,
        saving: _creating,
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                label: context.l10n.projectName,
                controller: _projectNameController,
                textInputAction: TextInputAction.next,
                errorText: projectError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.directoryName,
                controller: _directoryNameController,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                errorText: directoryError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.instanceName,
                controller: _instanceNameController,
                textInputAction: TextInputAction.next,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.instanceId,
                controller: _instanceIdController,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                errorText: instanceIdError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.startTopicTitle,
                controller: _topicTitleController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (canCreate) {
                    _submit();
                  }
                },
                errorText: topicTitleError,
              ),
            ],
          ),
          if (_creationError != null) ...[
            const SizedBox(height: BusyMarkSpacing.md),
            BusyMarkStatusBox(
              message: _creationError!,
              kind: BusyMarkStatusKind.error,
            ),
          ],
          BusyMarkGroupedList(
            title: context.l10n.location,
            filled: true,
            children: [
              YaruListTile.square(
                title: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    _targetPath,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.foreground),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  String? _projectNameError(BuildContext context) {
    if (_projectNameController.text.trim().isEmpty) {
      return context.l10n.projectNameRequired;
    }
    return null;
  }

  String? _directoryNameError(BuildContext context) {
    final value = _directoryNameController.text.trim();
    if (value.isEmpty) {
      return context.l10n.directoryNameRequired;
    }
    if (value == '.' ||
        value == '..' ||
        p.isAbsolute(value) ||
        value.contains('..') ||
        value.contains('/') ||
        value.contains(r'\')) {
      return context.l10n.useSingleSafeDirectoryName;
    }
    return null;
  }

  String? _instanceIdError(BuildContext context) {
    final value = _instanceIdController.text.trim();
    if (!WritersideProjectCreator.isValidInstanceId(value)) {
      return context.l10n.useLowercaseIdentifier;
    }
    return null;
  }

  String? _topicTitleError(BuildContext context) {
    if (_topicTitleController.text.trim().isEmpty) {
      return context.l10n.startTopicTitleRequired;
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
    final nextDirectoryName = _slugDirectoryName(_projectNameController.text);
    if (!_directoryEdited ||
        _directoryNameController.text == _lastGeneratedDirectoryName) {
      _syncingDirectory = true;
      _lastGeneratedDirectoryName = nextDirectoryName;
      _directoryNameController.text = nextDirectoryName;
      _syncingDirectory = false;
      _directoryEdited = false;
    }
    setState(() {});
  }

  void _handleDirectoryNameChanged() {
    _creationError = null;
    if (!_syncingDirectory) {
      _directoryEdited =
          _directoryNameController.text != _lastGeneratedDirectoryName;
    }
    setState(() {});
  }

  void _handleInstanceNameChanged() {
    _creationError = null;
    final nextInstanceId = _slugInstanceId(_instanceNameController.text);
    if (!_instanceIdEdited ||
        _instanceIdController.text == _lastGeneratedInstanceId) {
      _syncingInstanceId = true;
      _lastGeneratedInstanceId = nextInstanceId;
      _instanceIdController.text = nextInstanceId;
      _syncingInstanceId = false;
      _instanceIdEdited = false;
    }
    setState(() {});
  }

  void _handleInstanceIdChanged() {
    _creationError = null;
    if (!_syncingInstanceId) {
      _instanceIdEdited =
          _instanceIdController.text != _lastGeneratedInstanceId;
    }
    setState(() {});
  }

  void _handleFieldChanged() {
    _creationError = null;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_creating ||
        _projectNameError(context) != null ||
        _directoryNameError(context) != null ||
        _instanceIdError(context) != null ||
        _topicTitleError(context) != null) {
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
            ? context.l10n.defaultInstanceName
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
      final message = widget.message();
      _creationError = message == null
          ? context.l10n.createWritersideProjectFailed
          : localizeWorkspaceMessage(context, message);
    });
  }

  String _slugDirectoryName(String value) {
    final buffer = StringBuffer();
    var pendingSeparator = false;
    for (final rune in value.toLowerCase().trim().runes) {
      final character = String.fromCharCode(rune);
      if (_directorySlugCharacterPattern.hasMatch(character)) {
        if (pendingSeparator && buffer.isNotEmpty) {
          buffer.write('-');
        }
        buffer.write(character);
        pendingSeparator = false;
      } else {
        pendingSeparator = true;
      }
    }
    final slug = buffer.toString().replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    return slug.isEmpty ? 'writerside-project' : slug;
  }

  String _slugInstanceId(String value) {
    return WritersideProjectCreator.slugInstanceId(value);
  }
}

BusyMarkStatusKind busyMarkWorkspaceMessageStatusKind(
  WorkspaceMessageCode code,
) {
  return switch (code) {
    WorkspaceMessageCode.chooseWhereToSaveMarkdown =>
      BusyMarkStatusKind.information,
    WorkspaceMessageCode.recoveryRestored => BusyMarkStatusKind.information,
    WorkspaceMessageCode.saveBlockedFileChangedOnDisk ||
    WorkspaceMessageCode.recoveryDamaged => BusyMarkStatusKind.warning,
    WorkspaceMessageCode.openFailed ||
    WorkspaceMessageCode.createWritersideProjectFailed ||
    WorkspaceMessageCode.createWritersideTopicFailed ||
    WorkspaceMessageCode.couldNotOpenFile ||
    WorkspaceMessageCode.saveFailed ||
    WorkspaceMessageCode.fileOperationFailed ||
    WorkspaceMessageCode.validationFailed => BusyMarkStatusKind.error,
  };
}

// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor for Markdown files and Writerside-compatible documentation projects.';

  @override
  String get aboutBusyMark => 'About BusyMark';

  @override
  String get aboutTagline => 'Markdown and Writerside Editor';

  @override
  String get aboutLicenseLabel => 'License';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutSourceCode => 'Source code';

  @override
  String get reportIssue => 'Report an issue';

  @override
  String get feedbackCategory => 'Category';

  @override
  String get feedbackChooseCategory => 'Choose a category';

  @override
  String get feedbackCategoryProblem => 'Problem or bug';

  @override
  String get feedbackCategoryFeature => 'Feature request';

  @override
  String get feedbackCategoryPrivacySecurity => 'Privacy or security concern';

  @override
  String get feedbackCategoryUsability => 'Usability concern';

  @override
  String get feedbackCategoryOther => 'Other';

  @override
  String get feedbackSubject => 'Subject';

  @override
  String get feedbackMessage => 'Detailed message';

  @override
  String get feedbackReplyEmail => 'Email address for replies (optional)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Include technical details';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'When enabled, this adds only your Linux operating-system version and BusyMark application locale. No logs, files, account data, or other diagnostics are attached.';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackSubmitting => 'Submitting…';

  @override
  String get feedbackCategoryRequired => 'Choose a category.';

  @override
  String get feedbackSubjectLength =>
      'Subject must be between 3 and 120 characters.';

  @override
  String get feedbackMessageLength =>
      'Message must be between 10 and 5,000 characters.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Enter a valid email address or leave this field empty.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark could not connect. Check your internet connection and try again.';

  @override
  String get feedbackTimeoutFailure => 'The request timed out. Try again.';

  @override
  String get feedbackRateLimitedFailure =>
      'Too many reports were sent from this connection. Wait and try again.';

  @override
  String get feedbackRejectedFailure =>
      'The server rejected this report. Check the form fields and try again.';

  @override
  String get feedbackServerFailure =>
      'The server could not accept the report. Try again later.';

  @override
  String feedbackSuccess(String id) {
    return 'Feedback sent. Reference ID: $id';
  }

  @override
  String get advanced => 'Advanced';

  @override
  String get addToGit => 'Add to Git';

  @override
  String get appearance => 'Appearance';

  @override
  String get apply => 'Apply';

  @override
  String get back => 'Back';

  @override
  String get bottomLeft => 'Bottom left';

  @override
  String get bottomRight => 'Bottom right';

  @override
  String get cancel => 'Cancel';

  @override
  String get choose => 'Choose';

  @override
  String get chooseLocation => 'Choose location';

  @override
  String get copy => 'Copy';

  @override
  String get copyName => 'Copy name';

  @override
  String get copyFileName => 'Copy file name';

  @override
  String get copyPath => 'Copy path';

  @override
  String get create => 'Create';

  @override
  String get creating => 'Creating...';

  @override
  String get cut => 'Cut';

  @override
  String get promoteSection => 'Promote section';

  @override
  String get demoteSection => 'Demote section';

  @override
  String get moveSectionUp => 'Move section up';

  @override
  String get moveSectionDown => 'Move section down';

  @override
  String get confirmDeleteSectionTitle => 'Delete section?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Delete “$name” and all content in its section? This cannot be undone.';
  }

  @override
  String get darkTheme => 'Dark';

  @override
  String get delete => 'Delete';

  @override
  String get discard => 'Discard';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'File';

  @override
  String get fileHistory => 'File History';

  @override
  String get folder => 'Folder';

  @override
  String get insert => 'Insert';

  @override
  String get keyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get commandPalette => 'Command Palette';

  @override
  String get commandPaletteHint => 'Type a command';

  @override
  String get commandPaletteEmpty => 'No matching commands';

  @override
  String get commandUnavailableInContext =>
      'Unavailable in the current editor context';

  @override
  String get lightTheme => 'Light';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Open';

  @override
  String get openInFiles => 'Open in Files';

  @override
  String get pathActions => 'Path actions';

  @override
  String get outline => 'Outline';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get paste => 'Paste';

  @override
  String get pasteWithoutFormatting => 'Paste without formatting';

  @override
  String get reading => 'Reading';

  @override
  String get removeFromRecent => 'Remove from Recent';

  @override
  String get recent => 'Recent';

  @override
  String get redo => 'Redo';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get selectAll => 'Select all';

  @override
  String get settings => 'Settings';

  @override
  String get source => 'Source';

  @override
  String get split => 'Split';

  @override
  String get systemTheme => 'System';

  @override
  String get theme => 'Theme';

  @override
  String get appLanguage => 'Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageNorwegian => 'Norsk bokmål';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEstonian => 'Eesti';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get toggleSidebar => 'Sidebar panel';

  @override
  String get topLeft => 'Top left';

  @override
  String get topRight => 'Top right';

  @override
  String get undo => 'Undo';

  @override
  String get validate => 'Validate';

  @override
  String get validation => 'Validation';

  @override
  String get viewMode => 'View mode';

  @override
  String get welcome => 'Welcome';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Images';

  @override
  String get openMarkdownFile => 'Open Markdown File';

  @override
  String get markdownFileExtensions => '.md or .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Open Folder or Writerside Project';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown folder or Writerside-compatible project';

  @override
  String get noOpenFile => 'No open file';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Delete the selected Files item, or remove the selected topic from the table of contents';

  @override
  String get shortcutGroupGeneral => 'General';

  @override
  String get shortcutNewDocument => 'Create';

  @override
  String get shortcutNewDocumentDescription =>
      'Create a Markdown file or Writerside project';

  @override
  String get shortcutOpenDescription =>
      'Open a Markdown file, folder, or Writerside project';

  @override
  String get shortcutSaveDescription => 'Save the current document';

  @override
  String get shortcutSearchDescription => 'Search the current workspace';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Show this keyboard shortcut reference';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Abrir a referência de sintaxe';

  @override
  String get shortcutSettingsDescription => 'Open BusyMark settings';

  @override
  String get shortcutNextTab => 'Next tab';

  @override
  String get shortcutNextTabDescription => 'Move to the next open tab';

  @override
  String get shortcutPreviousTab => 'Previous tab';

  @override
  String get shortcutPreviousTabDescription => 'Move to the previous open tab';

  @override
  String get shortcutCloseTab => 'Close tab';

  @override
  String get shortcutCloseTabDescription => 'Close the active tab';

  @override
  String get shortcutCloseAllTabs => 'Close all tabs';

  @override
  String get shortcutCloseAllTabsDescription => 'Close all open tabs';

  @override
  String get shortcutGroupTextEditing => 'Text Editing';

  @override
  String get shortcutSelectAllDescription =>
      'In Source mode, select all text; in Editor mode, press twice to select every block';

  @override
  String get shortcutCutDescription => 'Cut the selected text';

  @override
  String get shortcutCopyDescription => 'Copy the selected text';

  @override
  String get shortcutPasteDescription => 'Paste from the clipboard';

  @override
  String get shortcutPastePlainTextDescription =>
      'Paste clipboard text without formatting';

  @override
  String get shortcutUndoDescription => 'Undo the last edit';

  @override
  String get shortcutRedoDescription => 'Redo the last undone edit';

  @override
  String get shortcutInsertIndentation => 'Insert indentation';

  @override
  String get shortcutInsertIndentationDescription =>
      'Insert indentation at the cursor';

  @override
  String get shortcutOutdentSource => 'Outdent source';

  @override
  String get shortcutOutdentSourceDescription =>
      'Remove one indentation level in Source mode';

  @override
  String get shortcutEscape => 'Close search or clear block selection';

  @override
  String get shortcutEscapeDescription =>
      'Close workspace search or clear a block selection in Editor mode';

  @override
  String get shortcutGroupFormatting => 'Formatting';

  @override
  String get shortcutBoldDescription => 'Toggle bold on the selected text';

  @override
  String get shortcutItalicDescription => 'Toggle italic on the selected text';

  @override
  String get shortcutUnderlineDescription =>
      'Toggle underline on the selected text';

  @override
  String get shortcutLinkDescription => 'Insert or edit a link';

  @override
  String get shortcutInlineCodeDescription =>
      'Toggle inline code on the selected text';

  @override
  String get shortcutStrikethroughDescription =>
      'Toggle strikethrough on the selected text';

  @override
  String get shortcutGroupBlocks => 'Blocks';

  @override
  String get shortcutParagraphDescription =>
      'Set the current block to paragraph';

  @override
  String get shortcutHeading1Description =>
      'Set the current block to Heading 1';

  @override
  String get shortcutHeading2Description =>
      'Set the current block to Heading 2';

  @override
  String get shortcutHeading3Description =>
      'Set the current block to Heading 3';

  @override
  String get shortcutHeading4Description =>
      'Set the current block to Heading 4';

  @override
  String get shortcutHeading5Description =>
      'Set the current block to Heading 5';

  @override
  String get shortcutHeading6Description =>
      'Set the current block to Heading 6';

  @override
  String get shortcutGroupLists => 'Lists';

  @override
  String get numberedList => 'Numbered list';

  @override
  String get shortcutNumberedListDescription =>
      'Toggle numbered list formatting';

  @override
  String get bulletedList => 'Bulleted list';

  @override
  String get shortcutBulletedListDescription =>
      'Toggle bulleted list formatting';

  @override
  String get checklist => 'Checklist';

  @override
  String get shortcutChecklistDescription => 'Toggle checklist formatting';

  @override
  String get shortcutGroupSidebar => 'Sidebar';

  @override
  String get sidebarViewMenu => 'Sidebar view';

  @override
  String get createMarkdownFile => 'Create Markdown File';

  @override
  String get createMarkdownFileDescription =>
      'Start an unsaved local Markdown document';

  @override
  String get createWritersideProject => 'Create Writerside Project';

  @override
  String get createWritersideProjectDescription =>
      'Start a local Writerside-compatible project';

  @override
  String get defaultProjectName => 'Documentation';

  @override
  String get defaultInstanceName => 'User Guide';

  @override
  String get defaultStartTopicTitle => 'Getting started';

  @override
  String get projectName => 'Project name';

  @override
  String get directoryName => 'Directory name';

  @override
  String get instanceName => 'Instance name';

  @override
  String get instanceId => 'Instance ID';

  @override
  String get startTopicTitle => 'Start topic title';

  @override
  String get location => 'Location';

  @override
  String get projectNameRequired => 'Project name is required.';

  @override
  String get directoryNameRequired => 'Directory name is required.';

  @override
  String get useSingleSafeDirectoryName => 'Use a single safe directory name.';

  @override
  String get useLowercaseIdentifier =>
      'Use a lowercase identifier with letters, numbers, underscores, or hyphens.';

  @override
  String get startTopicTitleRequired => 'Start topic title is required.';

  @override
  String get createWritersideProjectFailed =>
      'Could not create Writerside project.';

  @override
  String get settingsTitle => 'BusyMark Settings';

  @override
  String get autoSave => 'Auto Save';

  @override
  String get autoSaveDescription =>
      'Save file changes automatically after a short idle delay.';

  @override
  String get wordWrap => 'Word wrap';

  @override
  String get editorFontSize => 'Editor font size';

  @override
  String get validateOnEdit => 'Validate on edit';

  @override
  String get clearRecentWorkspaces => 'Clear recent workspaces';

  @override
  String get editingButtonsPosition => 'Editing buttons position';

  @override
  String get editingButtonsPositionDescription =>
      'Choose where the floating WYSIWYG editing buttons appear.';

  @override
  String get editingButtonsDirection => 'Editing buttons direction';

  @override
  String get editingButtonsDirectionDescription =>
      'Choose whether the floating WYSIWYG editing buttons are arranged horizontally or vertically.';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get privacy => 'Privacy';

  @override
  String get allowRemoteImages => 'Load remote images';

  @override
  String get allowRemoteImagesDescription =>
      'Allow Markdown preview and editor images to load from http and https URLs.';

  @override
  String get clearRemoteImagePermissions => 'Clear remote image permissions';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Forget workspaces that were allowed to load remote images.';

  @override
  String get clearGitWorkspaceTrust => 'Clear trusted Git workspaces';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Ask before enabling Git features for previously trusted workspaces.';

  @override
  String get settingsWindowSectionTitle => 'Window';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Reopen previous workspace on startup';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Open the workspace and tabs from the previous session when BusyMark starts.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirm before closing with unsaved changes';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Ask before closing BusyMark when documents have unsaved changes.';

  @override
  String get closeUnsavedChangesTitle => 'Unsaved changes';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'This document has unsaved changes. Save changes before closing BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents have unsaved changes. Save changes before closing BusyMark?',
      one:
          '1 document has unsaved changes. Save changes before closing BusyMark?',
      zero: 'Save changes before closing BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Cancel';

  @override
  String get closeUnsavedChangesDiscard => 'Discard';

  @override
  String get closeUnsavedChangesSave => 'Save';

  @override
  String get currentFile => 'current file';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'You have unsaved changes in $fileName. Save them before continuing?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents have unsaved changes. Save them before continuing?',
      one: '1 document has unsaved changes. Save it before continuing?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'File changed on disk';

  @override
  String get fileChangedOnDiskMessage =>
      'This file changed on disk since you opened it. Overwrite it?';

  @override
  String get untitledMarkdownFileName => 'Untitled.md';

  @override
  String get unorderedList => 'Unordered list';

  @override
  String get orderedList => 'Ordered list';

  @override
  String get taskList => 'Task list';

  @override
  String get toggleTaskChecked => 'Toggle task checked';

  @override
  String get indentListItem => 'Indent list item';

  @override
  String get outdentListItem => 'Outdent list item';

  @override
  String get blockquote => 'Blockquote';

  @override
  String get codeBlock => 'Code block';

  @override
  String get codeBlockLanguage => 'Code block language';

  @override
  String get image => 'Image';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Play video';

  @override
  String get pauseVideo => 'Pause video';

  @override
  String get videoUnavailable => 'Video unavailable';

  @override
  String get videoPreview => 'Video preview';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Video is missing its src attribute.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Unsupported video source: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Video file does not exist: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Video preview image does not exist: $preview';
  }

  @override
  String get inlineImage => 'Inline image';

  @override
  String get table => 'Table';

  @override
  String get htmlBlock => 'HTML block';

  @override
  String get htmlContentDefault => 'HTML content';

  @override
  String get shortcutHtmlBlockDescription => 'Insert or edit an HTML block';

  @override
  String get renderedHtml => 'Rendered HTML';

  @override
  String get editHtml => 'Edit HTML';

  @override
  String get htmlSource => 'HTML source';

  @override
  String get thematicBreak => 'Thematic break';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get underline => 'Underline';

  @override
  String get strikethrough => 'Strikethrough';

  @override
  String get inlineCode => 'Inline code';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Hard line break';

  @override
  String get textStyle => 'Text style';

  @override
  String get paragraph => 'Paragraph';

  @override
  String get heading1 => 'Heading 1';

  @override
  String get heading2 => 'Heading 2';

  @override
  String get heading3 => 'Heading 3';

  @override
  String get heading4 => 'Heading 4';

  @override
  String get heading5 => 'Heading 5';

  @override
  String get heading6 => 'Heading 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Delete table';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Column $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Insert column left';

  @override
  String get insertColumnRight => 'Insert column right';

  @override
  String get deleteColumn => 'Delete column';

  @override
  String get tableAlignmentUnspecified => 'Alignment: Unspecified';

  @override
  String get tableAlignmentLeft => 'Alignment: Left';

  @override
  String get tableAlignmentCenter => 'Alignment: Center';

  @override
  String get tableAlignmentRight => 'Alignment: Right';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Row $rowNumber';
  }

  @override
  String get insertRowAbove => 'Insert row above';

  @override
  String get insertRowBelow => 'Insert row below';

  @override
  String get deleteRow => 'Delete row';

  @override
  String get tableHeaderHint => 'Header';

  @override
  String get tableCellHint => 'Cell';

  @override
  String get language => 'Language';

  @override
  String get hideEditingButtons => 'Hide editing buttons';

  @override
  String get showEditingButtons => 'Show editing buttons';

  @override
  String get altText => 'Alt text';

  @override
  String get editorPlaceholderText => 'text';

  @override
  String get editorPlaceholderCode => 'code';

  @override
  String get editorPlaceholderAltText => 'alt text';

  @override
  String get describeTheImage => 'Describe the image';

  @override
  String get columns => 'Columns';

  @override
  String get rows => 'Rows';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Header $columnNumber';
  }

  @override
  String get tableCellDefault => 'Cell';

  @override
  String get noImageSource => 'No image source';

  @override
  String get remoteImageBlocked => 'Remote image blocked';

  @override
  String get remoteImageBlockedTooltip =>
      'Choose whether BusyMark can load remote images.';

  @override
  String get remoteImagesBlockedTitle => 'Remote images are blocked';

  @override
  String get remoteImagesBlockedMessage =>
      'This document references images from the internet. Loading them can reveal network information to the image host.';

  @override
  String get loadRemoteImagesForWorkspace => 'Load for this workspace';

  @override
  String get alwaysLoadRemoteImages => 'Always load remote images';

  @override
  String get hideSidebar => 'Hide sidebar panel';

  @override
  String get showSidebar => 'Show sidebar panel';

  @override
  String get showPreview => 'Show preview';

  @override
  String get hidePreview => 'Hide preview';

  @override
  String get workspaceKindUnsavedMarkdown => 'Unsaved Markdown file';

  @override
  String get workspaceKindSingleMarkdown => 'Single Markdown file';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown folder';

  @override
  String get workspaceKindWritersideModule => 'Writerside module';

  @override
  String get problems => 'Problems';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnostics',
      one: '1 diagnostic',
      zero: 'No diagnostics',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Files';

  @override
  String get toc => 'TOC';

  @override
  String get tocActions => 'TOC actions';

  @override
  String get markdownUnsaved => 'Markdown - unsaved';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'No files';

  @override
  String get newFile => 'New file';

  @override
  String get noWritersideToc => 'No Writerside TOC';

  @override
  String get tocSection => 'TOC section';

  @override
  String get newTopic => 'New Topic';

  @override
  String get newChildTopic => 'New Child Topic';

  @override
  String get newSiblingTopic => 'New Sibling Topic';

  @override
  String get renameTopicFile => 'Rename Topic File';

  @override
  String get topicPlacement => 'TOC placement';

  @override
  String get tocRoot => 'At TOC root';

  @override
  String get afterSelectedTopic => 'After selected topic';

  @override
  String get insideSelectedTopic => 'Inside selected topic';

  @override
  String get pasteAfterTopic => 'Paste After';

  @override
  String get pasteAsChildTopic => 'Paste as Child';

  @override
  String get removeFromToc => 'Remove from TOC';

  @override
  String get confirmRemoveFromTocTitle => 'Remove from TOC?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Remove $name from this table of contents? The topic file will be kept.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Delete topic file?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Delete $name and remove it from every table of contents? This cannot be undone.';
  }

  @override
  String get safeDeleteTopicFile => 'Safe Delete Topic File…';

  @override
  String get removeTocElement => 'Remove TOC Element';

  @override
  String get reviewUsages => 'Review Usages';

  @override
  String get deleteTopicFile => 'Delete Topic File';

  @override
  String get removeAction => 'Remove';

  @override
  String topicRemovalSummary(String topic) {
    return 'Remove “$topic” from the selected instance. The topic file will be kept.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Delete “$topic” and safely update its references throughout this Writerside project.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count child topics will move up one level.',
      one: '1 child topic will move up one level.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'This topic is used as an instance start page. Review its usages and assign another start page before continuing.';

  @override
  String topicUsagesCount(int count) {
    return 'Usages ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'No references that would be broken were found.';

  @override
  String get topicUsagesFound =>
      'BusyMark found the following references to this topic.';

  @override
  String get topicUsageTocElements => 'TOC elements';

  @override
  String get topicUsageStartPages => 'Start pages';

  @override
  String get topicUsageTopicLinks => 'Topic links';

  @override
  String get topicUsageIncludes => 'Includes';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usages',
      one: '1 usage',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Refactoring options';

  @override
  String get updateUsagesAutomatically => 'Update usages automatically';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Remove TOC references and includes, and preserve link text.';

  @override
  String get manualUsageUpdatesRequired =>
      'Some usages require manual changes before this refactoring.';

  @override
  String get setRedirectTo => 'Set redirect to';

  @override
  String get noRedirectDescription => 'Do not redirect the old published page.';

  @override
  String get redirectTarget => 'Redirect target';

  @override
  String get remainingUsagesBlockRemoval =>
      'Review and update the remaining usages before continuing, or enable automatic updates when available.';

  @override
  String usagesOfTopic(String topic) {
    return 'Usages of $topic';
  }

  @override
  String get noUsagesFound => 'No usages found';

  @override
  String get outsideSelectedInstance => 'outside selected instance';

  @override
  String get doRefactor => 'Do Refactor';

  @override
  String get orphanTopicTitle => 'Topic file is no longer used';

  @override
  String get keepTopicFile => 'Keep Topic File';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” is no longer used anywhere in this Writerside project. Delete the file, or keep it for use in another instance.';
  }

  @override
  String get defaultNewTopicTitle => 'New topic';

  @override
  String get topicTitle => 'Topic title';

  @override
  String get fileName => 'File name';

  @override
  String get topicTitleRequired => 'Topic title is required.';

  @override
  String get fileNameRequired => 'File name is required.';

  @override
  String get rename => 'Rename';

  @override
  String get confirmDeleteFileTitle => 'Delete file?';

  @override
  String get confirmDeleteFolderTitle => 'Delete folder?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Delete $name and all files inside it? This cannot be undone.';
  }

  @override
  String get useSingleSafeFileName => 'Use a single safe file name.';

  @override
  String useExpectedExtension(String extension) {
    return 'Use the $extension extension for the selected format.';
  }

  @override
  String get useIdentifierCharacters =>
      'Use letters, numbers, underscores, or hyphens before the extension.';

  @override
  String get topicIdAlreadyExists => 'Topic ID already exists.';

  @override
  String get createWritersideTopicFailed =>
      'Could not create Writerside topic.';

  @override
  String get noOutline => 'No outline';

  @override
  String expandKind(String kind) {
    return 'Expand $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Collapse $kind';
  }

  @override
  String get foldKindSection => 'section';

  @override
  String get foldKindList => 'list';

  @override
  String get foldKindQuote => 'quote';

  @override
  String get foldKindTag => 'tag';

  @override
  String get sourceSearchPreviousMatch => 'Previous match';

  @override
  String get sourceSearchNextMatch => 'Next match';

  @override
  String get sourceSearchCaseSensitive => 'Case sensitive';

  @override
  String get sourceSearchWholeWord => 'Whole word';

  @override
  String get sourceSearchRegex => 'Regex';

  @override
  String get sourceSearchReplacement => 'Replace with';

  @override
  String get sourceSearchReplaceCurrent => 'Replace current match';

  @override
  String get sourceSearchReplaceAndFindNext => 'Replace and find next';

  @override
  String get sourceSearchReplaceAll => 'Replace all';

  @override
  String get workspaceReplace => 'Replace in Workspace';

  @override
  String get reviewReplacements => 'Review replacements';

  @override
  String get applyReplacements => 'Apply replacements';

  @override
  String get skippedFiles => 'Skipped files';

  @override
  String get workspaceReplaceDirtyBuffer => 'Unsaved editor content';

  @override
  String get workspaceReplaceDiskContent => 'Saved disk content';

  @override
  String selectFileMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Select all $count matches',
      one: 'Select 1 match',
    );
    return '$_temp0';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Replaced $matches matches in $files files; skipped $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Final newline';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · No final newline';
  }

  @override
  String get normalizeLineEndings => 'Normalize line endings';

  @override
  String get mixedLineEndingsSavePrompt =>
      'This document contains mixed line endings. Choose a format.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName uses mixed line endings. Choose the format to use before replacing.';
  }

  @override
  String get workspaceReplaceIssueOversized => 'Skipped an oversized file.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Skipped a file that could not be read.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Skipped a file that is not valid UTF-8.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'The replacement preview was truncated.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Skipped a file that changed after the preview.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Skipped an editor buffer that changed after the preview.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Choose LF or CRLF normalization before replacing.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Rollback stopped because the file changed concurrently. Some replacements may remain; displaced content was preserved at the path below.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'The reviewed replacement could not be committed; no files were changed.';

  @override
  String externalChangesTitle(String fileName) {
    return 'External changes — $fileName';
  }

  @override
  String get externalFileDeleted => 'This file was deleted on disk.';

  @override
  String get externalFileChanged =>
      'This file changed on disk while you have unsaved edits.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Recovered unsaved content for $fileName. Inspect it, then save, save as, or discard it.';
  }

  @override
  String get compare => 'Compare';

  @override
  String get reloadFromDisk => 'Reload from Disk';

  @override
  String get keepMine => 'Keep Mine';

  @override
  String get saveAs => 'Save As';

  @override
  String get sourceSearchInvalidRegex => 'Invalid regular expression';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Large file: highlighting and folding are paused';

  @override
  String get nothingToRead => 'Nothing to read';

  @override
  String get admonition => 'Admonition';

  @override
  String get quote => 'Quote';

  @override
  String get note => 'Note';

  @override
  String get tip => 'Tip';

  @override
  String get warning => 'Warning';

  @override
  String get tabs => 'Tabs';

  @override
  String get tab => 'Tab';

  @override
  String get procedure => 'Procedure';

  @override
  String get step => 'Step';

  @override
  String get topic => 'Topic';

  @override
  String get chapter => 'Chapter';

  @override
  String couldNotOpenTarget(String target) {
    return 'Could not open $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Link target not found: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Cannot open this file type in editor';

  @override
  String anchorNotFound(String anchor) {
    return 'Anchor not found: $anchor';
  }

  @override
  String get noProblemsFound => 'No problems found';

  @override
  String get noResults => 'No results';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - Line $lineNumber';
  }

  @override
  String get untitledResult => 'Untitled result';

  @override
  String get documentKindMarkdownFile => 'Markdown file';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown topic';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML topic';

  @override
  String get documentKindWritersideTree => 'Writerside tree';

  @override
  String get documentKindConfigurationFile => 'Configuration file';

  @override
  String get documentKindVariablesFile => 'Variables file';

  @override
  String get documentKindCategoriesFile => 'Categories file';

  @override
  String get documentKindResourceFile => 'Resource file';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Open failed: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Could not create Writerside project: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Could not create Writerside topic: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Could not open file: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Choose where to save this Markdown file.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Save blocked: file changed on disk.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'File operation failed: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Validation failed: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Recovered $count unsaved documents. Review each one before saving or discarding it.',
      one:
          'Recovered 1 unsaved document. Review it before saving or discarding it.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count damaged recovery records could not be restored. Valid recovery records remain available.',
      one:
          'One damaged recovery record could not be restored. The original recovery file was preserved for inspection.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Path does not exist: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Target directory already exists and is not empty: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Target path already exists and is not a directory: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Generated file already exists: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Parent directory is required.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Parent directory does not exist: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Directory does not exist: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Path already exists: $path';
  }

  @override
  String get errorFileNameRequired => 'File name is required.';

  @override
  String get errorFileNameUnsafe =>
      'File name must be a single safe path segment.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Cannot move a folder into itself.';

  @override
  String get errorFileOperationOutsideRoot =>
      'File operation must stay inside the workspace.';

  @override
  String get errorFileOperationRoot =>
      'The workspace root cannot be changed from the file tree.';

  @override
  String get errorProjectNameRequired => 'Project name is required.';

  @override
  String get errorDirectoryNameRequired => 'Directory name is required.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Directory name must be a single safe path segment.';

  @override
  String get errorInstanceIdInvalid =>
      'Instance ID must start with a lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens.';

  @override
  String get errorTopicFileInvalid =>
      'Topic file name must be a Markdown file name without path separators.';

  @override
  String get errorTopicTitleRequired => 'Topic title is required.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside module root does not exist: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'A Writerside module must be open to create a topic.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'The Writerside module has no instance tree.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside tree file does not exist: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Topic ID \"$topicId\" already exists in this help module.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Topic file already exists: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Reference topic is not present in the selected tree: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'The selected TOC entry no longer exists.';

  @override
  String get errorWritersideTocInvalidMove =>
      'A TOC entry cannot be moved into itself or one of its children.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'The start topic $topic cannot be deleted. Choose another start page first.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Use Safe Delete for Writerside topic files.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Could not complete the topic usage scan. No files were changed.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Some topic usages still require attention. Review them before continuing.';

  @override
  String get errorWritersideRedirectInvalid =>
      'The selected redirect target is no longer valid. Choose it again.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Topic removal could not be fully rolled back. Review these paths before continuing: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Topics root must be a safe relative directory.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Topic file name must be a single safe path segment.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Topic file extension must match the selected format ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Topic file name must contain only letters, numbers, underscores, and hyphens.';

  @override
  String errorUnknown(String code) {
    return 'Unknown error: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Could not read file metadata: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Large workspace detected. Some files were skipped to keep the app responsive.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Could not inspect workspace entry: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'File is larger than the beta auto-parse limit.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Could not read Markdown file: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Malformed Writerside heading attribute block.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Duplicate heading ID \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Additional top-level H1 headings are treated as chapters.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown topic has no H1 or front matter title.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML topic is missing title.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Topic \"$fileName\" is missing a title.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Front matter is not closed.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Unsafe HTML element.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Link target does not exist: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Anchor \"$anchor\" does not exist.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Image \"$destination\" is missing alt text.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Image does not exist: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Invalid XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg root must be <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets declaration is missing src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups declaration is missing src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Unsupported keymaps mode: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Instance declaration is missing src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg does not register an instance.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree root must be <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Instance profile is missing id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Tree file stem does not match instance id \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Non-library instance is missing start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Start page \"$startPage\" does not exist.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Topic \"$topic\" appears more than once in this instance TOC.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Variable declaration must have name and value.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Variable \"$name\" is declared more than once.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => 'Category is missing id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Category \"$id\" is declared more than once.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Category order \"$order\" is declared more than once.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic root must be <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML topic is missing root id.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML topic root id \"$id\" must match filename \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Element id \"$elementId\" appears more than once.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> is missing href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside mode requires writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Configured build config directory is missing: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Configured API specifications directory is missing: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Configured snippets directory is missing: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Configured variables file is missing: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Configured categories file is missing: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Configured instance groups file is missing: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Registered instance tree \"$source\" does not exist.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Could not read topic file: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Default topics directory is missing: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Configured topics directory is missing: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Configured images directory is missing: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Element id \"$id\" appears more than once.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'TOC references missing topic \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'External href \"$href\" is invalid.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Variable \"%$name%\" is not declared.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Topic link \"$destination\" does not resolve.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Anchor \"$anchor\" does not exist in \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> is missing the from attribute.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Include source \"$from\" does not exist.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Include element \"$elementId\" does not exist in \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Seealso category \"$ref\" is not declared.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Topic reference \"$reference\" is ambiguous.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Unknown diagnostic: $code';
  }

  @override
  String get close => 'Close';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git diff';

  @override
  String get gitShowDiff => 'Show diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'old $oldRange → new $newRange';
  }

  @override
  String get gitDiffNoLines => 'no lines';

  @override
  String get gitUnavailableTitle => 'Git is unavailable';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Install Git or configure BusyMark to use an available Git executable. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'Trust this workspace for Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Git repositories can run programs through hooks, filters, and other configuration. Trust this workspace before BusyMark reads repository data or enables Git actions.';

  @override
  String get gitTrustWorkspace => 'Trust workspace';

  @override
  String get gitNotRepositoryTitle => 'Not a Git repository';

  @override
  String get gitNotRepositoryMessage =>
      'This workspace is not inside a Git repository.';

  @override
  String get gitInitializeRepository => 'Initialize repository';

  @override
  String get gitDetachedHead => 'Detached HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Detached at $commit';
  }

  @override
  String get gitNoUpstream => 'No upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unpushed commits',
      one: '1 unpushed commit',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits to pull',
      one: '1 commit to pull',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Clean';

  @override
  String get gitConflicts => 'Conflicts';

  @override
  String get gitChanges => 'Changes';

  @override
  String get gitStaged => 'Staged';

  @override
  String get gitUnstaged => 'Unstaged';

  @override
  String get gitHistory => 'History';

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitActions => 'Git actions';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Stage file';

  @override
  String get gitRemoveFromCommit => 'Unstage file';

  @override
  String get gitDiscard => 'Rollback';

  @override
  String get gitOpenFile => 'Open file';

  @override
  String get gitMarkResolved => 'Mark resolved';

  @override
  String get gitUntracked => 'Untracked';

  @override
  String get gitCommitMessage => 'Commit message';

  @override
  String get gitCommitSelectedFiles => 'Selected files';

  @override
  String get gitCommitNoSelectedFiles =>
      'Stage at least one file before committing.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staged files',
      one: '1 staged file',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Outside workspace';

  @override
  String get gitCommitMessageRequired => 'Enter a commit message.';

  @override
  String get gitCreateBranch => 'Create branch';

  @override
  String get gitNewBranch => 'New Branch';

  @override
  String get gitBranchName => 'Branch name';

  @override
  String get gitSwitchBranch => 'Switch';

  @override
  String get gitNoChanges => 'No changes';

  @override
  String get gitNoHistory => 'No history';

  @override
  String get gitNoBranches => 'No branches';

  @override
  String get gitNoDiff => 'No diff to show';

  @override
  String get gitBinaryFile =>
      'Binary file. BusyMark does not render binary patches.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Binary file ($size bytes). BusyMark does not render binary patches.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Unsaved editor changes are not included until saved.';

  @override
  String get gitConfirmDiscardTitle => 'Discard Git changes?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All staged and unstaged changes in the selected tracked files will be restored to HEAD.',
      one:
          'All staged and unstaged changes in the selected tracked file will be restored to HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The selected untracked files will be deleted.',
      one: 'The selected untracked file will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The selected files will be restored or deleted based on their Git status.',
      one:
          'The selected file will be restored or deleted based on its Git status.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Switch to $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark will reload the workspace from disk after Git switches branches.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Set upstream branch?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'This branch has no upstream. BusyMark can push $branch and set its upstream when exactly one remote is configured.';
  }

  @override
  String get gitProjectHistory => 'Project History';

  @override
  String get gitFileHistory => 'File History';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'File History requires an open Markdown file.';

  @override
  String get gitLoadMore => 'Load More';

  @override
  String get gitChangesInCommit => 'Changes in this commit';

  @override
  String get gitCompareWithCurrent => 'Compare with current';

  @override
  String get gitRestoreVersion => 'Restore this version';

  @override
  String get gitConfirmRestoreTitle => 'Restore this file version?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark will replace the current working-tree file with the selected committed version. The restored file will remain unstaged.';

  @override
  String get gitCommitActions => 'Commit actions';

  @override
  String get gitResetCurrentBranchToHere => 'Reset current branch to here…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Reset $branch to $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'This moves branch $branch to commit $commit. Choose how Git updates the index and working tree.';
  }

  @override
  String get gitReset => 'Reset';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Move the branch only. Keep the index and working tree unchanged; differences from the selected commit remain staged.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Move the branch and reset the index. Keep the working tree unchanged, leaving differences unstaged.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Move the branch and reset the index and working tree. Tracked changes are discarded; obstructing untracked files may be deleted.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Move the branch and reset tracked files while preserving local changes. Git aborts if those changes conflict with the reset.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'File actions';

  @override
  String get actions => 'Actions';

  @override
  String get gitStatusAdded => 'Added';

  @override
  String get gitStatusDeleted => 'Deleted';

  @override
  String get gitStatusRenamed => 'Renamed';

  @override
  String get gitStatusCopied => 'Copied';

  @override
  String get gitStatusUntracked => 'Untracked';

  @override
  String get gitStatusConflicted => 'Conflicted';

  @override
  String get gitStatusIgnored => 'Ignored';

  @override
  String get gitStatusTypeChanged => 'Type changed';

  @override
  String get gitStatusModified => 'Modified';

  @override
  String get gitStatusUnknown => 'Unknown';

  @override
  String get gitErrorUnavailable => 'Git is unavailable.';

  @override
  String get gitErrorNotRepository => 'This workspace is not a Git repository.';

  @override
  String get gitErrorUnsafePath => 'BusyMark blocked an unsafe Git path.';

  @override
  String get gitErrorInvalidBranchName => 'Enter a valid branch name.';

  @override
  String get gitErrorNoRemote => 'No Git remote is configured.';

  @override
  String get gitErrorNoUpstream => 'No upstream branch is configured.';

  @override
  String get gitErrorMultipleRemotes =>
      'Multiple remotes are configured. Choose an upstream outside this BusyMark version.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Save or discard BusyMark editor changes before switching branches.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Save or discard BusyMark editor changes before resetting the current branch.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Unstage this file before restoring a historical version.';

  @override
  String get gitErrorResetDetachedHead =>
      'Check out a branch before resetting it.';

  @override
  String get gitErrorDiverged =>
      'Branch has diverged. Resolve merge or rebase outside this BusyMark version.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git needs an author name and email address before it can commit.';

  @override
  String get gitAuthorIdentityTitle => 'Git Author Identity';

  @override
  String get gitAuthorIdentityMessage =>
      'Enter the identity Git should record on commits. BusyMark will save it and retry this commit.';

  @override
  String get gitAuthorName => 'Name';

  @override
  String get gitAuthorEmail => 'Email';

  @override
  String get gitAuthorIdentityGlobal => 'Use for all repositories';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'When installed as a Snap, this applies to repositories opened in BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Save and Commit';

  @override
  String get gitErrorAuthentication => 'Git authentication failed.';

  @override
  String get gitErrorNetwork => 'Git network operation failed.';

  @override
  String get gitErrorConflict => 'Git reported unresolved conflicts.';

  @override
  String get gitErrorCommandFailed => 'Git command failed.';

  @override
  String get syntaxReference => 'Referência de sintaxe';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Blocos Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Estruturas de bloco compatíveis no código Markdown e na pré-visualização.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown em linha';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatação dentro de parágrafos, itens de lista e células de tabela.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Blocos de HTML bruto';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Tags HTML de bloco seguras renderizadas pelos widgets de pré-visualização do BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Tags de HTML bruto em linha';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Tags HTML em linha seguras renderizadas sem mostrar as tags literais.';

  @override
  String get syntaxReferenceSafety => 'Regras de segurança';

  @override
  String get syntaxReferenceSafetyDescription =>
      'O HTML bruto é analisado e higienizado antes da pré-visualização.';

  @override
  String get syntaxReferenceHeadings => 'Títulos';

  @override
  String get syntaxReferenceParagraphs => 'Parágrafos';

  @override
  String get syntaxReferenceLists => 'Listas';

  @override
  String get syntaxReferenceHtmlContainers => 'Contêineres';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Blocos de texto';

  @override
  String get syntaxReferenceHtmlFigures => 'Figuras e imagens';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Código pré-formatado';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Blocos expansíveis';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Listas de descrição';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tags de formatação';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tags de código em linha';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Tags de texto semântico';

  @override
  String get syntaxReferenceSanitizedPreview => 'Pré-visualização higienizada';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'O HTML permitido é convertido em blocos de pré-visualização do BusyMark e não é renderizado em um navegador.';

  @override
  String get syntaxReferenceSourcePreserved => 'Código-fonte preservado';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'HTML bruto não editado é salvo exatamente como texto fonte.';

  @override
  String get syntaxReferenceMarkdownInsideHtml => 'Markdown dentro de HTML';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Marcadores Markdown dentro de HTML bruto são exibidos como texto literal.';

  @override
  String get syntaxReferenceBlockedContent => 'Conteúdo ativo bloqueado';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Scripts, estilos, frames, formulários, SVG, MathML, eventos e atributos inseguros são bloqueados.';

  @override
  String get syntaxReferenceSafeUrls => 'Somente URLs seguras';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Links permitem http, https, mailto, tel, URLs relativas e fragmentos; esquemas inseguros são bloqueados.';

  @override
  String get syntaxReferenceCategory => 'Categoria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramas e API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matemática';

  @override
  String get syntaxReferenceExample => 'Exemplo';

  @override
  String get syntaxReferenceIdentifiers => 'Identificadores e aliases';

  @override
  String get syntaxReferenceScope => 'Escopo';

  @override
  String get syntaxReferenceLimitation => 'Limitação do BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Documentação oficial';

  @override
  String get syntaxReferenceScopeMarkdownAndWritersideMarkdown =>
      'Markdown comum e Markdown do Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Somente Markdown do Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Somente Markdown e XML do Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'As formas essenciais de Markdown que o BusyMark pode criar e visualizar.';

  @override
  String get syntaxReferenceParagraphExample => 'Um parágrafo de texto.';

  @override
  String get syntaxReferenceTableLimitation =>
      'As tabelas usam a sintaxe de barras verticais do GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dois espaços no fim da linha, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'O BusyMark aceita um subconjunto seguro e específico de HTML bruto no código Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Blocos cercados Mermaid, PlantUML, D2 e OpenAPI funcionam no código Markdown. Os identificadores não diferenciam maiúsculas de minúsculas, e o BusyMark preserva a grafia original.';

  @override
  String get syntaxReferenceMermaid => 'Mermaid';

  @override
  String get syntaxReferencePlantUml => 'PlantUML';

  @override
  String get syntaxReferenceD2 => 'D2';

  @override
  String get syntaxReferenceOpenApi => 'OpenAPI';

  @override
  String get syntaxReferenceOpenApiLimitation =>
      'Use conteúdo YAML ou JSON em um bloco cercado. O BusyMark não trata um documento YAML ou JSON completo qualquer como referência OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Blocos de código semânticos para diagramas';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'As formas semânticas code-block e src aceitam Mermaid, PlantUML e D2, não OpenAPI, e somente em projetos Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Origem de diagrama referenciada';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Os caminhos devem ser relativos e permanecer dentro do projeto Writerside aberto; a forma de bloco cercado com src é exclusiva do Markdown do Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'O BusyMark aceita expressões TeX, não documentos TeX ou LaTeX completos.';

  @override
  String get syntaxReferenceInlineMath => 'Matemática em linha';

  @override
  String get syntaxReferenceGithubMath =>
      'Matemática do GitHub com cifrão e crase';

  @override
  String get syntaxReferenceDisplayMath => 'Matemática em bloco';

  @override
  String get syntaxReferenceMathFence => 'Bloco cercado math';

  @override
  String get syntaxReferenceTexFence => 'Bloco cercado tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'O BusyMark não reconhece \\(...\\) nem \\[...\\] como delimitadores matemáticos do Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Fora do modo Writerside, um bloco tex continua sendo um bloco de código comum.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Elemento math do Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'O elemento math é sintaxe semântica do Writerside, não MathML HTML bruto permitido.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Bloco de código TeX semântico';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Estas extensões específicas são interpretadas somente em projetos Writerside abertos.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Citação de aviso';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Uma citação simples é uma dica no Markdown do Writerside; no Markdown comum, continua sendo uma citação normal.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Avisos semânticos';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'O Markdown comum não interpreta estes elementos semânticos do Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Título recolhível';

  @override
  String get syntaxReferenceCollapsibleCode => 'Bloco de código recolhível';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Conteúdo semântico recolhível';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'O BusyMark aceita as formas recolhíveis chapter, procedure, code-block e lista de definições, não todo o catálogo do Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Blocos de código semânticos para matemática e diagramas';

  @override
  String get syntaxReferenceVideo => 'Vídeo do Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Vídeo local usa uma imagem preview-src local; fontes hospedadas devem ser URLs HTTPS compatíveis do YouTube ou Vimeo.';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String get pdfExportDescription =>
      'Choose the page layout for a polished, self-contained PDF.';

  @override
  String get pdfRemoteImagesNote =>
      'Remote images are not downloaded during export. Local images are included when available.';

  @override
  String get pdfPageSize => 'Page size';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => 'Orientation';

  @override
  String get pdfPortrait => 'Portrait';

  @override
  String get pdfLandscape => 'Landscape';

  @override
  String get pdfMargins => 'Margins';

  @override
  String get pdfMarginNarrow => 'Narrow';

  @override
  String get pdfMarginNormal => 'Normal';

  @override
  String get pdfMarginWide => 'Wide';

  @override
  String get pdfIncludePageNumbers => 'Include page numbers';

  @override
  String get export => 'Export';

  @override
  String get exportingPdf => 'Exporting PDF…';

  @override
  String get fileTypePdf => 'PDF document';

  @override
  String pdfExported(String fileName) {
    return '$fileName was exported.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
    );
    return '$fileName was exported with $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'The PDF export component is missing. Reinstall BusyMark and try again.';

  @override
  String get pdfExportTimedOut => 'PDF export took too long and was stopped.';

  @override
  String get pdfExportFailed =>
      'BusyMark could not export this document as PDF.';

  @override
  String get visualizationRendering => 'Rendering…';

  @override
  String get visualizationStale => 'Showing the last valid render';

  @override
  String get visualizationShowSource => 'Show source';

  @override
  String get visualizationShowRender => 'Show render';

  @override
  String get visualizationFitWidth => 'Fit to width';

  @override
  String get visualizationSaveImage => 'Save image';

  @override
  String get visualizationCopyImage => 'Copy image';

  @override
  String get visualizationImageCopied => 'Image copied';

  @override
  String get visualizationOpenApiReference => 'Open API Reference';

  @override
  String get visualizationValid => 'Valid';

  @override
  String get visualizationInvalid => 'Invalid';

  @override
  String get visualizationServers => 'Servers';

  @override
  String get visualizationPaths => 'Paths';

  @override
  String get visualizationOperations => 'Operations';

  @override
  String get visualizationTags => 'Tags';

  @override
  String get visualizationNoOperations => 'No matching operations';

  @override
  String get visualizationSearchOperations => 'Search operations';

  @override
  String get visualizationRenderFailed =>
      'This visualization could not be rendered.';

  @override
  String get visualizationRetry => 'Retry';

  @override
  String visualizationSaved(String fileName) {
    return 'Saved $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Export the active document or Writerside module as a PDF.';

  @override
  String get instances => 'Instances';

  @override
  String get newInstance => 'New instance';

  @override
  String get newTocLibrary => 'New TOC library';

  @override
  String get editInstance => 'Edit instance';

  @override
  String get openTocFile => 'Open TOC file';

  @override
  String get createInstance => 'Create instance';

  @override
  String get createTocLibrary => 'Create TOC library';

  @override
  String get instanceContent => 'Content';

  @override
  String get instanceContentSource => 'Create from';

  @override
  String get emptyInstance => 'Empty instance';

  @override
  String get markdownFiles => 'Local Markdown files';

  @override
  String get chooseMarkdownFolder => 'Choose Markdown folder';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Choose a folder containing Markdown files.';

  @override
  String get instanceAppearance => 'Appearance';

  @override
  String get instanceColor => 'Icon color';

  @override
  String get instanceVersion => 'Version';

  @override
  String instanceVersionInherited(String version) {
    return 'The project version is $version when this field is empty.';
  }

  @override
  String get instanceWebPath => 'Web path';

  @override
  String get instanceStatus => 'Status';

  @override
  String get instanceStatusRelease => 'Release';

  @override
  String get instanceStatusEap => 'Early access';

  @override
  String get instanceStatusDeprecated => 'Deprecated';

  @override
  String get allowSearchEngineIndexing => 'Allow search engine indexing';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Allow external search engines to index this output.';

  @override
  String get offlineArtifact => 'Offline artifact';

  @override
  String get offlineArtifactDescription =>
      'Bundle resources so the built documentation is self-contained.';

  @override
  String get instanceOutputSettings => 'Output settings';

  @override
  String get markdownImportSource => 'Markdown source';

  @override
  String get markdownImportFiles => 'Markdown files';

  @override
  String get selectNone => 'Select none';

  @override
  String markdownFilesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Markdown files found',
      one: '1 Markdown file found',
    );
    return '$_temp0';
  }

  @override
  String get noMarkdownFilesFound =>
      'No Markdown files were found in this directory.';

  @override
  String get copyReferencedMedia => 'Copy referenced media';

  @override
  String get copyReferencedMediaDescription =>
      'Copy local images and video referenced by the selected files while preserving relative paths.';

  @override
  String get instanceIdRenameWarningTitle => 'Rename instance ID?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark will rename the .tree file and update Writerside project references from “$oldId” to “$newId”. Publication scripts are not changed and must be updated separately.';
  }

  @override
  String get renameAndUpdateReferences => 'Rename and update references';

  @override
  String get tocLibraryDescription =>
      'A TOC library stores reusable sections and does not produce its own output.';

  @override
  String get defaultTocLibraryName => 'Shared TOC';

  @override
  String get instanceColorAutomatic => 'Automatic';

  @override
  String get instanceColorBlue => 'Blue';

  @override
  String get instanceColorGreen => 'Green';

  @override
  String get instanceColorOrange => 'Orange';

  @override
  String get instanceColorPurple => 'Purple';

  @override
  String get instanceColorRed => 'Red';

  @override
  String get instanceColorTeal => 'Teal';

  @override
  String get instanceColorYellow => 'Yellow';

  @override
  String get errorWritersideInstanceNameRequired => 'Enter an instance name.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'An instance with ID “$id” already exists.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'The instance tree already exists: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'The Markdown source directory does not exist: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Select at least one Markdown file to import.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'This is not a readable Markdown file inside the selected source: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Import would overwrite an existing project file: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Instance files changed on disk. Review them and try again.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark could not completely roll back the instance change. Review these files before continuing: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'A TOC library cannot import Markdown topics.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'The web path must be a single line.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'The Writerside instance configuration is invalid. Correct its diagnostics and try again.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark could not stage the instance changes safely.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Unknown instance status “$status”. Use release, eap, or deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'The instance ID “$id” is used by more than one tree file.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml must have a <buildprofiles> root element.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'The $name value “$value” must be true or false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'A <build-profile> element must specify an instance ID.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'A tree <include> must specify both from and element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'A tree <snippet> must specify an id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'A cross-instance TOC reference must specify both ref and in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'A TOC element cannot target more than one topic, reference, link, or redirect.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Tree element ID “$id” is declared more than once.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'The instance groups file must have an <instance-groups> root element.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'An instance group must specify a non-empty id and instances list.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Instance group ID “$id” is declared more than once.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'TOC include “$source#$id” belongs to external module “$origin” and cannot be expanded in this workspace.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Tree element “$id” does not exist in registered tree “$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Tree include “$source#$id” creates a cycle.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Instance condition references unknown group “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Cross-instance reference targets unknown instance “$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Topic “$topic” is not in referenced instance “$instance”.';
  }

  @override
  String get download => 'Download';

  @override
  String get exportWritersideAsPdf => 'Export Writerside as PDF';

  @override
  String get writersidePdfContent => 'Export content';

  @override
  String get writersidePdfPage => 'Page';

  @override
  String get exportingWritersidePdf => 'Exporting Writerside PDF…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'Local Ollama';

  @override
  String get aiDisabled => 'Disabled';

  @override
  String get aiExplicitEditingDescription =>
      'AI editing is explicit. BusyMark sends only the context shown for the selected provider and never applies a proposal without review.';

  @override
  String get aiProvider => 'AI provider';

  @override
  String get aiDefaultProvider => 'Default provider';

  @override
  String get aiConfigureProvider => 'Configure provider';

  @override
  String get aiChooseProvider => 'Choose AI provider';

  @override
  String get aiOllamaEndpoint => 'Ollama endpoint';

  @override
  String get aiOllamaModel => 'Ollama model';

  @override
  String get aiTestConnection => 'Test connection';

  @override
  String get aiTestingConnection => 'Testing…';

  @override
  String aiConnectionReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count installed models found',
      one: '1 installed model found',
    );
    return 'Connected. $_temp0.';
  }

  @override
  String get aiNoModels => 'No model selected.';

  @override
  String get aiConnectionFailed =>
      'BusyMark could not verify AI text generation.';

  @override
  String get aiConfigureFirst =>
      'Enable an AI provider and verify a model in Settings → AI.';

  @override
  String get aiEditWithAi => 'Edit with AI';

  @override
  String get aiRefineWithAi => 'Refine with AI';

  @override
  String get aiInstruction => 'Instruction';

  @override
  String get aiChangeTarget => 'What may change';

  @override
  String get aiSharedContext => 'Context shared with AI';

  @override
  String get aiTargetSelection => 'Selected content';

  @override
  String get aiTargetInsertAfterBlock => 'Insert after current block';

  @override
  String get aiTargetCurrentBlock => 'Current block';

  @override
  String get aiTargetCurrentSection => 'Current section';

  @override
  String get aiTargetCompleteDocument => 'Complete document';

  @override
  String get aiContextNone => 'No document context';

  @override
  String get aiContextSelection => 'Selected content';

  @override
  String get aiContextCurrentBlock => 'Current block';

  @override
  String get aiContextCurrentSection => 'Current section';

  @override
  String get aiContextCompleteDocument => 'Complete document';

  @override
  String get aiGenerating => 'Generating proposal…';

  @override
  String get aiProposal => 'AI proposal';

  @override
  String get aiGenerateProposal => 'Generate proposal';

  @override
  String aiContextDisclosure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return 'The selected provider will receive $_temp0 from the displayed context.';
  }

  @override
  String get aiOriginal => 'Original';

  @override
  String get aiSuggested => 'Suggested';

  @override
  String get aiApplyProposal => 'Apply proposal';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input input tokens · $output output tokens';
  }

  @override
  String get aiStaleProposal =>
      'The document changed while this proposal was generated. Run the action again.';

  @override
  String get gitAiStagedChangesChanged =>
      'The staged changes changed while this commit message was generated. Run the action again.';

  @override
  String get aiViewContext => 'View context sent';

  @override
  String get aiReviewExactContent => 'Review exact content';

  @override
  String get aiContentToChange => 'Content to change';

  @override
  String get aiContentSentToAi => 'Content sent to AI';

  @override
  String get aiApiKey => 'API key';

  @override
  String get aiApiKeyStoredHint =>
      'A key is stored in the system credential store';

  @override
  String get aiApiKeyEnterHint => 'Enter a provider API key';

  @override
  String get aiReplaceApiKey => 'Replace API key';

  @override
  String get aiSaveApiKey => 'Save API key securely';

  @override
  String get aiRemoveApiKey => 'Remove saved API key';

  @override
  String get aiCredentialSaved =>
      'API key saved in the system credential store.';

  @override
  String get aiCredentialRemoved => 'The saved API key was removed.';

  @override
  String get aiModelRouting => 'Model routing';

  @override
  String get aiAutomaticRouting => 'Automatic by task';

  @override
  String get aiFixedModelRouting => 'Use selected model';

  @override
  String get aiPreferredModel => 'Preferred model';

  @override
  String get aiModel => 'Model';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests requests · $input input tokens · $output output tokens';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Send content to $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Enable $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Only content shown in each AI review dialog is sent. Requests are stateless, proposals require review, and the API key is stored in the Linux system credential store.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Confirm $provider data sharing in Settings → AI first.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compatible models available',
      one: '1 compatible model available',
    );
    return 'Generation verified with $model. $_temp0.';
  }

  @override
  String get aiColdStartObserved => 'A local model cold start was observed.';

  @override
  String get aiNoCompatibleModels =>
      'No compatible text-generation model is available.';

  @override
  String get aiEnableProvider => 'Enable an AI provider first.';

  @override
  String get aiDraftCommitMessage => 'Draft commit message';

  @override
  String get aiDrafting => 'Drafting…';

  @override
  String get aiDraftWithAi => 'Draft with AI';

  @override
  String get generateOrUpdateMarkdownToc => 'Generate/update table of contents';

  @override
  String get markdownTocTitle => 'Table of contents';

  @override
  String markdownTocUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'Table of contents updated with $_temp0.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Add at least one section heading before generating a table of contents.';

  @override
  String get markdownTocMalformedMarkers =>
      'The BusyMark table-of-contents markers are missing, duplicated, or out of order.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Heading level $level follows level $previousLevel; review the section nesting.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Link text is empty; provide an accessible name that describes its purpose.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Review whether the link text “$text” describes its purpose in context.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Table header cells must identify their columns; complete each empty header.';

  @override
  String get mathRenderFailed =>
      'The mathematical expression could not be rendered.';

  @override
  String get inlineMath => 'Inline math';

  @override
  String get displayMath => 'Display math';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor para arquivos Markdown e projetos de documentação compatíveis com o Writerside.';

  @override
  String get aboutBusyMark => 'Sobre BusyMark';

  @override
  String get aboutTagline => 'Editor de Markdown e Writerside';

  @override
  String get aboutLicenseLabel => 'Licença';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Site';

  @override
  String get aboutSourceCode => 'Código-fonte';

  @override
  String get reportIssue => 'Comunicar um problema';

  @override
  String get feedbackCategory => 'Categoria';

  @override
  String get feedbackChooseCategory => 'Escolha uma categoria';

  @override
  String get feedbackCategoryProblem => 'Problema ou erro';

  @override
  String get feedbackCategoryFeature => 'Pedido de funcionalidade';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Preocupação com privacidade ou segurança';

  @override
  String get feedbackCategoryUsability => 'Preocupação de usabilidade';

  @override
  String get feedbackCategoryOther => 'Outro';

  @override
  String get feedbackSubject => 'Assunto';

  @override
  String get feedbackMessage => 'Mensagem detalhada';

  @override
  String get feedbackReplyEmail => 'E-mail para resposta (opcional)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Incluir detalhes técnicos';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Quando esta opção está ativada, adiciona apenas a versão do sistema operacional Linux e o locale do BusyMark. Nenhum log, arquivo, dados de conta ou outro diagnóstico é anexado.';

  @override
  String get feedbackSubmit => 'Enviar';

  @override
  String get feedbackSubmitting => 'Enviando…';

  @override
  String get feedbackCategoryRequired => 'Escolha uma categoria.';

  @override
  String get feedbackSubjectLength =>
      'O assunto deve ter entre 3 e 120 caracteres.';

  @override
  String get feedbackMessageLength =>
      'A mensagem deve ter entre 10 e 5000 caracteres.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Digite um endereço de e-mail válido ou deixe este campo vazio.';

  @override
  String get feedbackConnectionFailure =>
      'O BusyMark não conseguiu estabelecer conexão. Verifique a conexão com a Internet e tente novamente.';

  @override
  String get feedbackTimeoutFailure =>
      'O pedido excedeu o tempo limite. Tente novamente.';

  @override
  String get feedbackRateLimitedFailure =>
      'Foram enviados relatórios demais a partir desta conexão. Aguarde e tente novamente.';

  @override
  String get feedbackRejectedFailure =>
      'O servidor rejeitou o relatório. Verifique os campos do formulário e tente novamente.';

  @override
  String get feedbackServerFailure =>
      'O servidor não conseguiu aceitar o relatório. Tente novamente mais tarde.';

  @override
  String feedbackSuccess(String id) {
    return 'Comentários enviados. ID de referência: $id';
  }

  @override
  String get advanced => 'Avançado';

  @override
  String get addToGit => 'Adicionar ao Git';

  @override
  String get appearance => 'Aparência';

  @override
  String get apply => 'Aplicar';

  @override
  String get back => 'Voltar';

  @override
  String get bottomLeft => 'Canto inferior esquerdo';

  @override
  String get bottomRight => 'Canto inferior direito';

  @override
  String get cancel => 'Cancelar';

  @override
  String get choose => 'Escolher';

  @override
  String get chooseLocation => 'Escolher local';

  @override
  String get copy => 'Copiar';

  @override
  String get copyName => 'Copiar nome';

  @override
  String get copyFileName => 'Copiar nome do arquivo';

  @override
  String get copyPath => 'Copiar caminho';

  @override
  String get create => 'Criar';

  @override
  String get creating => 'Criando...';

  @override
  String get cut => 'Recortar';

  @override
  String get promoteSection => 'Promover seção';

  @override
  String get demoteSection => 'Rebaixar seção';

  @override
  String get moveSectionUp => 'Mover seção para cima';

  @override
  String get moveSectionDown => 'Mover seção para baixo';

  @override
  String get confirmDeleteSectionTitle => 'Excluir seção?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Excluir “$name” e todo o conteúdo da seção? Isso não pode ser desfeito.';
  }

  @override
  String get darkTheme => 'Escuro';

  @override
  String get delete => 'Excluir';

  @override
  String get discard => 'Descartar';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'Arquivo';

  @override
  String get fileHistory => 'Histórico do arquivo';

  @override
  String get folder => 'Pasta';

  @override
  String get insert => 'Inserir';

  @override
  String get keyboardShortcuts => 'Atalhos de teclado';

  @override
  String get commandPalette => 'Paleta de comandos';

  @override
  String get commandPaletteHint => 'Digite um comando';

  @override
  String get commandPaletteEmpty => 'Nenhum comando correspondente';

  @override
  String get commandUnavailableInContext =>
      'Este comando não está disponível no contexto atual.';

  @override
  String get lightTheme => 'Claro';

  @override
  String get mainMenu => 'Menu principal';

  @override
  String get fullScreen => 'Tela cheia';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Abrir';

  @override
  String get openInFiles => 'Abrir em Arquivos';

  @override
  String get pathActions => 'Ações do caminho';

  @override
  String get outline => 'Estrutura';

  @override
  String get overwrite => 'Sobrescrever';

  @override
  String get paste => 'Colar';

  @override
  String get pasteWithoutFormatting => 'Colar sem formatar';

  @override
  String get reading => 'Leitura';

  @override
  String get removeFromRecent => 'Remover dos recentes';

  @override
  String get recent => 'Recentes';

  @override
  String get redo => 'Refazer';

  @override
  String get save => 'Salvar';

  @override
  String get search => 'Pesquisar';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get settings => 'Configurações';

  @override
  String get source => 'Código-fonte';

  @override
  String get split => 'Dividido';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theme => 'Tema';

  @override
  String get appLanguage => 'Idioma';

  @override
  String get systemLanguage => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageNorwegian => 'Norsk bokmål';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEstonian => 'Eesti';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get toggleSidebar => 'Painel lateral';

  @override
  String get topLeft => 'Canto superior esquerdo';

  @override
  String get topRight => 'Canto superior direito';

  @override
  String get undo => 'Desfazer';

  @override
  String get validate => 'Validar';

  @override
  String get validation => 'Validação';

  @override
  String get viewMode => 'Modo de exibição';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Imagens';

  @override
  String get openMarkdownFile => 'Abrir arquivo Markdown';

  @override
  String get markdownFileExtensions => '.md ou .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Abrir pasta ou projeto Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Pasta Markdown ou projeto compatível com Writerside';

  @override
  String get noOpenFile => 'Nenhum arquivo aberto';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Excluir o item selecionado em Arquivos ou remover o tópico selecionado do sumário';

  @override
  String get shortcutGroupGeneral => 'Geral';

  @override
  String get shortcutNewDocument => 'Criar';

  @override
  String get shortcutNewDocumentDescription =>
      'Criar arquivo Markdown ou projeto Writerside';

  @override
  String get shortcutOpenDescription =>
      'Abrir um arquivo Markdown, uma pasta ou um projeto Writerside';

  @override
  String get shortcutSaveDescription => 'Salvar o documento atual';

  @override
  String get shortcutSearchDescription =>
      'Pesquisar no espaço de trabalho atual';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Mostrar esta referência de atalhos de teclado';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Abrir a referência de sintaxe';

  @override
  String get shortcutSettingsDescription =>
      'Abrir as configurações do BusyMark';

  @override
  String get shortcutNextTab => 'Próxima guia';

  @override
  String get shortcutNextTabDescription => 'Ir para a próxima guia aberta';

  @override
  String get shortcutPreviousTab => 'Guia anterior';

  @override
  String get shortcutPreviousTabDescription => 'Ir para a guia aberta anterior';

  @override
  String get shortcutCloseTab => 'Fechar guia';

  @override
  String get shortcutCloseTabDescription => 'Fechar a guia ativa';

  @override
  String get shortcutCloseAllTabs => 'Fechar todas as guias';

  @override
  String get shortcutCloseAllTabsDescription => 'Fechar todas as guias abertas';

  @override
  String get shortcutGroupTextEditing => 'Edição de texto';

  @override
  String get shortcutSelectAllDescription =>
      'No modo Código-fonte, selecionar todo o texto; no modo Editor, pressionar duas vezes para selecionar todos os blocos';

  @override
  String get shortcutCutDescription => 'Recortar o texto selecionado';

  @override
  String get shortcutCopyDescription => 'Copiar o texto selecionado';

  @override
  String get shortcutPasteDescription => 'Colar da área de transferência';

  @override
  String get shortcutPastePlainTextDescription =>
      'Colar o texto da área de transferência sem formatação';

  @override
  String get shortcutUndoDescription => 'Desfazer a última edição';

  @override
  String get shortcutRedoDescription => 'Refazer a última edição desfeita';

  @override
  String get shortcutInsertIndentation => 'Inserir recuo';

  @override
  String get shortcutInsertIndentationDescription =>
      'Inserir recuo na posição do cursor';

  @override
  String get shortcutOutdentSource => 'Diminuir recuo do código-fonte';

  @override
  String get shortcutOutdentSourceDescription =>
      'Remover um nível de recuo no modo Código-fonte';

  @override
  String get shortcutEscape =>
      'Fechar a pesquisa ou limpar a seleção de blocos';

  @override
  String get shortcutEscapeDescription =>
      'Fechar a pesquisa do espaço de trabalho ou limpar uma seleção de blocos no modo Editor';

  @override
  String get shortcutGroupFormatting => 'Formatação';

  @override
  String get shortcutBoldDescription => 'Alternar negrito no texto selecionado';

  @override
  String get shortcutItalicDescription =>
      'Alternar itálico no texto selecionado';

  @override
  String get shortcutUnderlineDescription =>
      'Alternar sublinhado no texto selecionado';

  @override
  String get shortcutLinkDescription => 'Inserir ou editar um link';

  @override
  String get shortcutInlineCodeDescription =>
      'Alternar código embutido no texto selecionado';

  @override
  String get shortcutStrikethroughDescription =>
      'Alternar tachado no texto selecionado';

  @override
  String get shortcutGroupBlocks => 'Blocos';

  @override
  String get shortcutParagraphDescription =>
      'Definir o bloco atual como parágrafo';

  @override
  String get shortcutHeading1Description =>
      'Definir o bloco atual como Título 1';

  @override
  String get shortcutHeading2Description =>
      'Definir o bloco atual como Título 2';

  @override
  String get shortcutHeading3Description =>
      'Definir o bloco atual como Título 3';

  @override
  String get shortcutHeading4Description =>
      'Definir o bloco atual como Título 4';

  @override
  String get shortcutHeading5Description =>
      'Definir o bloco atual como Título 5';

  @override
  String get shortcutHeading6Description =>
      'Definir o bloco atual como Título 6';

  @override
  String get shortcutGroupLists => 'Listas';

  @override
  String get numberedList => 'Lista numerada';

  @override
  String get shortcutNumberedListDescription =>
      'Alternar formatação de lista numerada';

  @override
  String get bulletedList => 'Lista com marcadores';

  @override
  String get shortcutBulletedListDescription =>
      'Alternar formatação de lista com marcadores';

  @override
  String get checklist => 'Lista de verificação';

  @override
  String get shortcutChecklistDescription =>
      'Alternar formatação de lista de verificação';

  @override
  String get shortcutGroupSidebar => 'Barra lateral';

  @override
  String get sidebarViewMenu => 'Visualização da barra lateral';

  @override
  String get createMarkdownFile => 'Criar arquivo Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Iniciar um documento Markdown local não salvo';

  @override
  String get createWritersideProject => 'Criar projeto Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Iniciar um projeto local compatível com Writerside';

  @override
  String get defaultProjectName => 'Documentação';

  @override
  String get defaultInstanceName => 'Guia do usuário';

  @override
  String get defaultStartTopicTitle => 'Primeiros passos';

  @override
  String get projectName => 'Nome do projeto';

  @override
  String get directoryName => 'Nome do diretório';

  @override
  String get instanceName => 'Nome da instância';

  @override
  String get instanceId => 'ID da instância';

  @override
  String get startTopicTitle => 'Título do tópico inicial';

  @override
  String get location => 'Local';

  @override
  String get projectNameRequired => 'O nome do projeto é obrigatório.';

  @override
  String get directoryNameRequired => 'O nome do diretório é obrigatório.';

  @override
  String get useSingleSafeDirectoryName =>
      'Use um único nome de diretório seguro.';

  @override
  String get useLowercaseIdentifier =>
      'Use um identificador em minúsculas com letras, números, sublinhados ou hifens.';

  @override
  String get startTopicTitleRequired =>
      'O título do tópico inicial é obrigatório.';

  @override
  String get createWritersideProjectFailed =>
      'Não foi possível criar o projeto Writerside.';

  @override
  String get settingsTitle => 'Configurações do BusyMark';

  @override
  String get autoSave => 'Salvamento automático';

  @override
  String get autoSaveDescription =>
      'Salva automaticamente as alterações do arquivo após um curto período de inatividade.';

  @override
  String get wordWrap => 'Quebra de linha';

  @override
  String get editorFontSize => 'Tamanho da fonte do editor';

  @override
  String get validateOnEdit => 'Validar ao editar';

  @override
  String get clearRecentWorkspaces => 'Limpar espaços de trabalho recentes';

  @override
  String get editingButtonsPosition => 'Posição dos botões de edição';

  @override
  String get editingButtonsPositionDescription =>
      'Escolha onde os botões flutuantes de edição WYSIWYG aparecem.';

  @override
  String get editingButtonsDirection => 'Orientação dos botões de edição';

  @override
  String get editingButtonsDirectionDescription =>
      'Escolha se os botões flutuantes de edição WYSIWYG ficam dispostos horizontalmente ou verticalmente.';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get privacy => 'Privacidade';

  @override
  String get allowRemoteImages => 'Carregar imagens remotas';

  @override
  String get allowRemoteImagesDescription =>
      'Permitir que a pré-visualização do Markdown e o editor carreguem imagens de URLs HTTP e HTTPS.';

  @override
  String get clearRemoteImagePermissions =>
      'Limpar permissões de imagens remotas';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Esquecer os espaços de trabalho autorizados a carregar imagens remotas.';

  @override
  String get clearGitWorkspaceTrust =>
      'Limpar espaços de trabalho confiáveis para o Git';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Perguntar antes de ativar recursos do Git em espaços de trabalho considerados confiáveis anteriormente.';

  @override
  String get settingsWindowSectionTitle => 'Janela';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Reabrir o espaço de trabalho anterior ao iniciar';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Abra o espaço de trabalho e as abas da sessão anterior quando o BusyMark iniciar.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirmar antes de fechar com alterações não salvas';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Perguntar antes de fechar o BusyMark quando documentos tiverem alterações não salvas.';

  @override
  String get closeUnsavedChangesTitle => 'Alterações não salvas';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Este documento tem alterações não salvas. Salvar as alterações antes de fechar o BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos têm alterações não salvas. Salvar as alterações antes de fechar o BusyMark?',
      one:
          '1 documento tem alterações não salvas. Salvar as alterações antes de fechar o BusyMark?',
      zero: 'Salvar as alterações antes de fechar o BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Cancelar';

  @override
  String get closeUnsavedChangesDiscard => 'Descartar';

  @override
  String get closeUnsavedChangesSave => 'Salvar';

  @override
  String get currentFile => 'arquivo atual';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Você tem alterações não salvas em $fileName. Salvá-las antes de continuar?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos com alterações não salvas. Deseja salvá-los antes de continuar?',
      one:
          'Há 1 documento com alterações não salvas. Deseja salvá-lo antes de continuar?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Arquivo alterado no disco';

  @override
  String get fileChangedOnDiskMessage =>
      'Este arquivo foi alterado no disco desde que foi aberto. Sobrescrever?';

  @override
  String get untitledMarkdownFileName => 'Sem título.md';

  @override
  String get unorderedList => 'Lista não ordenada';

  @override
  String get orderedList => 'Lista ordenada';

  @override
  String get taskList => 'Lista de tarefas';

  @override
  String get toggleTaskChecked => 'Marcar/desmarcar tarefa';

  @override
  String get indentListItem => 'Recuar item da lista';

  @override
  String get outdentListItem => 'Remover recuo do item da lista';

  @override
  String get blockquote => 'Citação em bloco';

  @override
  String get codeBlock => 'Bloco de código';

  @override
  String get codeBlockLanguage => 'Linguagem do bloco de código';

  @override
  String get image => 'Imagem';

  @override
  String get video => 'Vídeo';

  @override
  String get openVideo => 'Reproduzir vídeo';

  @override
  String get pauseVideo => 'Pausar vídeo';

  @override
  String get videoUnavailable => 'Vídeo indisponível';

  @override
  String get videoPreview => 'Pré-visualização do vídeo';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'O vídeo não tem o atributo src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Fonte de vídeo não suportada: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'O arquivo de vídeo não existe: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'A imagem de pré-visualização do vídeo não existe: $preview';
  }

  @override
  String get inlineImage => 'Imagem embutida';

  @override
  String get table => 'Tabela';

  @override
  String get htmlBlock => 'Bloco HTML';

  @override
  String get htmlContentDefault => 'Conteúdo HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Inserir ou editar um bloco HTML';

  @override
  String get renderedHtml => 'HTML renderizado';

  @override
  String get editHtml => 'Editar HTML';

  @override
  String get htmlSource => 'Código-fonte HTML';

  @override
  String get thematicBreak => 'Separador temático';

  @override
  String get bold => 'Negrito';

  @override
  String get italic => 'Itálico';

  @override
  String get underline => 'Sublinhado';

  @override
  String get strikethrough => 'Tachado';

  @override
  String get inlineCode => 'Código embutido';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Quebra de linha forçada';

  @override
  String get textStyle => 'Estilo de texto';

  @override
  String get paragraph => 'Parágrafo';

  @override
  String get heading1 => 'Título 1';

  @override
  String get heading2 => 'Título 2';

  @override
  String get heading3 => 'Título 3';

  @override
  String get heading4 => 'Título 4';

  @override
  String get heading5 => 'Título 5';

  @override
  String get heading6 => 'Título 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Excluir tabela';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Coluna $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Inserir coluna à esquerda';

  @override
  String get insertColumnRight => 'Inserir coluna à direita';

  @override
  String get deleteColumn => 'Excluir coluna';

  @override
  String get tableAlignmentUnspecified => 'Alinhamento: não especificado';

  @override
  String get tableAlignmentLeft => 'Alinhamento: esquerda';

  @override
  String get tableAlignmentCenter => 'Alinhamento: centro';

  @override
  String get tableAlignmentRight => 'Alinhamento: direita';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Linha $rowNumber';
  }

  @override
  String get insertRowAbove => 'Inserir linha acima';

  @override
  String get insertRowBelow => 'Inserir linha abaixo';

  @override
  String get deleteRow => 'Excluir linha';

  @override
  String get tableHeaderHint => 'Cabeçalho';

  @override
  String get tableCellHint => 'Célula';

  @override
  String get language => 'Linguagem';

  @override
  String get hideEditingButtons => 'Ocultar botões de edição';

  @override
  String get showEditingButtons => 'Mostrar botões de edição';

  @override
  String get altText => 'Texto alternativo';

  @override
  String get editorPlaceholderText => 'texto';

  @override
  String get editorPlaceholderCode => 'código';

  @override
  String get editorPlaceholderAltText => 'texto alternativo';

  @override
  String get describeTheImage => 'Descreva a imagem';

  @override
  String get columns => 'Colunas';

  @override
  String get rows => 'Linhas';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Cabeçalho $columnNumber';
  }

  @override
  String get tableCellDefault => 'Célula';

  @override
  String get noImageSource => 'Nenhuma origem de imagem';

  @override
  String get remoteImageBlocked => 'Imagem remota bloqueada';

  @override
  String get remoteImageBlockedTooltip =>
      'Escolha se o BusyMark pode carregar imagens remotas.';

  @override
  String get remoteImagesBlockedTitle => 'As imagens remotas estão bloqueadas';

  @override
  String get remoteImagesBlockedMessage =>
      'Este documento faz referência a imagens da Internet. Carregá-las pode revelar informações de rede ao servidor que as hospeda.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Carregar neste espaço de trabalho';

  @override
  String get alwaysLoadRemoteImages => 'Sempre carregar imagens remotas';

  @override
  String get hideSidebar => 'Ocultar painel lateral';

  @override
  String get showSidebar => 'Mostrar painel lateral';

  @override
  String get showPreview => 'Mostrar pré-visualização';

  @override
  String get hidePreview => 'Ocultar pré-visualização';

  @override
  String get workspaceKindUnsavedMarkdown => 'Arquivo Markdown não salvo';

  @override
  String get workspaceKindSingleMarkdown => 'Arquivo Markdown único';

  @override
  String get workspaceKindMarkdownFolder => 'Pasta Markdown';

  @override
  String get workspaceKindWritersideModule => 'Módulo Writerside';

  @override
  String get problems => 'Problemas';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnósticos',
      one: '1 diagnóstico',
      zero: 'Nenhum diagnóstico',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Arquivos';

  @override
  String get toc => 'TOC';

  @override
  String get tocActions => 'Ações do sumário';

  @override
  String get markdownUnsaved => 'Markdown - não salvo';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Nenhum arquivo';

  @override
  String get newFile => 'Novo arquivo';

  @override
  String get noWritersideToc => 'Nenhum TOC do Writerside';

  @override
  String get tocSection => 'Seção do TOC';

  @override
  String get newTopic => 'Novo tópico';

  @override
  String get newChildTopic => 'Novo subtópico';

  @override
  String get newSiblingTopic => 'Novo tópico no mesmo nível';

  @override
  String get renameTopicFile => 'Renomear arquivo do tópico';

  @override
  String get topicPlacement => 'Posição no TOC';

  @override
  String get tocRoot => 'Na raiz do TOC';

  @override
  String get afterSelectedTopic => 'Após o tópico selecionado';

  @override
  String get insideSelectedTopic => 'Dentro do tópico selecionado';

  @override
  String get pasteAfterTopic => 'Colar depois';

  @override
  String get pasteAsChildTopic => 'Colar como subtópico';

  @override
  String get removeFromToc => 'Remover do TOC';

  @override
  String get confirmRemoveFromTocTitle => 'Remover do TOC?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Remover $name deste TOC? O arquivo do tópico será mantido.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Excluir o arquivo do tópico?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Excluir $name e removê-lo de todos os TOCs? Isso não pode ser desfeito.';
  }

  @override
  String get safeDeleteTopicFile =>
      'Excluir o arquivo do tópico com segurança…';

  @override
  String get removeTocElement => 'Remover elemento do TOC';

  @override
  String get reviewUsages => 'Revisar usos';

  @override
  String get deleteTopicFile => 'Excluir arquivo do tópico';

  @override
  String get removeAction => 'Remover';

  @override
  String topicRemovalSummary(String topic) {
    return 'Remova “$topic” da instância selecionada. O arquivo do tópico será mantido.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Exclua “$topic” e atualize com segurança as referências a ele em todo este projeto Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count tópicos filhos subirão um nível.',
      one: 'O tópico filho subirá um nível.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Este tópico é usado como página inicial de uma instância. Revise os usos dele e atribua outra página inicial antes de continuar.';

  @override
  String topicUsagesCount(int count) {
    return 'Usos ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Não foram encontradas referências que deixariam de funcionar.';

  @override
  String get topicUsagesFound =>
      'O BusyMark encontrou as seguintes referências a este tópico.';

  @override
  String get topicUsageTocElements => 'Elementos do TOC';

  @override
  String get topicUsageStartPages => 'Páginas iniciais';

  @override
  String get topicUsageTopicLinks => 'Links para tópicos';

  @override
  String get topicUsageIncludes => 'Inclusões';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usos',
      one: '1 uso',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Opções de refatoração';

  @override
  String get updateUsagesAutomatically => 'Atualizar usos automaticamente';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Remova referências dos TOCs e inclusões e preserve o texto dos links.';

  @override
  String get manualUsageUpdatesRequired =>
      'Alguns usos exigem alterações manuais antes desta refatoração.';

  @override
  String get setRedirectTo => 'Redirecionar para';

  @override
  String get noRedirectDescription =>
      'Não redirecionar a página publicada antiga.';

  @override
  String get redirectTarget => 'Destino do redirecionamento';

  @override
  String get remainingUsagesBlockRemoval =>
      'Revise e atualize os usos restantes antes de continuar ou ative as atualizações automáticas quando estiverem disponíveis.';

  @override
  String usagesOfTopic(String topic) {
    return 'Usos de $topic';
  }

  @override
  String get noUsagesFound => 'Nenhum uso encontrado.';

  @override
  String get outsideSelectedInstance => 'Fora da instância selecionada';

  @override
  String get doRefactor => 'Refatorar';

  @override
  String get orphanTopicTitle => 'O arquivo do tópico não é mais usado';

  @override
  String get keepTopicFile => 'Manter o arquivo do tópico';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” não é mais usado em nenhum lugar deste projeto Writerside. Exclua o arquivo ou mantenha-o para uso em outra instância.';
  }

  @override
  String get defaultNewTopicTitle => 'Novo tópico';

  @override
  String get topicTitle => 'Título do tópico';

  @override
  String get fileName => 'Nome do arquivo';

  @override
  String get topicTitleRequired => 'O título do tópico é obrigatório.';

  @override
  String get fileNameRequired => 'O nome do arquivo é obrigatório.';

  @override
  String get rename => 'Renomear';

  @override
  String get confirmDeleteFileTitle => 'Excluir arquivo?';

  @override
  String get confirmDeleteFolderTitle => 'Excluir pasta?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Excluir $name? Isso não pode ser desfeito.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Excluir $name e todos os arquivos dentro dela? Isso não pode ser desfeito.';
  }

  @override
  String get useSingleSafeFileName => 'Use um único nome de arquivo seguro.';

  @override
  String useExpectedExtension(String extension) {
    return 'Use a extensão $extension para o formato selecionado.';
  }

  @override
  String get useIdentifierCharacters =>
      'Use letras, números, sublinhados ou hifens antes da extensão.';

  @override
  String get topicIdAlreadyExists => 'O ID do tópico já existe.';

  @override
  String get createWritersideTopicFailed =>
      'Não foi possível criar o tópico do Writerside.';

  @override
  String get noOutline => 'Sem estrutura';

  @override
  String expandKind(String kind) {
    return 'Expandir $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Recolher $kind';
  }

  @override
  String get foldKindSection => 'seção';

  @override
  String get foldKindList => 'lista';

  @override
  String get foldKindQuote => 'citação';

  @override
  String get foldKindTag => 'tag';

  @override
  String get sourceSearchPreviousMatch => 'Correspondência anterior';

  @override
  String get sourceSearchNextMatch => 'Próxima correspondência';

  @override
  String get sourceSearchCaseSensitive =>
      'Diferenciar maiúsculas de minúsculas';

  @override
  String get sourceSearchWholeWord => 'Palavra inteira';

  @override
  String get sourceSearchRegex => 'Expressão regular';

  @override
  String get sourceSearchReplacement => 'Substituir por';

  @override
  String get sourceSearchReplaceCurrent => 'Substituir correspondência atual';

  @override
  String get sourceSearchReplaceAndFindNext => 'Substituir e localizar próximo';

  @override
  String get sourceSearchReplaceAll => 'Substituir tudo';

  @override
  String get workspaceReplace => 'Substituir no espaço de trabalho';

  @override
  String get reviewReplacements => 'Revisar substituições';

  @override
  String get applyReplacements => 'Aplicar substituições';

  @override
  String get skippedFiles => 'Arquivos ignorados';

  @override
  String get workspaceReplaceDirtyBuffer => 'Conteúdo não salvo do editor';

  @override
  String get workspaceReplaceDiskContent => 'Conteúdo salvo no disco';

  @override
  String selectFileMatches(int count) {
    return 'Selecionar todas as $count correspondências';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Foram substituídas $matches correspondências em $files arquivos; $skipped ignoradas.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Quebra de linha final';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Sem quebra de linha final';
  }

  @override
  String get normalizeLineEndings => 'Normalizar finais de linha';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Este documento contém finais de linha mistos. Escolha um formato.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName usa finais de linha mistos. Escolha o formato antes de substituir.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Um arquivo grande demais foi ignorado.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Um arquivo que não pôde ser lido foi ignorado.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Um arquivo que não é UTF-8 válido foi ignorado.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'A prévia de substituições foi truncada.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Um arquivo alterado após a prévia foi ignorado.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Um buffer do editor alterado após a prévia foi ignorado.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Escolha a normalização LF ou CRLF antes de substituir.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'A reversão foi interrompida porque o arquivo foi alterado simultaneamente. Algumas substituições podem permanecer; o conteúdo deslocado foi preservado no caminho abaixo.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Nenhuma substituição foi aplicada porque o conjunto revisado não pôde ser salvo com segurança.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Alterações externas — $fileName';
  }

  @override
  String get externalFileDeleted => 'Este arquivo foi excluído do disco.';

  @override
  String get externalFileChanged =>
      'Este arquivo mudou no disco enquanto você tem alterações não salvas.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'O conteúdo não salvo de $fileName foi recuperado. Revise-o e depois salve, salve como ou descarte-o.';
  }

  @override
  String get compare => 'Comparar';

  @override
  String get reloadFromDisk => 'Recarregar do disco';

  @override
  String get keepMine => 'Manter minha versão';

  @override
  String get saveAs => 'Salvar como';

  @override
  String get sourceSearchInvalidRegex => 'Expressão regular inválida';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Arquivo grande: o realce e o recolhimento estão pausados';

  @override
  String get nothingToRead => 'Nenhum conteúdo para ler';

  @override
  String get admonition => 'Bloco de destaque';

  @override
  String get quote => 'Citação';

  @override
  String get note => 'Observação';

  @override
  String get tip => 'Dica';

  @override
  String get warning => 'Aviso';

  @override
  String get tabs => 'Guias';

  @override
  String get tab => 'Guia';

  @override
  String get procedure => 'Procedimento';

  @override
  String get step => 'Etapa';

  @override
  String get topic => 'Tópico';

  @override
  String get chapter => 'Capítulo';

  @override
  String couldNotOpenTarget(String target) {
    return 'Não foi possível abrir $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Destino do link não encontrado: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Não é possível abrir este tipo de arquivo no editor';

  @override
  String anchorNotFound(String anchor) {
    return 'Âncora não encontrada: $anchor';
  }

  @override
  String get noProblemsFound => 'Nenhum problema encontrado';

  @override
  String get noResults => 'Nenhum resultado';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - linha $lineNumber';
  }

  @override
  String get untitledResult => 'Resultado sem título';

  @override
  String get documentKindMarkdownFile => 'Arquivo Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Tópico Markdown do Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Tópico XML do Writerside';

  @override
  String get documentKindWritersideTree => 'Árvore do Writerside';

  @override
  String get documentKindConfigurationFile => 'Arquivo de configuração';

  @override
  String get documentKindVariablesFile => 'Arquivo de variáveis';

  @override
  String get documentKindCategoriesFile => 'Arquivo de categorias';

  @override
  String get documentKindResourceFile => 'Arquivo de recursos';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Falha ao abrir: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Não foi possível criar o projeto Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Não foi possível criar o tópico do Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Não foi possível abrir o arquivo: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Escolha onde salvar este arquivo Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Salvamento bloqueado: o arquivo foi alterado no disco.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Falha na operação de arquivo: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Falha na validação: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos sem salvamento recuperados. Revise cada um antes de salvar ou descartar.',
      one:
          '1 documento sem salvamento recuperado. Revise antes de salvar ou descartar.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count registros de recuperação danificados não puderam ser restaurados. Os registros de recuperação válidos permanecem disponíveis.',
      one:
          '1 registro de recuperação danificado não pôde ser restaurado. O arquivo de recuperação original foi preservado para inspeção.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'O caminho não existe: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'O diretório de destino já existe e não está vazio: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'O caminho de destino já existe e não é um diretório: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'O arquivo gerado já existe: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'O diretório pai é obrigatório.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'O diretório pai não existe: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'O diretório não existe: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'O caminho já existe: $path';
  }

  @override
  String get errorFileNameRequired => 'O nome do arquivo é obrigatório.';

  @override
  String get errorFileNameUnsafe =>
      'O nome do arquivo deve ser um único segmento de caminho seguro.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Não é possível mover uma pasta para dentro dela mesma.';

  @override
  String get errorFileOperationOutsideRoot =>
      'A operação de arquivo deve permanecer dentro do espaço de trabalho.';

  @override
  String get errorFileOperationRoot =>
      'A raiz do espaço de trabalho não pode ser alterada pela árvore de arquivos.';

  @override
  String get errorProjectNameRequired => 'O nome do projeto é obrigatório.';

  @override
  String get errorDirectoryNameRequired => 'O nome do diretório é obrigatório.';

  @override
  String get errorDirectoryNameUnsafe =>
      'O nome do diretório deve ser um único segmento de caminho seguro.';

  @override
  String get errorInstanceIdInvalid =>
      'O ID da instância deve começar com uma letra minúscula e conter apenas letras minúsculas, números, sublinhados e hifens.';

  @override
  String get errorTopicFileInvalid =>
      'O nome do arquivo do tópico deve ser um nome de arquivo Markdown sem separadores de caminho.';

  @override
  String get errorTopicTitleRequired => 'O título do tópico é obrigatório.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'A raiz do módulo Writerside não existe: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Um módulo Writerside deve estar aberto para criar um tópico.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'O módulo Writerside não tem uma árvore de instância.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'O arquivo de árvore do Writerside não existe: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'O ID do tópico \"$topicId\" já existe neste módulo de ajuda.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'O arquivo do tópico já existe: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'O tópico de referência não está presente na árvore selecionada: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'A entrada selecionada do TOC não existe mais.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Uma entrada do TOC não pode ser movida para dentro de si mesma nem de um de seus descendentes.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'O tópico inicial $topic não pode ser excluído. Escolha primeiro outra página inicial.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Use a exclusão segura para arquivos de tópicos do Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Não foi possível concluir a verificação dos usos do tópico. Nenhum arquivo foi alterado.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Alguns usos do tópico ainda precisam de atenção. Revise-os antes de continuar.';

  @override
  String get errorWritersideRedirectInvalid =>
      'O destino de redirecionamento selecionado não é mais válido. Selecione-o novamente.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Não foi possível reverter completamente a remoção do tópico. Revise estes caminhos antes de continuar: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'A raiz dos tópicos deve ser um diretório relativo seguro.';

  @override
  String get errorTopicFileNameUnsafe =>
      'O nome do arquivo do tópico deve ser um único segmento de caminho seguro.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'A extensão do arquivo do tópico deve corresponder ao formato selecionado ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'O nome do arquivo do tópico deve conter apenas letras, números, sublinhados e hifens.';

  @override
  String errorUnknown(String code) {
    return 'Erro desconhecido: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Não foi possível ler os metadados do arquivo: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Espaço de trabalho grande detectado. Alguns arquivos foram ignorados para manter o aplicativo responsivo.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Não foi possível inspecionar a entrada do espaço de trabalho: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'O arquivo excede o limite beta de análise automática.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Não foi possível ler o arquivo Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'O bloco de atributos de título do Writerside está malformado.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID de título duplicado \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Títulos H1 adicionais no nível superior são tratados como capítulos.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'O tópico Markdown do Writerside não tem H1 nem título no front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'O tópico XML não tem título.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'O tópico \"$fileName\" não tem título.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'O front matter não foi fechado.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Elemento HTML inseguro.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'O destino do link não existe: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'A âncora \"$anchor\" não existe.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'A imagem \"$destination\" não tem texto alternativo.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'A imagem não existe: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML inválido: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'A raiz do arquivo writerside.cfg deve ser <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'A declaração de snippets está sem o atributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'A declaração de instance-groups está sem o atributo src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Modo de keymaps não suportado: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'A declaração de instância está sem o atributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'O arquivo writerside.cfg não registra uma instância.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'A raiz do arquivo .tree deve ser <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'O perfil da instância está sem o atributo id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'O nome-base do arquivo .tree não corresponde ao ID da instância \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'A instância que não é de biblioteca não tem start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'A página inicial \"$startPage\" não existe.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'O tópico \"$topic\" aparece mais de uma vez no TOC desta instância.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'A declaração de variável deve ter nome e valor.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'A variável \"$name\" é declarada mais de uma vez.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'A categoria está sem o atributo id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'A categoria \"$id\" é declarada mais de uma vez.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'A ordem da categoria \"$order\" foi declarada mais de uma vez.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'A raiz do arquivo .topic deve ser <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'A raiz do tópico XML está sem o atributo id.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'O ID raiz do tópico XML \"$id\" deve corresponder ao nome do arquivo \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'O ID do elemento \"$elementId\" aparece mais de uma vez.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> está sem o atributo href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'O modo Writerside requer o arquivo writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'O diretório configurado para a compilação está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'O diretório de especificações de API configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'O diretório de snippets configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'O arquivo de variáveis configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'O arquivo de categorias configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'O arquivo de grupos de instâncias configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'A árvore de instância registrada \"$source\" não existe.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Não foi possível ler o arquivo do tópico: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'O diretório de tópicos padrão está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'O diretório de tópicos configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'O diretório de imagens configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'O ID do elemento \"$id\" aparece mais de uma vez.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'O TOC faz referência ao tópico ausente \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'O href externo \"$href\" é inválido.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'A variável \"%$name%\" não foi declarada.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'O link para o tópico \"$destination\" não pode ser resolvido.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'A âncora \"$anchor\" não existe em \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> está sem o atributo from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'A origem da inclusão \"$from\" não existe.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'O elemento incluído \"$elementId\" não existe em \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'A categoria seealso \"$ref\" não foi declarada.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'A referência de tópico \"$reference\" é ambígua.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Diagnóstico desconhecido: $code';
  }

  @override
  String get close => 'Fechar';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Diff do Git';

  @override
  String get gitShowDiff => 'Mostrar diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'anterior $oldRange → novo $newRange';
  }

  @override
  String get gitDiffNoLines => 'sem linhas';

  @override
  String get gitUnavailableTitle => 'Git não está disponível';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Instale o Git ou configure o BusyMark para usar um executável do Git disponível. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Confiar neste espaço de trabalho para o Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Os repositórios Git podem executar programas por meio de hooks, filtros e outras configurações. Confie neste espaço de trabalho antes que o BusyMark leia os dados do repositório ou ative ações do Git.';

  @override
  String get gitTrustWorkspace => 'Confiar no espaço de trabalho';

  @override
  String get gitNotRepositoryTitle => 'Não é um repositório Git';

  @override
  String get gitNotRepositoryMessage =>
      'Este espaço de trabalho não está em um repositório Git.';

  @override
  String get gitInitializeRepository => 'Inicializar repositório';

  @override
  String get gitDetachedHead => 'HEAD desanexado';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Desanexado em $commit';
  }

  @override
  String get gitNoUpstream => 'Sem upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits não enviados',
      one: '1 commit não enviado',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits para obter',
      one: '1 commit para obter',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Limpo';

  @override
  String get gitConflicts => 'Conflitos';

  @override
  String get gitChanges => 'Alterações';

  @override
  String get gitStaged => 'Preparados';

  @override
  String get gitUnstaged => 'Não preparados';

  @override
  String get gitHistory => 'Histórico';

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitActions => 'Ações do Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Buscar';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Adicionar arquivo ao índice';

  @override
  String get gitRemoveFromCommit => 'Remover arquivo do índice';

  @override
  String get gitDiscard => 'Descartar';

  @override
  String get gitOpenFile => 'Abrir arquivo';

  @override
  String get gitMarkResolved => 'Marcar como resolvido';

  @override
  String get gitUntracked => 'Arquivos não rastreados';

  @override
  String get gitCommitMessage => 'Mensagem de commit';

  @override
  String get gitCommitSelectedFiles => 'Arquivos selecionados';

  @override
  String get gitCommitNoSelectedFiles =>
      'Adicione pelo menos um arquivo ao índice antes de criar o commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos preparados',
      one: '1 arquivo preparado',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Fora do espaço de trabalho';

  @override
  String get gitCommitMessageRequired => 'Digite uma mensagem de commit.';

  @override
  String get gitCreateBranch => 'Criar branch';

  @override
  String get gitNewBranch => 'Nova branch';

  @override
  String get gitBranchName => 'Nome da branch';

  @override
  String get gitSwitchBranch => 'Trocar';

  @override
  String get gitNoChanges => 'Nenhuma alteração';

  @override
  String get gitNoHistory => 'Nenhum histórico';

  @override
  String get gitNoBranches => 'Nenhuma branch';

  @override
  String get gitNoDiff => 'Nenhum diff para exibir';

  @override
  String get gitBinaryFile =>
      'Arquivo binário. O BusyMark não exibe patches binários.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Arquivo binário ($size bytes). O BusyMark não exibe patches binários.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'As alterações não salvas do editor não são incluídas até serem salvas.';

  @override
  String get gitConfirmDiscardTitle => 'Descartar alterações do Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Todas as mudanças staged e unstaged nos arquivos rastreados selecionados serão restauradas para HEAD.',
      one:
          'Todas as mudanças staged e unstaged no arquivo selecionado rastreado serão restauradas para HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os arquivos não rastreados selecionados serão excluídos.',
      one: 'O arquivo não rastreado selecionado será excluído.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Os arquivos selecionados serão restaurados ou excluídos de acordo com o status do Git.',
      one:
          'O arquivo selecionado será restaurado ou excluído de acordo com o status do Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Trocar para $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'O BusyMark recarregará o espaço de trabalho do disco depois que o Git trocar de branch.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Definir branch upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Esta branch não tem upstream. O BusyMark pode enviar $branch e definir seu upstream quando houver exatamente um remoto configurado.';
  }

  @override
  String get gitProjectHistory => 'Histórico do projeto';

  @override
  String get gitFileHistory => 'Histórico do arquivo';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'O histórico do arquivo requer um arquivo Markdown aberto.';

  @override
  String get gitLoadMore => 'Carregar mais';

  @override
  String get gitChangesInCommit => 'Alterações neste commit';

  @override
  String get gitCompareWithCurrent => 'Comparar com a versão atual';

  @override
  String get gitRestoreVersion => 'Restaurar esta versão';

  @override
  String get gitConfirmRestoreTitle => 'Restaurar esta versão do arquivo?';

  @override
  String get gitConfirmRestoreMessage =>
      'O BusyMark substituirá o arquivo atual da árvore de trabalho pela versão selecionada do commit. O arquivo restaurado permanecerá não preparado.';

  @override
  String get gitCommitActions => 'Ações do commit';

  @override
  String get gitResetCurrentBranchToHere => 'Redefinir a branch atual aqui…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Redefinir $branch para $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Isto move a branch $branch para o commit $commit. Escolha como o Git deve atualizar o índice e a árvore de trabalho.';
  }

  @override
  String get gitReset => 'Redefinir';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Mover apenas a branch. Manter o índice e a árvore de trabalho inalterados; as diferenças em relação ao commit selecionado permanecem preparadas.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Mover a branch e redefinir o índice. Manter a árvore de trabalho inalterada, deixando as diferenças não preparadas.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Mover a branch e redefinir o índice e a árvore de trabalho. As alterações rastreadas são descartadas; os arquivos não rastreados que bloqueiam a operação podem ser excluídos.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Mover a branch e redefinir os arquivos rastreados, preservando as alterações locais. O Git aborta se essas alterações entrarem em conflito com a redefinição.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Ações do arquivo';

  @override
  String get actions => 'Ações';

  @override
  String get gitStatusAdded => 'Adicionado';

  @override
  String get gitStatusDeleted => 'Excluído';

  @override
  String get gitStatusRenamed => 'Renomeado';

  @override
  String get gitStatusCopied => 'Copiado';

  @override
  String get gitStatusUntracked => 'Não rastreado';

  @override
  String get gitStatusConflicted => 'Em conflito';

  @override
  String get gitStatusIgnored => 'Ignorado';

  @override
  String get gitStatusTypeChanged => 'Tipo alterado';

  @override
  String get gitStatusModified => 'Modificado';

  @override
  String get gitStatusUnknown => 'Desconhecido';

  @override
  String get gitErrorUnavailable => 'Git não está disponível.';

  @override
  String get gitErrorNotRepository =>
      'Este espaço de trabalho não é um repositório Git.';

  @override
  String get gitErrorUnsafePath =>
      'O BusyMark bloqueou um caminho Git inseguro.';

  @override
  String get gitErrorInvalidBranchName => 'Digite um nome de branch válido.';

  @override
  String get gitErrorNoRemote => 'Nenhum remoto Git está configurado.';

  @override
  String get gitErrorNoUpstream => 'Nenhuma branch upstream está configurada.';

  @override
  String get gitErrorMultipleRemotes =>
      'Há vários remotos configurados. Escolha um upstream fora desta versão do BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Salve ou descarte as alterações do editor do BusyMark antes de trocar de branch.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Salve ou descarte as alterações no editor do BusyMark antes de redefinir a branch atual.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Remova o arquivo do índice antes de restaurar uma versão anterior.';

  @override
  String get gitErrorResetDetachedHead =>
      'Alterne para uma branch antes de redefini-la.';

  @override
  String get gitErrorDiverged =>
      'A branch divergiu. Resolva o merge ou o rebase fora desta versão do BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'O Git precisa do nome e do e-mail do autor antes de criar um commit.';

  @override
  String get gitAuthorIdentityTitle => 'Identidade do autor do Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Informe a identidade que o Git deve registrar nos commits. O BusyMark irá salvá-la e tentar este commit novamente.';

  @override
  String get gitAuthorName => 'Nome';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Usar em todos os repositórios';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Quando instalado como Snap, isto se aplica aos repositórios abertos no BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Salvar e criar commit';

  @override
  String get gitErrorAuthentication => 'A autenticação do Git falhou.';

  @override
  String get gitErrorNetwork => 'A operação de rede do Git falhou.';

  @override
  String get gitErrorConflict => 'O Git relatou conflitos não resolvidos.';

  @override
  String get gitErrorCommandFailed => 'O comando Git falhou.';

  @override
  String get syntaxReference => 'Referência de sintaxe';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Blocos Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Estruturas de bloco compatíveis no código Markdown e na pré-visualização.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown em linha';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatação dentro de parágrafos, itens de lista e células de tabela.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Blocos de HTML bruto';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Tags HTML de bloco seguras renderizadas pelos widgets de pré-visualização do BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Tags de HTML bruto em linha';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Tags HTML em linha seguras renderizadas sem mostrar as tags literais.';

  @override
  String get syntaxReferenceSafety => 'Regras de segurança';

  @override
  String get syntaxReferenceSafetyDescription =>
      'O HTML bruto é analisado e higienizado antes da pré-visualização.';

  @override
  String get syntaxReferenceHeadings => 'Títulos';

  @override
  String get syntaxReferenceParagraphs => 'Parágrafos';

  @override
  String get syntaxReferenceLists => 'Listas';

  @override
  String get syntaxReferenceHtmlContainers => 'Contêineres';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Blocos de texto';

  @override
  String get syntaxReferenceHtmlFigures => 'Figuras e imagens';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Código pré-formatado';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Blocos expansíveis';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Listas de descrição';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tags de formatação';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tags de código em linha';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Tags de texto semântico';

  @override
  String get syntaxReferenceSanitizedPreview => 'Pré-visualização higienizada';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'O HTML permitido é convertido em blocos de pré-visualização do BusyMark e não é renderizado em um navegador.';

  @override
  String get syntaxReferenceSourcePreserved => 'Código-fonte preservado';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'HTML bruto não editado é salvo exatamente como texto fonte.';

  @override
  String get syntaxReferenceMarkdownInsideHtml => 'Markdown dentro de HTML';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Marcadores Markdown dentro de HTML bruto são exibidos como texto literal.';

  @override
  String get syntaxReferenceBlockedContent => 'Conteúdo ativo bloqueado';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Scripts, estilos, frames, formulários, SVG, MathML, eventos e atributos inseguros são bloqueados.';

  @override
  String get syntaxReferenceSafeUrls => 'Somente URLs seguras';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Links permitem http, https, mailto, tel, URLs relativas e fragmentos; esquemas inseguros são bloqueados.';

  @override
  String get syntaxReferenceCategory => 'Categoria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramas e API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matemática';

  @override
  String get syntaxReferenceExample => 'Exemplo';

  @override
  String get syntaxReferenceIdentifiers => 'Identificadores e aliases';

  @override
  String get syntaxReferenceScope => 'Escopo';

  @override
  String get syntaxReferenceLimitation => 'Limitação do BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Documentação oficial';

  @override
  String get syntaxReferenceScopeMarkdownAndWritersideMarkdown =>
      'Markdown comum e Markdown do Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Somente Markdown do Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Somente Markdown e XML do Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'As formas essenciais de Markdown que o BusyMark pode criar e visualizar.';

  @override
  String get syntaxReferenceParagraphExample => 'Um parágrafo de texto.';

  @override
  String get syntaxReferenceTableLimitation =>
      'As tabelas usam a sintaxe de barras verticais do GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dois espaços no fim da linha, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'O BusyMark aceita um subconjunto seguro e específico de HTML bruto no código Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Blocos cercados Mermaid, PlantUML, D2 e OpenAPI funcionam no código Markdown. Os identificadores não diferenciam maiúsculas de minúsculas, e o BusyMark preserva a grafia original.';

  @override
  String get syntaxReferenceMermaid => 'Mermaid';

  @override
  String get syntaxReferencePlantUml => 'PlantUML';

  @override
  String get syntaxReferenceD2 => 'D2';

  @override
  String get syntaxReferenceOpenApi => 'OpenAPI';

  @override
  String get syntaxReferenceOpenApiLimitation =>
      'Use conteúdo YAML ou JSON em um bloco cercado. O BusyMark não trata um documento YAML ou JSON completo qualquer como referência OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Blocos de código semânticos para diagramas';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'As formas semânticas code-block e src aceitam Mermaid, PlantUML e D2, não OpenAPI, e somente em projetos Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Origem de diagrama referenciada';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Os caminhos devem ser relativos e permanecer dentro do projeto Writerside aberto; a forma de bloco cercado com src é exclusiva do Markdown do Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'O BusyMark aceita expressões TeX, não documentos TeX ou LaTeX completos.';

  @override
  String get syntaxReferenceInlineMath => 'Matemática em linha';

  @override
  String get syntaxReferenceGithubMath =>
      'Matemática do GitHub com cifrão e crase';

  @override
  String get syntaxReferenceDisplayMath => 'Matemática em bloco';

  @override
  String get syntaxReferenceMathFence => 'Bloco cercado math';

  @override
  String get syntaxReferenceTexFence => 'Bloco cercado tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'O BusyMark não reconhece \\(...\\) nem \\[...\\] como delimitadores matemáticos do Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Fora do modo Writerside, um bloco tex continua sendo um bloco de código comum.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Elemento math do Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'O elemento math é sintaxe semântica do Writerside, não MathML HTML bruto permitido.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Bloco de código TeX semântico';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Estas extensões específicas são interpretadas somente em projetos Writerside abertos.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Citação de aviso';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Uma citação simples é uma dica no Markdown do Writerside; no Markdown comum, continua sendo uma citação normal.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Avisos semânticos';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'O Markdown comum não interpreta estes elementos semânticos do Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Título recolhível';

  @override
  String get syntaxReferenceCollapsibleCode => 'Bloco de código recolhível';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Conteúdo semântico recolhível';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'O BusyMark aceita as formas recolhíveis chapter, procedure, code-block e lista de definições, não todo o catálogo do Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Blocos de código semânticos para matemática e diagramas';

  @override
  String get syntaxReferenceVideo => 'Vídeo do Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Vídeo local usa uma imagem preview-src local; fontes hospedadas devem ser URLs HTTPS compatíveis do YouTube ou Vimeo.';

  @override
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get pdfExportDescription =>
      'Escolha o esquema da página para criar um PDF bem acabado e independente.';

  @override
  String get pdfRemoteImagesNote =>
      'As imagens remotas não são transferidas durante a exportação. As imagens locais são incluídas quando disponíveis.';

  @override
  String get pdfPageSize => 'Tamanho da página';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Carta';

  @override
  String get pdfOrientation => 'Orientação';

  @override
  String get pdfPortrait => 'Vertical';

  @override
  String get pdfLandscape => 'Horizontal';

  @override
  String get pdfMargins => 'Margens';

  @override
  String get pdfMarginNarrow => 'Estreitas';

  @override
  String get pdfMarginNormal => 'Normais';

  @override
  String get pdfMarginWide => 'Largas';

  @override
  String get pdfIncludePageNumbers => 'Incluir números de página';

  @override
  String get export => 'Exportar';

  @override
  String get exportingPdf => 'Exportando PDF…';

  @override
  String get fileTypePdf => 'Documento PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName foi exportado.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avisos',
      one: '1 aviso',
    );
    return '$fileName foi exportado com $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'O componente de exportação para PDF está ausente. Reinstale o BusyMark e tente novamente.';

  @override
  String get pdfExportTimedOut =>
      'A exportação para PDF demorou demasiado e foi interrompida.';

  @override
  String get pdfExportFailed =>
      'O BusyMark não conseguiu exportar este documento como PDF.';

  @override
  String get visualizationRendering => 'Renderizando…';

  @override
  String get visualizationStale => 'Exibindo a última renderização válida';

  @override
  String get visualizationShowSource => 'Mostrar código-fonte';

  @override
  String get visualizationShowRender => 'Mostrar renderização';

  @override
  String get visualizationFitWidth => 'Ajustar à largura';

  @override
  String get visualizationSaveImage => 'Salvar imagem';

  @override
  String get visualizationCopyImage => 'Copiar imagem';

  @override
  String get visualizationImageCopied => 'Imagem copiada';

  @override
  String get visualizationOpenApiReference => 'Abrir referência da API';

  @override
  String get visualizationValid => 'Válido';

  @override
  String get visualizationInvalid => 'Inválido';

  @override
  String get visualizationServers => 'Servidores';

  @override
  String get visualizationPaths => 'Caminhos';

  @override
  String get visualizationOperations => 'Operações';

  @override
  String get visualizationTags => 'Etiquetas';

  @override
  String get visualizationNoOperations => 'Nenhuma operação correspondente';

  @override
  String get visualizationSearchOperations => 'Pesquisar operações';

  @override
  String get visualizationRenderFailed =>
      'Não foi possível renderizar esta visualização.';

  @override
  String get visualizationRetry => 'Tentar novamente';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName salvo';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Exportar o documento ativo ou o módulo do Writerside como PDF.';

  @override
  String get instances => 'Instâncias';

  @override
  String get newInstance => 'Nova instância';

  @override
  String get newTocLibrary => 'Nova biblioteca de sumário';

  @override
  String get editInstance => 'Editar instância';

  @override
  String get openTocFile => 'Abrir arquivo do índice';

  @override
  String get createInstance => 'Criar instância';

  @override
  String get createTocLibrary => 'Criar biblioteca de sumário';

  @override
  String get instanceContent => 'Conteúdo';

  @override
  String get instanceContentSource => 'Criar a partir de';

  @override
  String get emptyInstance => 'Instância vazia';

  @override
  String get markdownFiles => 'Arquivos Markdown locais';

  @override
  String get chooseMarkdownFolder => 'Escolher pasta de Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Escolha uma pasta que contenha arquivos Markdown.';

  @override
  String get instanceAppearance => 'Aparência';

  @override
  String get instanceColor => 'Cor do ícone';

  @override
  String get instanceVersion => 'Versão';

  @override
  String instanceVersionInherited(String version) {
    return 'Quando este campo está vazio, é usada a versão do projeto $version.';
  }

  @override
  String get instanceWebPath => 'Caminho web';

  @override
  String get instanceStatus => 'Estado';

  @override
  String get instanceStatusRelease => 'Lançamento';

  @override
  String get instanceStatusEap => 'Acesso antecipado';

  @override
  String get instanceStatusDeprecated => 'Obsoleta';

  @override
  String get allowSearchEngineIndexing =>
      'Permitir indexação por mecanismos de busca';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Permita que mecanismos de busca externos indexem esta saída.';

  @override
  String get offlineArtifact => 'Artefato offline';

  @override
  String get offlineArtifactDescription =>
      'Inclua os recursos para que a documentação gerada funcione de forma autônoma.';

  @override
  String get instanceOutputSettings => 'Configurações de saída';

  @override
  String get markdownImportSource => 'Origem Markdown';

  @override
  String get markdownImportFiles => 'Arquivos Markdown';

  @override
  String get selectNone => 'Não selecionar nenhum';

  @override
  String markdownFilesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count arquivos Markdown',
      one: 'Foi encontrado 1 arquivo Markdown',
    );
    return '$_temp0';
  }

  @override
  String get noMarkdownFilesFound =>
      'Não foram encontrados arquivos Markdown neste diretório.';

  @override
  String get copyReferencedMedia => 'Copiar mídia referenciada';

  @override
  String get copyReferencedMediaDescription =>
      'Copie imagens e vídeos locais referenciados pelos arquivos selecionados, preservando os caminhos relativos.';

  @override
  String get instanceIdRenameWarningTitle => 'Mudar o nome do ID da instância?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'O BusyMark vai renomear o arquivo .tree e atualizar as referências do projeto Writerside de “$oldId” para “$newId”. Os scripts de publicação não são alterados e devem ser atualizados separadamente.';
  }

  @override
  String get renameAndUpdateReferences =>
      'Mudar o nome e atualizar referências';

  @override
  String get tocLibraryDescription =>
      'Uma biblioteca de sumário armazena seções reutilizáveis e não produz uma saída própria.';

  @override
  String get defaultTocLibraryName => 'Sumário compartilhado';

  @override
  String get instanceColorAutomatic => 'Automático';

  @override
  String get instanceColorBlue => 'Azul';

  @override
  String get instanceColorGreen => 'Verde';

  @override
  String get instanceColorOrange => 'Laranja';

  @override
  String get instanceColorPurple => 'Roxo';

  @override
  String get instanceColorRed => 'Vermelho';

  @override
  String get instanceColorTeal => 'Verde-azulado';

  @override
  String get instanceColorYellow => 'Amarelo';

  @override
  String get errorWritersideInstanceNameRequired =>
      'Digite um nome para a instância.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Já existe uma instância com o ID “$id”.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'A árvore da instância já existe: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'O diretório de origem Markdown não existe: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Selecione pelo menos um arquivo Markdown para importar.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Este não é um arquivo Markdown legível dentro da origem selecionada: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'A importação substituiria um arquivo existente do projeto: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Os arquivos da instância foram alterados no disco. Revise-os e tente novamente.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'O BusyMark não conseguiu reverter completamente a alteração da instância. Revise estes arquivos antes de continuar: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Uma biblioteca de sumário não pode importar tópicos Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'O caminho web deve ter uma única linha.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'A configuração da instância do Writerside é inválida. Corrija os diagnósticos e tente novamente.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'O BusyMark não conseguiu preparar com segurança as alterações da instância.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Estado de instância desconhecido “$status”. Use release, eap ou deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'O ID de instância “$id” é usado por mais de um arquivo de árvore.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml deve ter um elemento raiz <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'O valor $name “$value” deve ser true ou false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Um elemento <build-profile> deve especificar um ID de instância.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Um <include> da árvore deve especificar from e element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Um <snippet> da árvore deve especificar um id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Uma referência de sumário entre instâncias deve especificar ref e in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Um elemento do sumário não pode apontar para mais do que um tópico, referência, link ou redirecionamento.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'O ID de elemento da árvore “$id” foi declarado mais de uma vez.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'O arquivo de grupos de instâncias deve ter um elemento raiz <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Um grupo de instâncias deve especificar um id e uma lista de instâncias não vazios.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'O ID do grupo de instâncias “$id” foi declarado mais de uma vez.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'A inclusão de sumário “$source#$id” pertence ao módulo externo “$origin” e não pode ser expandida neste espaço de trabalho.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'O elemento de árvore “$id” não existe na árvore registrada “$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'A inclusão de árvore “$source#$id” cria um ciclo.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'A condição de instância referencia o grupo desconhecido “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'A referência entre instâncias aponta para a instância desconhecida “$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'O tópico “$topic” não está na instância referenciada “$instance”.';
  }

  @override
  String get download => 'Baixar';

  @override
  String get exportWritersideAsPdf => 'Exportar Writerside como PDF';

  @override
  String get writersidePdfContent => 'Conteúdo da exportação';

  @override
  String get writersidePdfPage => 'Página';

  @override
  String get exportingWritersidePdf => 'Exportando PDF do Writerside…';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama local';

  @override
  String get aiDisabled => 'Desativado';

  @override
  String get aiExplicitEditingDescription =>
      'A edição com IA é iniciada apenas de forma explícita. O BusyMark envia somente o contexto exibido ao provedor selecionado e nunca aplica uma proposta sem revisão.';

  @override
  String get aiProvider => 'Provedor de IA';

  @override
  String get aiDefaultProvider => 'Provedor predefinido';

  @override
  String get aiConfigureProvider => 'Configurar provedor';

  @override
  String get aiChooseProvider => 'Escolher provedor de IA';

  @override
  String get aiOllamaEndpoint => 'Endpoint do Ollama';

  @override
  String get aiOllamaModel => 'Modelo do Ollama';

  @override
  String get aiTestConnection => 'Testar conexão';

  @override
  String get aiTestingConnection => 'Testando…';

  @override
  String aiConnectionReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count modelos instalados',
      one: 'Foi encontrado 1 modelo instalado',
    );
    return 'Conectado. $_temp0.';
  }

  @override
  String get aiNoModels => 'Nenhum modelo selecionado.';

  @override
  String get aiConnectionFailed =>
      'O BusyMark não conseguiu verificar a geração de texto por IA.';

  @override
  String get aiConfigureFirst =>
      'Ative um provedor de IA e verifique um modelo em Configurações → IA.';

  @override
  String get aiEditWithAi => 'Editar com IA';

  @override
  String get aiRefineWithAi => 'Melhorar com IA';

  @override
  String get aiInstruction => 'Instrução';

  @override
  String get aiChangeTarget => 'O que pode ser alterado';

  @override
  String get aiSharedContext => 'Contexto compartilhado com a IA';

  @override
  String get aiTargetSelection => 'Conteúdo selecionado';

  @override
  String get aiTargetInsertAfterBlock => 'Inserir após o bloco atual';

  @override
  String get aiTargetCurrentBlock => 'Bloco atual';

  @override
  String get aiTargetCurrentSection => 'Seção atual';

  @override
  String get aiTargetCompleteDocument => 'Documento completo';

  @override
  String get aiContextNone => 'Sem contexto do documento';

  @override
  String get aiContextSelection => 'Conteúdo selecionado';

  @override
  String get aiContextCurrentBlock => 'Bloco atual';

  @override
  String get aiContextCurrentSection => 'Seção atual';

  @override
  String get aiContextCompleteDocument => 'Documento completo';

  @override
  String get aiGenerating => 'Gerando proposta…';

  @override
  String get aiProposal => 'Proposta de IA';

  @override
  String get aiGenerateProposal => 'Gerar proposta';

  @override
  String aiContextDisclosure(int count) {
    return 'O provedor selecionado receberá $count caracteres do contexto exibido.';
  }

  @override
  String get aiOriginal => 'Texto original';

  @override
  String get aiSuggested => 'Sugestão';

  @override
  String get aiApplyProposal => 'Aplicar proposta';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input tokens de entrada · $output tokens de saída';
  }

  @override
  String get aiStaleProposal =>
      'O documento foi alterado enquanto esta proposta era gerada. Execute a ação novamente.';

  @override
  String get gitAiStagedChangesChanged =>
      'As alterações preparadas mudaram enquanto esta mensagem de commit era gerada. Execute a ação novamente.';

  @override
  String get aiViewContext => 'Ver contexto enviado';

  @override
  String get aiReviewExactContent => 'Revisar conteúdo exato';

  @override
  String get aiContentToChange => 'Conteúdo a alterar';

  @override
  String get aiContentSentToAi => 'Conteúdo enviado à IA';

  @override
  String get aiApiKey => 'Chave de API';

  @override
  String get aiApiKeyStoredHint =>
      'Uma chave está armazenada no cofre de credenciais do sistema';

  @override
  String get aiApiKeyEnterHint => 'Insira uma chave de API do provedor';

  @override
  String get aiReplaceApiKey => 'Substituir chave de API';

  @override
  String get aiSaveApiKey => 'Salvar chave de API com segurança';

  @override
  String get aiRemoveApiKey => 'Remover chave de API salva';

  @override
  String get aiCredentialSaved =>
      'A chave de API foi salva no cofre de credenciais do sistema.';

  @override
  String get aiCredentialRemoved => 'A chave de API salva foi removida.';

  @override
  String get aiModelRouting => 'Seleção de modelo';

  @override
  String get aiAutomaticRouting => 'Automática conforme a tarefa';

  @override
  String get aiFixedModelRouting => 'Usar o modelo selecionado';

  @override
  String get aiPreferredModel => 'Modelo preferido';

  @override
  String get aiModel => 'Modelo';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests solicitações · $input tokens de entrada · $output tokens de saída';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Enviar conteúdo para $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Ativar $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Somente o conteúdo exibido em cada caixa de diálogo de revisão de IA é enviado. As solicitações não mantêm estado, as propostas exigem revisão e a chave de API é armazenada no cofre de credenciais do sistema Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Primeiro, confirme o compartilhamento de dados com $provider em Configurações → IA.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Geração verificada com $model. Há $count modelos compatíveis disponíveis.';
  }

  @override
  String get aiColdStartObserved =>
      'Foi detetado um arranque a frio do modelo local.';

  @override
  String get aiNoCompatibleModels =>
      'Não há nenhum modelo compatível de geração de texto disponível.';

  @override
  String get aiEnableProvider => 'Primeiro, ative um provedor de IA.';

  @override
  String get aiDraftCommitMessage => 'Criar rascunho da mensagem de commit';

  @override
  String get aiDrafting => 'Criando rascunho…';

  @override
  String get aiDraftWithAi => 'Criar rascunho com IA';

  @override
  String get generateOrUpdateMarkdownToc => 'Gerar/atualizar sumário';

  @override
  String get markdownTocTitle => 'Sumário';

  @override
  String markdownTocUpdated(int count) {
    return 'Sumário atualizado com $count entradas.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Adicione pelo menos um título de seção antes de gerar um sumário.';

  @override
  String get markdownTocMalformedMarkers =>
      'Os marcadores de sumário do BusyMark estão ausentes, duplicados ou fora de ordem.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'O título de nível $level vem após o nível $previousLevel; revise o aninhamento das seções.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'O texto do link está vazio; forneça um nome acessível que descreva sua finalidade.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Verifique se o texto do link “$text” descreve sua finalidade no contexto.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Os cabeçalhos da tabela devem identificar suas colunas; preencha cada cabeçalho vazio.';

  @override
  String get mathRenderFailed =>
      'Não foi possível renderizar a expressão matemática.';

  @override
  String get inlineMath => 'Matemática em linha';

  @override
  String get displayMath => 'Matemática em bloco';
}

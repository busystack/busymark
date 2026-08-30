// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
  String get shortcutMarkdownAndHtmlDescription =>
      'Open the Markdown and HTML reference';

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
  String get markdownAndHtml => 'Markdown and HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown Blocks';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Block structures supported in Markdown source and preview.';

  @override
  String get markdownHtmlInlineFormatting => 'Inline Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formatting that can appear inside paragraphs, list items, and table cells.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Raw HTML Blocks';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Safe block-level HTML tags rendered through BusyMark preview widgets.';

  @override
  String get markdownHtmlRawHtmlInline => 'Raw HTML Inline Tags';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Safe inline HTML tags rendered without showing literal tags.';

  @override
  String get markdownHtmlSafety => 'Safety Rules';

  @override
  String get markdownHtmlSafetyDescription =>
      'Raw HTML is parsed and sanitized before preview rendering.';

  @override
  String get markdownHtmlHeadings => 'Headings';

  @override
  String get markdownHtmlParagraphs => 'Paragraphs';

  @override
  String get markdownHtmlLists => 'Lists';

  @override
  String get markdownHtmlHtmlContainers => 'Containers';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Text blocks';

  @override
  String get markdownHtmlHtmlFigures => 'Figures and images';

  @override
  String get markdownHtmlHtmlPreformatted => 'Preformatted code';

  @override
  String get markdownHtmlHtmlDisclosure => 'Disclosure blocks';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Description lists';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Formatting tags';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Inline code tags';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Semantic text tags';

  @override
  String get markdownHtmlSanitizedPreview => 'Sanitized preview';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Allowed HTML is converted to BusyMark preview blocks, not rendered in a browser.';

  @override
  String get markdownHtmlSourcePreserved => 'Source is preserved';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Unedited raw HTML is saved back exactly as source text.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown inside HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Markdown markers inside raw HTML render as literal text.';

  @override
  String get markdownHtmlBlockedContent => 'Blocked active content';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Scripts, styles, frames, forms, SVG, MathML, events, and unsafe attributes are blocked.';

  @override
  String get markdownHtmlSafeUrls => 'Safe URLs only';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Links allow http, https, mailto, tel, relative, and fragment URLs; unsafe schemes are blocked.';

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

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle => 'Markdown 文件和兼容 Writerside 的文档项目编辑器。';

  @override
  String get aboutBusyMark => '关于 BusyMark';

  @override
  String get aboutTagline => 'Markdown 和 Writerside 编辑器';

  @override
  String get aboutLicenseLabel => '许可证';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => '网站';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get reportIssue => '报告问题';

  @override
  String get feedbackCategory => '类别';

  @override
  String get feedbackChooseCategory => '选择类别';

  @override
  String get feedbackCategoryProblem => '问题或错误';

  @override
  String get feedbackCategoryFeature => '功能请求';

  @override
  String get feedbackCategoryPrivacySecurity => '隐私或安全问题';

  @override
  String get feedbackCategoryUsability => '可用性问题';

  @override
  String get feedbackCategoryOther => '其他';

  @override
  String get feedbackSubject => '主题';

  @override
  String get feedbackMessage => '详细留言';

  @override
  String get feedbackReplyEmail => '回复邮箱（可选）';

  @override
  String get feedbackIncludeTechnicalDetails => '包含技术详细信息';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      '启用后，此选项仅会添加您的 Linux 操作系统版本和 BusyMark 应用语言。不会附加日志、文件、账户数据或其他诊断信息。';

  @override
  String get feedbackSubmit => '提交';

  @override
  String get feedbackSubmitting => '正在提交…';

  @override
  String get feedbackCategoryRequired => '请选择类别。';

  @override
  String get feedbackSubjectLength => '主题必须包含 3 到 120 个字符。';

  @override
  String get feedbackMessageLength => '信息必须包含 10 到 5,000 个字符。';

  @override
  String get feedbackReplyEmailInvalid => '请输入有效的邮箱地址，或将此字段留空。';

  @override
  String get feedbackConnectionFailure => 'BusyMark 无法连接。请检查网络连接后重试。';

  @override
  String get feedbackTimeoutFailure => '请求超时。请重试。';

  @override
  String get feedbackRateLimitedFailure => '此连接发送的报告过多。请稍候再试。';

  @override
  String get feedbackRejectedFailure => '服务器拒绝了此报告。请检查表单字段后重试。';

  @override
  String get feedbackServerFailure => '服务器无法接收此报告。请稍后重试。';

  @override
  String feedbackSuccess(String id) {
    return '反馈已发送。参考 ID：$id';
  }

  @override
  String get advanced => '高级';

  @override
  String get addToGit => '添加到 Git';

  @override
  String get appearance => '外观';

  @override
  String get apply => '应用';

  @override
  String get back => '返回';

  @override
  String get bottomLeft => '左下';

  @override
  String get bottomRight => '右下';

  @override
  String get cancel => '取消';

  @override
  String get choose => '选择';

  @override
  String get chooseLocation => '选择位置';

  @override
  String get copy => '复制';

  @override
  String get copyName => '复制名称';

  @override
  String get copyFileName => '复制文件名';

  @override
  String get copyPath => '复制路径';

  @override
  String get create => '创建';

  @override
  String get creating => '正在创建…';

  @override
  String get cut => '剪切';

  @override
  String get promoteSection => '提升节级别';

  @override
  String get demoteSection => '降低节级别';

  @override
  String get moveSectionUp => '上移节';

  @override
  String get moveSectionDown => '下移节';

  @override
  String get confirmDeleteSectionTitle => '删除此节？';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '删除“$name”及其节中的全部内容？此操作无法撤销。';
  }

  @override
  String get darkTheme => '深色';

  @override
  String get delete => '删除';

  @override
  String get discard => '放弃';

  @override
  String get editor => '编辑器';

  @override
  String get file => '文件';

  @override
  String get fileHistory => '文件历史记录';

  @override
  String get folder => '文件夹';

  @override
  String get insert => '插入';

  @override
  String get keyboardShortcuts => '键盘快捷键';

  @override
  String get commandPalette => '命令面板';

  @override
  String get commandPaletteHint => '输入命令';

  @override
  String get commandPaletteEmpty => '没有匹配的命令';

  @override
  String get commandUnavailableInContext => '当前编辑器上下文中无法使用此命令';

  @override
  String get lightTheme => '浅色';

  @override
  String get mainMenu => '主菜单';

  @override
  String get fullScreen => '全屏';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => '打开';

  @override
  String get openInFiles => '在文件中打开';

  @override
  String get pathActions => '路径操作';

  @override
  String get outline => '大纲';

  @override
  String get overwrite => '覆盖';

  @override
  String get paste => '粘贴';

  @override
  String get pasteWithoutFormatting => '粘贴为无格式文本';

  @override
  String get reading => '阅读';

  @override
  String get removeFromRecent => '从最近使用记录中移除';

  @override
  String get recent => '最近使用';

  @override
  String get redo => '重做';

  @override
  String get save => '保存';

  @override
  String get search => '搜索';

  @override
  String get selectAll => '全选';

  @override
  String get settings => '设置';

  @override
  String get source => '源代码';

  @override
  String get split => '拆分';

  @override
  String get systemTheme => '系统';

  @override
  String get theme => '主题';

  @override
  String get appLanguage => '语言';

  @override
  String get systemLanguage => '系统';

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
  String get toggleSidebar => '侧边栏面板';

  @override
  String get topLeft => '左上';

  @override
  String get topRight => '右上';

  @override
  String get undo => '撤销';

  @override
  String get validate => '验证';

  @override
  String get validation => '验证';

  @override
  String get viewMode => '视图模式';

  @override
  String get welcome => '欢迎';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => '图像';

  @override
  String get openMarkdownFile => '打开 Markdown 文件';

  @override
  String get markdownFileExtensions => '.md 或 .markdown';

  @override
  String get openFolderOrWritersideProject => '打开文件夹或 Writerside 项目';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown 文件夹或兼容 Writerside 的项目';

  @override
  String get noOpenFile => '没有打开的文件';

  @override
  String get shortcutDeleteTreeItemDescription => '删除选中的文件项，或从目录中移除选中的主题';

  @override
  String get shortcutGroupGeneral => '常规';

  @override
  String get shortcutNewDocument => '创建';

  @override
  String get shortcutNewDocumentDescription => '创建 Markdown 文件或 Writerside 项目';

  @override
  String get shortcutOpenDescription => '打开 Markdown 文件、文件夹或 Writerside 项目';

  @override
  String get shortcutSaveDescription => '保存当前文档';

  @override
  String get shortcutSearchDescription => '搜索当前工作区';

  @override
  String get shortcutKeyboardShortcutsDescription => '显示此键盘快捷键参考';

  @override
  String get shortcutMarkdownAndHtmlDescription => '打开 Markdown 和 HTML 参考';

  @override
  String get shortcutSettingsDescription => '打开 BusyMark 设置';

  @override
  String get shortcutNextTab => '下一个标签页';

  @override
  String get shortcutNextTabDescription => '移至下一个打开的标签页';

  @override
  String get shortcutPreviousTab => '上一个标签页';

  @override
  String get shortcutPreviousTabDescription => '移至上一个打开的标签页';

  @override
  String get shortcutCloseTab => '关闭标签页';

  @override
  String get shortcutCloseTabDescription => '关闭当前标签页';

  @override
  String get shortcutCloseAllTabs => '关闭所有标签页';

  @override
  String get shortcutCloseAllTabsDescription => '关闭所有打开的标签页';

  @override
  String get shortcutGroupTextEditing => '文本编辑';

  @override
  String get shortcutSelectAllDescription => '在源代码模式下选择全部文本；在编辑器模式下按两次以选择所有块';

  @override
  String get shortcutCutDescription => '剪切选中的文本';

  @override
  String get shortcutCopyDescription => '复制选中的文本';

  @override
  String get shortcutPasteDescription => '从剪贴板粘贴';

  @override
  String get shortcutPastePlainTextDescription => '粘贴剪贴板中的无格式文本';

  @override
  String get shortcutUndoDescription => '撤销上次编辑';

  @override
  String get shortcutRedoDescription => '重做上次撤销的编辑';

  @override
  String get shortcutInsertIndentation => '插入缩进';

  @override
  String get shortcutInsertIndentationDescription => '在光标处插入缩进';

  @override
  String get shortcutOutdentSource => '减少源代码缩进';

  @override
  String get shortcutOutdentSourceDescription => '在源代码模式下减少一级缩进';

  @override
  String get shortcutEscape => '关闭搜索或清除块选择';

  @override
  String get shortcutEscapeDescription => '关闭工作区搜索，或在编辑器模式下清除块选择';

  @override
  String get shortcutGroupFormatting => '格式';

  @override
  String get shortcutBoldDescription => '切换选中文本的粗体';

  @override
  String get shortcutItalicDescription => '切换选中文本的斜体';

  @override
  String get shortcutUnderlineDescription => '切换选中文本的下划线';

  @override
  String get shortcutLinkDescription => '插入或编辑链接';

  @override
  String get shortcutInlineCodeDescription => '切换选中文本的行内代码格式';

  @override
  String get shortcutStrikethroughDescription => '切换选中文本的删除线';

  @override
  String get shortcutGroupBlocks => '块';

  @override
  String get shortcutParagraphDescription => '将当前块设为段落';

  @override
  String get shortcutHeading1Description => '将当前块设为标题 1';

  @override
  String get shortcutHeading2Description => '将当前块设为标题 2';

  @override
  String get shortcutHeading3Description => '将当前块设为标题 3';

  @override
  String get shortcutHeading4Description => '将当前块设为标题 4';

  @override
  String get shortcutHeading5Description => '将当前块设为标题 5';

  @override
  String get shortcutHeading6Description => '将当前块设为标题 6';

  @override
  String get shortcutGroupLists => '列表';

  @override
  String get numberedList => '编号列表';

  @override
  String get shortcutNumberedListDescription => '切换编号列表格式';

  @override
  String get bulletedList => '项目符号列表';

  @override
  String get shortcutBulletedListDescription => '切换项目符号列表格式';

  @override
  String get checklist => '检查清单';

  @override
  String get shortcutChecklistDescription => '切换检查清单格式';

  @override
  String get shortcutGroupSidebar => '侧边栏';

  @override
  String get sidebarViewMenu => '侧边栏视图';

  @override
  String get createMarkdownFile => '创建 Markdown 文件';

  @override
  String get createMarkdownFileDescription => '开始创建未保存的本地 Markdown 文档';

  @override
  String get createWritersideProject => '创建 Writerside 项目';

  @override
  String get createWritersideProjectDescription => '开始创建本地兼容 Writerside 的项目';

  @override
  String get defaultProjectName => '文档';

  @override
  String get defaultInstanceName => '用户指南';

  @override
  String get defaultStartTopicTitle => '开始使用';

  @override
  String get projectName => '项目名称';

  @override
  String get directoryName => '目录名称';

  @override
  String get instanceName => '实例名称';

  @override
  String get instanceId => '实例 ID';

  @override
  String get startTopicTitle => '起始主题标题';

  @override
  String get location => '位置';

  @override
  String get projectNameRequired => '项目名称为必填项。';

  @override
  String get directoryNameRequired => '目录名称为必填项。';

  @override
  String get useSingleSafeDirectoryName => '使用单一且安全的目录名称。';

  @override
  String get useLowercaseIdentifier => '使用仅包含小写字母、数字、下划线或连字符的小写标识符。';

  @override
  String get startTopicTitleRequired => '起始主题标题为必填项。';

  @override
  String get createWritersideProjectFailed => '无法创建 Writerside 项目。';

  @override
  String get settingsTitle => 'BusyMark 设置';

  @override
  String get autoSave => '自动保存';

  @override
  String get autoSaveDescription => '在短暂空闲后自动保存文件更改。';

  @override
  String get wordWrap => '自动换行';

  @override
  String get editorFontSize => '编辑器字体大小';

  @override
  String get validateOnEdit => '编辑时验证';

  @override
  String get clearRecentWorkspaces => '清除最近使用的工作区';

  @override
  String get editingButtonsPosition => '编辑按钮位置';

  @override
  String get editingButtonsPositionDescription => '选择浮动 WYSIWYG 编辑按钮的显示位置。';

  @override
  String get editingButtonsDirection => '编辑按钮方向';

  @override
  String get editingButtonsDirectionDescription => '选择水平或垂直排列浮动 WYSIWYG 编辑按钮。';

  @override
  String get horizontal => '水平';

  @override
  String get vertical => '垂直';

  @override
  String get privacy => '隐私';

  @override
  String get allowRemoteImages => '加载远程图像';

  @override
  String get allowRemoteImagesDescription =>
      '允许 Markdown 预览和编辑器从 http 和 https URL 加载图像。';

  @override
  String get clearRemoteImagePermissions => '清除远程图像权限';

  @override
  String get clearRemoteImagePermissionsDescription => '忘记已获准加载远程图像的工作区。';

  @override
  String get clearGitWorkspaceTrust => '清除受信任的 Git 工作区';

  @override
  String get clearGitWorkspaceTrustDescription => '为之前受信任的工作区启用 Git 功能前先进行询问。';

  @override
  String get settingsWindowSectionTitle => '窗口';

  @override
  String get settingsReopenWorkspaceOnStartupTitle => '启动时重新打开上次的工作区';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark 启动时打开上次会话中的工作区和标签页。';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle => '有未保存更改时关闭前进行确认';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      '文档有未保存更改时，关闭 BusyMark 前先进行询问。';

  @override
  String get closeUnsavedChangesTitle => '未保存的更改';

  @override
  String get closeUnsavedChangesSingleMessage =>
      '此文档有未保存的更改。关闭 BusyMark 前保存更改？';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文档包含未保存的更改。关闭 BusyMark 前保存更改？',
      one: '有 1 个文档包含未保存的更改。关闭 BusyMark 前保存更改？',
      zero: '关闭 BusyMark 前保存更改？',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => '取消';

  @override
  String get closeUnsavedChangesDiscard => '放弃';

  @override
  String get closeUnsavedChangesSave => '保存';

  @override
  String get currentFile => '当前文件';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName 中有未保存的更改。继续前保存这些更改？';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文档包含未保存的更改。继续前保存它们？',
      one: '有 1 个文档包含未保存的更改。继续前保存它？',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => '文件已在磁盘上更改';

  @override
  String get fileChangedOnDiskMessage => '自打开此文件后，它已在磁盘上发生更改。覆盖它？';

  @override
  String get untitledMarkdownFileName => '未命名.md';

  @override
  String get unorderedList => '无序列表';

  @override
  String get orderedList => '有序列表';

  @override
  String get taskList => '任务列表';

  @override
  String get toggleTaskChecked => '切换任务选中状态';

  @override
  String get indentListItem => '增加列表项缩进';

  @override
  String get outdentListItem => '减少列表项缩进';

  @override
  String get blockquote => '引用块';

  @override
  String get codeBlock => '代码块';

  @override
  String get codeBlockLanguage => '代码块语言';

  @override
  String get image => '图像';

  @override
  String get video => '视频';

  @override
  String get openVideo => '播放视频';

  @override
  String get pauseVideo => '暂停视频';

  @override
  String get videoUnavailable => '视频不可用';

  @override
  String get videoPreview => '视频预览';

  @override
  String get diagnosticWritersideVideoMissingSource => '视频缺少 src 属性。';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return '不支持的视频源：$source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return '视频文件不存在：$source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return '视频预览图像不存在：$preview';
  }

  @override
  String get inlineImage => '行内图像';

  @override
  String get table => '表格';

  @override
  String get htmlBlock => 'HTML 块';

  @override
  String get htmlContentDefault => 'HTML 内容';

  @override
  String get shortcutHtmlBlockDescription => '插入或编辑 HTML 块';

  @override
  String get renderedHtml => '已渲染的 HTML';

  @override
  String get editHtml => '编辑 HTML';

  @override
  String get htmlSource => 'HTML 源代码';

  @override
  String get thematicBreak => '分隔线';

  @override
  String get bold => '粗体';

  @override
  String get italic => '斜体';

  @override
  String get underline => '下划线';

  @override
  String get strikethrough => '删除线';

  @override
  String get inlineCode => '行内代码';

  @override
  String get link => '链接';

  @override
  String get hardLineBreak => '硬换行';

  @override
  String get textStyle => '文本样式';

  @override
  String get paragraph => '段落';

  @override
  String get heading1 => '标题 1';

  @override
  String get heading2 => '标题 2';

  @override
  String get heading3 => '标题 3';

  @override
  String get heading4 => '标题 4';

  @override
  String get heading5 => '标题 5';

  @override
  String get heading6 => '标题 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => '删除表格';

  @override
  String tableColumnNumber(int columnNumber) {
    return '列 $columnNumber';
  }

  @override
  String get insertColumnLeft => '在左侧插入列';

  @override
  String get insertColumnRight => '在右侧插入列';

  @override
  String get deleteColumn => '删除列';

  @override
  String get tableAlignmentUnspecified => '对齐方式：未指定';

  @override
  String get tableAlignmentLeft => '对齐方式：左对齐';

  @override
  String get tableAlignmentCenter => '对齐方式：居中';

  @override
  String get tableAlignmentRight => '对齐方式：右对齐';

  @override
  String tableRowNumber(int rowNumber) {
    return '行 $rowNumber';
  }

  @override
  String get insertRowAbove => '在上方插入行';

  @override
  String get insertRowBelow => '在下方插入行';

  @override
  String get deleteRow => '删除行';

  @override
  String get tableHeaderHint => '标题';

  @override
  String get tableCellHint => '单元格';

  @override
  String get language => '语言';

  @override
  String get hideEditingButtons => '隐藏编辑按钮';

  @override
  String get showEditingButtons => '显示编辑按钮';

  @override
  String get altText => '替代文本';

  @override
  String get editorPlaceholderText => '文本';

  @override
  String get editorPlaceholderCode => '代码';

  @override
  String get editorPlaceholderAltText => '替代文本';

  @override
  String get describeTheImage => '描述图像';

  @override
  String get columns => '列';

  @override
  String get rows => '行';

  @override
  String tableHeaderNumber(int columnNumber) {
    return '标题 $columnNumber';
  }

  @override
  String get tableCellDefault => '单元格';

  @override
  String get noImageSource => '没有图像源';

  @override
  String get remoteImageBlocked => '远程图像已阻止';

  @override
  String get remoteImageBlockedTooltip => '选择是否允许 BusyMark 加载远程图像。';

  @override
  String get remoteImagesBlockedTitle => '远程图像已阻止';

  @override
  String get remoteImagesBlockedMessage =>
      '本文档引用了来自互联网的图像。加载这些图像可能会向图像托管方泄露网络信息。';

  @override
  String get loadRemoteImagesForWorkspace => '为此工作区加载';

  @override
  String get alwaysLoadRemoteImages => '始终加载远程图像';

  @override
  String get hideSidebar => '隐藏侧边栏面板';

  @override
  String get showSidebar => '显示侧边栏面板';

  @override
  String get showPreview => '显示预览';

  @override
  String get hidePreview => '隐藏预览';

  @override
  String get workspaceKindUnsavedMarkdown => '未保存的 Markdown 文件';

  @override
  String get workspaceKindSingleMarkdown => '单个 Markdown 文件';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown 文件夹';

  @override
  String get workspaceKindWritersideModule => 'Writerside 模块';

  @override
  String get problems => '问题';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条诊断信息',
      one: '1 条诊断信息',
      zero: '没有诊断信息',
    );
    return '$_temp0';
  }

  @override
  String get files => '文件';

  @override
  String get toc => '目录';

  @override
  String get tocActions => '目录操作';

  @override
  String get markdownUnsaved => 'Markdown - 未保存';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => '没有文件';

  @override
  String get newFile => '新建文件';

  @override
  String get noWritersideToc => '没有 Writerside 目录';

  @override
  String get tocSection => '目录节';

  @override
  String get newTopic => '新建主题';

  @override
  String get newChildTopic => '新建子主题';

  @override
  String get newSiblingTopic => '新建同级主题';

  @override
  String get renameTopicFile => '重命名主题文件';

  @override
  String get topicPlacement => '目录位置';

  @override
  String get tocRoot => '位于目录根级别';

  @override
  String get afterSelectedTopic => '位于选中主题之后';

  @override
  String get insideSelectedTopic => '位于选中主题内';

  @override
  String get pasteAfterTopic => '粘贴到主题之后';

  @override
  String get pasteAsChildTopic => '粘贴为子主题';

  @override
  String get removeFromToc => '从目录中移除';

  @override
  String get confirmRemoveFromTocTitle => '从目录中移除？';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '从此目录中移除 $name？主题文件将被保留。';
  }

  @override
  String get confirmDeleteTopicTitle => '删除主题文件？';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '删除 $name 并从每个目录中移除它？此操作无法撤销。';
  }

  @override
  String get safeDeleteTopicFile => '安全删除主题文件…';

  @override
  String get removeTocElement => '移除目录元素';

  @override
  String get reviewUsages => '查看使用情况';

  @override
  String get deleteTopicFile => '删除主题文件';

  @override
  String get removeAction => '移除';

  @override
  String topicRemovalSummary(String topic) {
    return '从选中的实例中移除“$topic”。主题文件将被保留。';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '删除“$topic”，并在整个 Writerside 项目中安全更新其引用。';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个子主题将上移一级。',
      one: '1 个子主题将上移一级。',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      '此主题被用作实例的起始页。请查看其使用情况，并在继续前指定其他起始页。';

  @override
  String topicUsagesCount(int count) {
    return '使用情况（$count）';
  }

  @override
  String get noBreakingTopicUsages => '未找到会导致引用失效的引用。';

  @override
  String get topicUsagesFound => 'BusyMark 找到了以下对该主题的引用。';

  @override
  String get topicUsageTocElements => '目录元素';

  @override
  String get topicUsageStartPages => '起始页';

  @override
  String get topicUsageTopicLinks => '主题链接';

  @override
  String get topicUsageIncludes => '包含项';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次使用',
      one: '1 次使用',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => '重构选项';

  @override
  String get updateUsagesAutomatically => '自动更新使用情况';

  @override
  String get updateUsagesAutomaticallyDescription => '移除目录引用和包含项，同时保留链接文本。';

  @override
  String get manualUsageUpdatesRequired => '执行此重构前，某些使用情况需要手动更改。';

  @override
  String get setRedirectTo => '设置重定向到';

  @override
  String get noRedirectDescription => '不重定向旧的已发布页面。';

  @override
  String get redirectTarget => '重定向目标';

  @override
  String get remainingUsagesBlockRemoval => '请在继续前查看并更新剩余的使用情况，或在可用时启用自动更新。';

  @override
  String usagesOfTopic(String topic) {
    return '$topic 的使用情况';
  }

  @override
  String get noUsagesFound => '未找到使用情况';

  @override
  String get outsideSelectedInstance => '在选中的实例之外';

  @override
  String get doRefactor => '执行重构';

  @override
  String get orphanTopicTitle => '主题文件已不再使用';

  @override
  String get keepTopicFile => '保留主题文件';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic”在此 Writerside 项目中已不再使用。删除该文件，或保留它以供其他实例使用。';
  }

  @override
  String get defaultNewTopicTitle => '新主题';

  @override
  String get topicTitle => '主题标题';

  @override
  String get fileName => '文件名';

  @override
  String get topicTitleRequired => '主题标题为必填项。';

  @override
  String get fileNameRequired => '文件名为必填项。';

  @override
  String get rename => '重命名';

  @override
  String get confirmDeleteFileTitle => '删除文件？';

  @override
  String get confirmDeleteFolderTitle => '删除文件夹？';

  @override
  String confirmDeleteFileMessage(String name) {
    return '删除 $name？此操作无法撤销。';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '删除 $name 及其中的所有文件？此操作无法撤销。';
  }

  @override
  String get useSingleSafeFileName => '使用单一且安全的文件名。';

  @override
  String useExpectedExtension(String extension) {
    return '为选中的格式使用 $extension 扩展名。';
  }

  @override
  String get useIdentifierCharacters => '在扩展名之前仅使用字母、数字、下划线或连字符。';

  @override
  String get topicIdAlreadyExists => '主题 ID 已存在。';

  @override
  String get createWritersideTopicFailed => '无法创建 Writerside 主题。';

  @override
  String get noOutline => '没有大纲';

  @override
  String expandKind(String kind) {
    return '展开 $kind';
  }

  @override
  String collapseKind(String kind) {
    return '折叠 $kind';
  }

  @override
  String get foldKindSection => '节';

  @override
  String get foldKindList => '列表';

  @override
  String get foldKindQuote => '引用';

  @override
  String get foldKindTag => '标签';

  @override
  String get sourceSearchPreviousMatch => '上一个匹配项';

  @override
  String get sourceSearchNextMatch => '下一个匹配项';

  @override
  String get sourceSearchCaseSensitive => '区分大小写';

  @override
  String get sourceSearchWholeWord => '全字匹配';

  @override
  String get sourceSearchRegex => '正则表达式';

  @override
  String get sourceSearchReplacement => '替换为';

  @override
  String get sourceSearchReplaceCurrent => '替换当前匹配项';

  @override
  String get sourceSearchReplaceAndFindNext => '替换并查找下一个';

  @override
  String get sourceSearchReplaceAll => '全部替换';

  @override
  String get workspaceReplace => '在工作区中替换';

  @override
  String get reviewReplacements => '查看替换内容';

  @override
  String get applyReplacements => '应用替换';

  @override
  String get skippedFiles => '跳过的文件';

  @override
  String get workspaceReplaceDirtyBuffer => '未保存的编辑器内容';

  @override
  String get workspaceReplaceDiskContent => '磁盘上的已保存内容';

  @override
  String selectFileMatches(int count) {
    return '选择全部 $count 个匹配项';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '已在 $files 个文件中替换 $matches 个匹配项；跳过 $skipped 个。';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾有换行符';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾无换行符';
  }

  @override
  String get normalizeLineEndings => '规范化行尾';

  @override
  String get mixedLineEndingsSavePrompt => '此文档包含混合的行尾格式。请选择一种格式。';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName 使用混合的行尾格式。请在替换前选择要使用的格式。';
  }

  @override
  String get workspaceReplaceIssueOversized => '已跳过过大的文件。';

  @override
  String get workspaceReplaceIssueUnreadable => '已跳过无法读取的文件。';

  @override
  String get workspaceReplaceIssueInvalidUtf8 => '已跳过不是有效 UTF-8 的文件。';

  @override
  String get workspaceReplaceIssueTruncated => '替换预览已被截断。';

  @override
  String get workspaceReplaceIssueFileChanged => '已跳过预览后发生变化的文件。';

  @override
  String get workspaceReplaceIssueBufferChanged => '已跳过预览后发生变化的编辑器缓冲区。';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      '请在替换前选择 LF 或 CRLF 规范化。';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      '由于文件同时发生了变化，回滚已停止。部分替换可能仍然存在；被移出的内容已保留在下方路径中。';

  @override
  String get workspaceReplaceIssueApplyFailed => '无法提交经过审查的替换；没有文件发生更改。';

  @override
  String externalChangesTitle(String fileName) {
    return '外部更改 — $fileName';
  }

  @override
  String get externalFileDeleted => '此文件已从磁盘删除。';

  @override
  String get externalFileChanged => '在您有未保存编辑时，此文件已在磁盘上发生变化。';

  @override
  String recoveredDocumentReview(String fileName) {
    return '已恢复 $fileName 的未保存内容。请检查后保存、另存为或放弃。';
  }

  @override
  String get compare => '比较';

  @override
  String get reloadFromDisk => '从磁盘重新加载';

  @override
  String get keepMine => '保留我的版本';

  @override
  String get saveAs => '另存为';

  @override
  String get sourceSearchInvalidRegex => '无效的正则表达式';

  @override
  String get sourceLargeFileFeaturesPaused => '大文件：已暂停语法突出显示和折叠';

  @override
  String get nothingToRead => '没有可读取的内容';

  @override
  String get admonition => '提示块';

  @override
  String get quote => '引用';

  @override
  String get note => '备注';

  @override
  String get tip => '提示';

  @override
  String get warning => '警告';

  @override
  String get tabs => '标签页';

  @override
  String get tab => '标签页';

  @override
  String get procedure => '操作步骤';

  @override
  String get step => '步骤';

  @override
  String get topic => '主题';

  @override
  String get chapter => '章节';

  @override
  String couldNotOpenTarget(String target) {
    return '无法打开 $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return '找不到链接目标：$targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor => '无法在编辑器中打开此文件类型';

  @override
  String anchorNotFound(String anchor) {
    return '找不到锚点：$anchor';
  }

  @override
  String get noProblemsFound => '未发现问题';

  @override
  String get noResults => '无结果';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - 第 $lineNumber 行';
  }

  @override
  String get untitledResult => '未命名结果';

  @override
  String get documentKindMarkdownFile => 'Markdown 文件';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown 主题';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML 主题';

  @override
  String get documentKindWritersideTree => 'Writerside 树';

  @override
  String get documentKindConfigurationFile => '配置文件';

  @override
  String get documentKindVariablesFile => '变量文件';

  @override
  String get documentKindCategoriesFile => '类别文件';

  @override
  String get documentKindResourceFile => '资源文件';

  @override
  String workspaceErrorOpenFailed(String error) {
    return '打开失败：$error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return '无法创建 Writerside 项目：$error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return '无法创建 Writerside 主题：$error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown => '选择保存此 Markdown 文件的位置。';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk => '保存已阻止：文件已在磁盘上发生变化。';

  @override
  String workspaceErrorSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return '文件操作失败：$error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return '验证失败：$error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已恢复 $count 个未保存的文档。请在保存或放弃前逐一检查。',
      one: '已恢复 1 个未保存的文档。请在保存或放弃前进行检查。',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '无法恢复 $count 条损坏的恢复记录。有效的恢复记录仍可用。',
      one: '无法恢复一条损坏的恢复记录。原始恢复文件已保留以供检查。',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return '路径不存在：$path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return '目标目录已存在且不为空：$path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return '目标路径已存在但不是目录：$path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return '生成的文件已存在：$path';
  }

  @override
  String get errorParentDirectoryRequired => '必须指定父目录。';

  @override
  String errorParentDirectoryMissing(String path) {
    return '父目录不存在：$path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return '目录不存在：$path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return '路径已存在：$path';
  }

  @override
  String get errorFileNameRequired => '文件名为必填项。';

  @override
  String get errorFileNameUnsafe => '文件名必须是单一且安全的路径段。';

  @override
  String get errorFileOperationInvalidTarget => '无法将文件夹移动到其自身中。';

  @override
  String get errorFileOperationOutsideRoot => '文件操作必须在工作区内进行。';

  @override
  String get errorFileOperationRoot => '无法从文件树更改工作区根目录。';

  @override
  String get errorProjectNameRequired => '项目名称为必填项。';

  @override
  String get errorDirectoryNameRequired => '目录名称为必填项。';

  @override
  String get errorDirectoryNameUnsafe => '目录名称必须是单一且安全的路径段。';

  @override
  String get errorInstanceIdInvalid => '实例 ID 必须以小写字母开头，且只能包含小写字母、数字、下划线和连字符。';

  @override
  String get errorTopicFileInvalid => '主题文件名必须是没有路径分隔符的 Markdown 文件名。';

  @override
  String get errorTopicTitleRequired => '主题标题为必填项。';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside 模块根目录不存在：$path';
  }

  @override
  String get errorWritersideModuleNotOpen => '必须打开 Writerside 模块才能创建主题。';

  @override
  String get errorWritersideInstanceTreeMissing => 'Writerside 模块没有实例树。';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside 树文件不存在：$path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return '主题 ID \"$topicId\" 已存在于此帮助模块中。';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return '主题文件已存在：$path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return '选中的树中不存在引用主题：$topic';
  }

  @override
  String get errorWritersideTocNodeMissing => '选中的目录项已不存在。';

  @override
  String get errorWritersideTocInvalidMove => '目录项无法移动到自身或其子项中。';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return '无法删除起始主题 $topic。请先选择其他起始页。';
  }

  @override
  String get errorWritersideSafeDeleteRequired => '请对 Writerside 主题文件使用安全删除。';

  @override
  String get errorWritersideTopicUsageScanFailed => '无法完成主题使用情况扫描。没有文件发生更改。';

  @override
  String get errorWritersideTopicUsagesRemain => '某些主题使用情况仍需处理。请先查看后再继续。';

  @override
  String get errorWritersideRedirectInvalid => '选中的重定向目标已无效。请重新选择。';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return '无法完全回滚主题移除。请在继续前查看这些路径：$paths';
  }

  @override
  String get errorTopicsRootUnsafe => '主题根目录必须是安全的相对目录。';

  @override
  String get errorTopicFileNameUnsafe => '主题文件名必须是单一且安全的路径段。';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return '主题文件扩展名必须与选中的格式匹配（$extension）。';
  }

  @override
  String get errorTopicFileNameInvalid => '主题文件名只能包含字母、数字、下划线和连字符。';

  @override
  String errorUnknown(String code) {
    return '未知错误：$code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return '无法读取文件元数据：$error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped => '检测到大型工作区。为保持应用响应速度，已跳过部分文件。';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return '无法检查工作区项：$error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge => '文件超过 beta 自动解析限制。';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return '无法读取 Markdown 文件：$error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed => 'Writerside 标题属性块格式错误。';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return '标题 ID“$id”重复。';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      '额外的顶级 H1 标题将被视为章节。';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown 主题没有 H1 或 front matter 标题。';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle => 'XML 主题缺少标题。';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return '主题“$fileName”缺少标题。';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed => 'front matter 未闭合。';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => '不安全的 HTML 元素。';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return '链接目标不存在：$targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return '锚点“$anchor”不存在。';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return '图像“$destination”缺少替代文本。';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return '图像不存在：$destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return '无效的 XML：$message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg 根元素必须是 <ihp>。';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets 声明缺少 src。';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups 声明缺少 src。';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return '不支持的 keymaps 模式：$mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'instance 声明缺少 src。';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg 未注册实例。';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree 根元素必须是 <instance-profile>。';

  @override
  String get diagnosticWritersideTreeMissingId => '实例配置文件缺少 id。';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return '树文件名（不含扩展名）与实例 ID“$id”不匹配。';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage => '非库实例缺少 start-page。';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return '起始页“$startPage”不存在。';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return '主题“$topic”在此实例目录中出现多次。';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      '变量声明必须包含名称和值。';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return '变量“$name”被声明了多次。';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => '类别缺少 id。';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return '类别“$id”被声明了多次。';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return '类别顺序“$order”被声明了多次。';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot => '.topic 根元素必须是 <topic>。';

  @override
  String get diagnosticWritersideTopicMissingRootId => 'XML 主题缺少根 id。';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML 主题根 ID“$id”必须与文件名“$expectedId”匹配。';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return '元素 ID“$elementId”出现多次。';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a> 缺少 href。';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside 模式需要 writerside.cfg。';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return '配置的构建配置目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return '配置的 API 规范目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return '配置的 snippets 目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return '配置的变量文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return '配置的类别文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return '配置的实例组文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return '已注册的实例树“$source”不存在。';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return '无法读取主题文件：$error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return '默认主题目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return '配置的主题目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return '配置的图像目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return '元素 ID“$id”出现多次。';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return '目录引用了缺失的主题“$topic”。';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return '外部 href“$href”无效。';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return '变量“%$name%”未声明。';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return '主题链接“$destination”无法解析。';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return '“$targetName”中不存在锚点“$anchor”。';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom => '<include> 缺少 from。';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return '包含源“$from”不存在。';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return '“$from”中不存在包含元素“$elementId”。';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso 类别“$ref”未声明。';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return '主题引用“$reference”不明确。';
  }

  @override
  String diagnosticUnknown(String code) {
    return '未知诊断信息：$code';
  }

  @override
  String get close => '关闭';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git 差异';

  @override
  String get gitShowDiff => '显示差异';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return '旧 $oldRange → 新 $newRange';
  }

  @override
  String get gitDiffNoLines => '无行';

  @override
  String get gitUnavailableTitle => 'Git 不可用';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other': '安装 Git，或配置 BusyMark 以使用可用的 Git 可执行文件。$reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => '信任此工作区以使用 Git？';

  @override
  String get gitTrustRequiredMessage =>
      'Git 存储库可以通过 hook、过滤器和其他配置运行程序。在 BusyMark 读取存储库数据或启用 Git 操作前，请先信任此工作区。';

  @override
  String get gitTrustWorkspace => '信任工作区';

  @override
  String get gitNotRepositoryTitle => '不是 Git 存储库';

  @override
  String get gitNotRepositoryMessage => '此工作区不在 Git 存储库中。';

  @override
  String get gitInitializeRepository => '初始化存储库';

  @override
  String get gitDetachedHead => '分离的 HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return '分离于 $commit';
  }

  @override
  String get gitNoUpstream => '没有上游分支';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个未推送的提交',
      one: '1 个未推送的提交',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个待拉取的提交',
      one: '1 个待拉取的提交',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => '干净';

  @override
  String get gitConflicts => '冲突';

  @override
  String get gitChanges => '更改';

  @override
  String get gitStaged => '已暂存';

  @override
  String get gitUnstaged => '未暂存';

  @override
  String get gitHistory => '历史记录';

  @override
  String get gitBranches => '分支';

  @override
  String get gitActions => 'Git 操作';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => '暂存文件';

  @override
  String get gitRemoveFromCommit => '取消暂存文件';

  @override
  String get gitDiscard => '还原';

  @override
  String get gitOpenFile => '打开文件';

  @override
  String get gitMarkResolved => '标记为已解决';

  @override
  String get gitUntracked => '未跟踪';

  @override
  String get gitCommitMessage => '提交消息';

  @override
  String get gitCommitSelectedFiles => '选中的文件';

  @override
  String get gitCommitNoSelectedFiles => '提交前至少暂存一个文件。';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已暂存文件',
      one: '1 个已暂存文件',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => '工作区之外';

  @override
  String get gitCommitMessageRequired => '请输入提交消息。';

  @override
  String get gitCreateBranch => '创建分支';

  @override
  String get gitNewBranch => '新分支';

  @override
  String get gitBranchName => '分支名称';

  @override
  String get gitSwitchBranch => '切换';

  @override
  String get gitNoChanges => '没有更改';

  @override
  String get gitNoHistory => '没有历史记录';

  @override
  String get gitNoBranches => '没有分支';

  @override
  String get gitNoDiff => '没有可显示的差异';

  @override
  String get gitBinaryFile => '二进制文件。BusyMark 不渲染二进制补丁。';

  @override
  String gitBinaryFileInfo(int size) {
    return '二进制文件（$size 字节）。BusyMark 不渲染二进制补丁。';
  }

  @override
  String get gitUnsavedChangesBanner => '保存前不会包含未保存的编辑器更改。';

  @override
  String get gitConfirmDiscardTitle => '放弃 Git 更改？';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '选中的已跟踪文件中的所有已暂存和未暂存更改都将还原到 HEAD。',
      one: '选中的已跟踪文件中的所有已暂存和未暂存更改都将还原到 HEAD。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '选中的未跟踪文件将被删除。',
      one: '选中的未跟踪文件将被删除。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将根据其 Git 状态还原或删除选中的文件。',
      one: '将根据其 Git 状态还原或删除选中的文件。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '切换到 $branch？';
  }

  @override
  String get gitConfirmSwitchBranchMessage => 'Git 切换分支后，BusyMark 将从磁盘重新加载工作区。';

  @override
  String get gitConfirmPushSetUpstreamTitle => '设置上游分支？';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return '此分支没有上游分支。当只配置了一个远程仓库时，BusyMark 可以推送 $branch 并设置其上游分支。';
  }

  @override
  String get gitProjectHistory => '项目历史记录';

  @override
  String get gitFileHistory => '文件历史记录';

  @override
  String get gitFileHistoryRequiresOpenFile => '文件历史记录需要打开的 Markdown 文件。';

  @override
  String get gitLoadMore => '加载更多';

  @override
  String get gitChangesInCommit => '此提交中的更改';

  @override
  String get gitCompareWithCurrent => '与当前版本比较';

  @override
  String get gitRestoreVersion => '还原此版本';

  @override
  String get gitConfirmRestoreTitle => '还原此文件版本？';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark 将使用选中的已提交版本替换当前工作树中的文件。还原后的文件将保持未暂存状态。';

  @override
  String get gitCommitActions => '提交操作';

  @override
  String get gitResetCurrentBranchToHere => '将当前分支重置到此处…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '将 $branch 重置到 $commit？';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return '这会将分支 $branch 移动到提交 $commit。请选择 Git 更新索引和工作树的方式。';
  }

  @override
  String get gitReset => '重置';

  @override
  String get gitResetModeSoft => '软';

  @override
  String get gitResetModeSoftDescription =>
      '仅移动分支。保持索引和工作树不变；与选中提交之间的差异仍会保持暂存状态。';

  @override
  String get gitResetModeMixed => '混合';

  @override
  String get gitResetModeMixedDescription => '移动分支并重置索引。保持工作树不变，使差异处于未暂存状态。';

  @override
  String get gitResetModeHard => '硬';

  @override
  String get gitResetModeHardDescription =>
      '移动分支并重置索引和工作树。已跟踪的更改将被放弃；造成阻碍的未跟踪文件可能会被删除。';

  @override
  String get gitResetModeKeep => '保留';

  @override
  String get gitResetModeKeepDescription =>
      '移动分支并重置已跟踪文件，同时保留本地更改。如果这些更改与重置冲突，Git 将中止操作。';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => '文件操作';

  @override
  String get actions => '操作';

  @override
  String get gitStatusAdded => '已添加';

  @override
  String get gitStatusDeleted => '已删除';

  @override
  String get gitStatusRenamed => '已重命名';

  @override
  String get gitStatusCopied => '已复制';

  @override
  String get gitStatusUntracked => '未跟踪';

  @override
  String get gitStatusConflicted => '有冲突';

  @override
  String get gitStatusIgnored => '已忽略';

  @override
  String get gitStatusTypeChanged => '类型已更改';

  @override
  String get gitStatusModified => '已修改';

  @override
  String get gitStatusUnknown => '未知';

  @override
  String get gitErrorUnavailable => 'Git 不可用。';

  @override
  String get gitErrorNotRepository => '此工作区不是 Git 存储库。';

  @override
  String get gitErrorUnsafePath => 'BusyMark 阻止了不安全的 Git 路径。';

  @override
  String get gitErrorInvalidBranchName => '请输入有效的分支名称。';

  @override
  String get gitErrorNoRemote => '未配置 Git 远程仓库。';

  @override
  String get gitErrorNoUpstream => '未配置上游分支。';

  @override
  String get gitErrorMultipleRemotes => '配置了多个远程仓库。请在此 BusyMark 版本之外选择上游分支。';

  @override
  String get gitErrorDirtyWorkspace => '切换分支前，请保存或放弃 BusyMark 编辑器中的更改。';

  @override
  String get gitErrorResetDirtyWorkspace => '重置当前分支前，请保存或放弃 BusyMark 编辑器中的更改。';

  @override
  String get gitErrorRestoreStagedFile => '还原历史版本前，请取消暂存此文件。';

  @override
  String get gitErrorResetDetachedHead => '重置前请先检出一个分支。';

  @override
  String get gitErrorDiverged => '分支已发生分歧。请在此 BusyMark 版本之外解决合并或变基问题。';

  @override
  String get gitErrorAuthorIdentity => 'Git 需要作者姓名和邮箱地址才能提交。';

  @override
  String get gitAuthorIdentityTitle => 'Git 作者身份';

  @override
  String get gitAuthorIdentityMessage =>
      '请输入 Git 应记录在提交中的身份信息。BusyMark 将保存它并重试此次提交。';

  @override
  String get gitAuthorName => '姓名';

  @override
  String get gitAuthorEmail => 'Email';

  @override
  String get gitAuthorIdentityGlobal => '用于所有存储库';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      '作为 Snap 安装时，此设置适用于在 BusyMark 中打开的存储库。';

  @override
  String get gitSaveIdentityAndCommit => '保存并提交';

  @override
  String get gitErrorAuthentication => 'Git 身份验证失败。';

  @override
  String get gitErrorNetwork => 'Git 网络操作失败。';

  @override
  String get gitErrorConflict => 'Git 报告存在未解决的冲突。';

  @override
  String get gitErrorCommandFailed => 'Git 命令失败。';

  @override
  String get markdownAndHtml => 'Markdown 和 HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown 块';

  @override
  String get markdownHtmlMarkdownBlocksDescription => 'Markdown 源代码和预览中支持的块结构。';

  @override
  String get markdownHtmlInlineFormatting => '行内 Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription => '可出现在段落、列表项和表格单元格中的格式。';

  @override
  String get markdownHtmlRawHtmlBlocks => '原始 HTML 块';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      '通过 BusyMark 预览组件渲染的安全块级 HTML 标签。';

  @override
  String get markdownHtmlRawHtmlInline => '原始 HTML 行内标签';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      '安全的行内 HTML 标签，渲染时不会显示字面标签。';

  @override
  String get markdownHtmlSafety => '安全规则';

  @override
  String get markdownHtmlSafetyDescription => '原始 HTML 会在预览前进行解析和清理。';

  @override
  String get markdownHtmlHeadings => '标题';

  @override
  String get markdownHtmlParagraphs => '段落';

  @override
  String get markdownHtmlLists => '列表';

  @override
  String get markdownHtmlHtmlContainers => '容器';

  @override
  String get markdownHtmlHtmlTextBlocks => '文本块';

  @override
  String get markdownHtmlHtmlFigures => '图和图像';

  @override
  String get markdownHtmlHtmlPreformatted => '预格式化代码';

  @override
  String get markdownHtmlHtmlDisclosure => '折叠块';

  @override
  String get markdownHtmlHtmlDescriptionLists => '描述列表';

  @override
  String get markdownHtmlHtmlFormattingTags => '格式标签';

  @override
  String get markdownHtmlHtmlInlineCodeTags => '行内代码标签';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => '语义文本标签';

  @override
  String get markdownHtmlSanitizedPreview => '已清理的预览';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      '允许的 HTML 会转换为 BusyMark 预览块，而不是在浏览器中渲染。';

  @override
  String get markdownHtmlSourcePreserved => '保留源代码';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      '未经编辑的原始 HTML 会按源文本原样保存。';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'HTML 内的 Markdown';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      '原始 HTML 内的 Markdown 标记会按字面文本渲染。';

  @override
  String get markdownHtmlBlockedContent => '被阻止的活动内容';

  @override
  String get markdownHtmlBlockedContentDescription =>
      '脚本、样式、框架、表单、SVG、MathML、事件和不安全属性都会被阻止。';

  @override
  String get markdownHtmlSafeUrls => '仅允许安全 URL';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      '链接允许 http、https、mailto、tel、相对路径和片段 URL；不安全的 scheme 会被阻止。';

  @override
  String get exportAsPdf => '导出为 PDF';

  @override
  String get pdfExportDescription => '选择页面布局，生成精美且自包含的 PDF。';

  @override
  String get pdfRemoteImagesNote => '导出过程中不会下载远程图像。有可用的本地图像时将包含它们。';

  @override
  String get pdfPageSize => '页面大小';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => '方向';

  @override
  String get pdfPortrait => '纵向';

  @override
  String get pdfLandscape => '横向';

  @override
  String get pdfMargins => '页边距';

  @override
  String get pdfMarginNarrow => '窄';

  @override
  String get pdfMarginNormal => '普通';

  @override
  String get pdfMarginWide => '宽';

  @override
  String get pdfIncludePageNumbers => '包含页码';

  @override
  String get export => '导出';

  @override
  String get exportingPdf => '正在导出 PDF…';

  @override
  String get fileTypePdf => 'PDF 文档';

  @override
  String pdfExported(String fileName) {
    return '已导出 $fileName。';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条警告',
      one: '1 条警告',
    );
    return '$fileName 已导出，包含 $_temp0。';
  }

  @override
  String get pdfExportUnavailable => '缺少 PDF 导出组件。请重新安装 BusyMark 后重试。';

  @override
  String get pdfExportTimedOut => 'PDF 导出耗时过长，已停止。';

  @override
  String get pdfExportFailed => 'BusyMark 无法将此文档导出为 PDF。';

  @override
  String get visualizationRendering => '正在渲染…';

  @override
  String get visualizationStale => '正在显示上次有效的渲染结果';

  @override
  String get visualizationShowSource => '显示源代码';

  @override
  String get visualizationShowRender => '显示渲染结果';

  @override
  String get visualizationFitWidth => '适应宽度';

  @override
  String get visualizationSaveImage => '保存图像';

  @override
  String get visualizationCopyImage => '复制图像';

  @override
  String get visualizationImageCopied => '图像已复制';

  @override
  String get visualizationOpenApiReference => '打开 API 参考';

  @override
  String get visualizationValid => '有效';

  @override
  String get visualizationInvalid => '无效';

  @override
  String get visualizationServers => '服务器';

  @override
  String get visualizationPaths => '路径';

  @override
  String get visualizationOperations => '操作';

  @override
  String get visualizationTags => '标签';

  @override
  String get visualizationNoOperations => '没有匹配的操作';

  @override
  String get visualizationSearchOperations => '搜索操作';

  @override
  String get visualizationRenderFailed => '无法渲染此可视化内容。';

  @override
  String get visualizationRetry => '重试';

  @override
  String visualizationSaved(String fileName) {
    return '已保存 $fileName';
  }

  @override
  String get shortcutExportPdfDescription => '将当前文档或 Writerside 模块导出为 PDF。';

  @override
  String get instances => '实例';

  @override
  String get newInstance => '新建实例';

  @override
  String get newTocLibrary => '新建目录库';

  @override
  String get editInstance => '编辑实例';

  @override
  String get openTocFile => '打开目录文件';

  @override
  String get createInstance => '创建实例';

  @override
  String get createTocLibrary => '创建目录库';

  @override
  String get instanceContent => '内容';

  @override
  String get instanceContentSource => '创建来源';

  @override
  String get emptyInstance => '空实例';

  @override
  String get markdownFiles => '本地 Markdown 文件';

  @override
  String get chooseMarkdownFolder => '选择 Markdown 文件夹';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      '选择包含 Markdown 文件的文件夹。';

  @override
  String get instanceAppearance => '外观';

  @override
  String get instanceColor => '图标颜色';

  @override
  String get instanceVersion => '版本';

  @override
  String instanceVersionInherited(String version) {
    return '此字段为空时，项目版本为 $version。';
  }

  @override
  String get instanceWebPath => 'Web 路径';

  @override
  String get instanceStatus => '状态';

  @override
  String get instanceStatusRelease => '发布';

  @override
  String get instanceStatusEap => '抢先体验';

  @override
  String get instanceStatusDeprecated => '已弃用';

  @override
  String get allowSearchEngineIndexing => '允许搜索引擎建立索引';

  @override
  String get allowSearchEngineIndexingDescription => '允许外部搜索引擎为此输出建立索引。';

  @override
  String get offlineArtifact => '离线构件';

  @override
  String get offlineArtifactDescription => '捆绑资源，使构建的文档可以自包含。';

  @override
  String get instanceOutputSettings => '输出设置';

  @override
  String get markdownImportSource => 'Markdown 源';

  @override
  String get markdownImportFiles => 'Markdown 文件';

  @override
  String get selectNone => '全部取消选择';

  @override
  String markdownFilesFound(int count) {
    return '找到 $count 个 Markdown 文件';
  }

  @override
  String get noMarkdownFilesFound => '在此目录中未找到 Markdown 文件。';

  @override
  String get copyReferencedMedia => '复制引用的媒体';

  @override
  String get copyReferencedMediaDescription => '复制选中文件引用的本地图像和视频，同时保留相对路径。';

  @override
  String get instanceIdRenameWarningTitle => '重命名实例 ID？';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark 将重命名 .tree 文件，并将 Writerside 项目引用从“$oldId”更新为“$newId”。发布脚本不会更改，必须单独更新。';
  }

  @override
  String get renameAndUpdateReferences => '重命名并更新引用';

  @override
  String get tocLibraryDescription => '目录库用于存储可复用的节，不会生成自己的输出。';

  @override
  String get defaultTocLibraryName => '共享目录';

  @override
  String get instanceColorAutomatic => '自动';

  @override
  String get instanceColorBlue => '蓝色';

  @override
  String get instanceColorGreen => '绿色';

  @override
  String get instanceColorOrange => '橙色';

  @override
  String get instanceColorPurple => '紫色';

  @override
  String get instanceColorRed => '红色';

  @override
  String get instanceColorTeal => '青绿色';

  @override
  String get instanceColorYellow => '黄色';

  @override
  String get errorWritersideInstanceNameRequired => '请输入实例名称。';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return '已存在 ID 为“$id”的实例。';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return '实例树已存在：$path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown 源目录不存在：$path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      '请选择至少一个 Markdown 文件进行导入。';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return '选中的源中有一个不是可读取的 Markdown 文件：$path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return '导入将覆盖现有项目文件：$path';
  }

  @override
  String get errorWritersideInstanceFilesChanged => '实例文件已在磁盘上发生变化。请查看后重试。';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark 无法完全回滚实例更改。请在继续前查看这些文件：$paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport => '目录库无法导入 Markdown 主题。';

  @override
  String get errorWritersideInstanceWebPathInvalid => 'Web 路径必须为单行文本。';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside 实例配置无效。请修正其诊断信息后重试。';

  @override
  String get errorWritersideInstanceTemporaryFile => 'BusyMark 无法安全暂存实例更改。';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return '未知的实例状态“$status”。请使用 release、eap 或 deprecated。';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return '实例 ID“$id”被多个树文件使用。';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml 必须包含 <buildprofiles> 根元素。';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '$name 值“$value”必须为 true 或 false。';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      '<build-profile> 元素必须指定实例 ID。';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      '树中的 <include> 必须同时指定 from 和 element-id。';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      '树中的 <snippet> 必须指定 id。';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      '跨实例目录引用必须同时指定 ref 和 in。';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      '目录元素不能同时指向多个主题、引用、链接或重定向。';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return '树元素 ID“$id”被声明了多次。';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      '实例组文件必须包含 <instance-groups> 根元素。';

  @override
  String get diagnosticWritersideInstanceGroupInvalid => '实例组必须指定非空 ID 和实例列表。';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return '实例组 ID“$id”被声明了多次。';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return '目录包含项“$source#$id”属于外部模块“$origin”，无法在此工作区中展开。';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return '已注册树“$source”中不存在树元素“$id”。';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return '树包含项“$source#$id”创建了循环。';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return '实例条件引用了未知组“@$group”。';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return '跨实例引用指向未知实例“$instance”。';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return '主题“$topic”不在被引用的实例“$instance”中。';
  }

  @override
  String get download => '下载';

  @override
  String get exportWritersideAsPdf => '将 Writerside 导出为 PDF';

  @override
  String get writersidePdfContent => '导出内容';

  @override
  String get writersidePdfPage => '页面';

  @override
  String get exportingWritersidePdf => '正在导出 Writerside PDF…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => '本地 Ollama';

  @override
  String get aiDisabled => '已禁用';

  @override
  String get aiExplicitEditingDescription =>
      'AI 编辑需要明确发起。BusyMark 只会将所选提供商对应的显示上下文发送出去，且不会在未经审核的情况下应用建议。';

  @override
  String get aiProvider => 'AI 提供商';

  @override
  String get aiDefaultProvider => '默认提供商';

  @override
  String get aiConfigureProvider => '配置提供商';

  @override
  String get aiChooseProvider => '选择 AI 提供商';

  @override
  String get aiOllamaEndpoint => 'Ollama 端点';

  @override
  String get aiOllamaModel => 'Ollama 模型';

  @override
  String get aiTestConnection => '测试连接';

  @override
  String get aiTestingConnection => '正在测试…';

  @override
  String aiConnectionReady(int count) {
    return '已连接。找到 $count 个已安装模型。';
  }

  @override
  String get aiNoModels => '未选择模型。';

  @override
  String get aiConnectionFailed => 'BusyMark 无法验证 AI 文本生成。';

  @override
  String get aiConfigureFirst => '请先在设置 → AI 中启用 AI 提供商并验证模型。';

  @override
  String get aiEditWithAi => '使用 AI 编辑';

  @override
  String get aiRefineWithAi => '使用 AI 优化';

  @override
  String get aiInstruction => '指令';

  @override
  String get aiChangeTarget => '可更改内容';

  @override
  String get aiSharedContext => '与 AI 共享的上下文';

  @override
  String get aiTargetSelection => '选中的内容';

  @override
  String get aiTargetInsertAfterBlock => '插入到当前块之后';

  @override
  String get aiTargetCurrentBlock => '当前块';

  @override
  String get aiTargetCurrentSection => '当前节';

  @override
  String get aiTargetCompleteDocument => '完整文档';

  @override
  String get aiContextNone => '没有文档上下文';

  @override
  String get aiContextSelection => '选中的内容';

  @override
  String get aiContextCurrentBlock => '当前块';

  @override
  String get aiContextCurrentSection => '当前节';

  @override
  String get aiContextCompleteDocument => '完整文档';

  @override
  String get aiGenerating => '正在生成建议…';

  @override
  String get aiProposal => 'AI 建议';

  @override
  String get aiGenerateProposal => '生成建议';

  @override
  String aiContextDisclosure(int count) {
    return '所选提供商将接收显示上下文中的 $count 个字符。';
  }

  @override
  String get aiOriginal => '原始内容';

  @override
  String get aiSuggested => '建议内容';

  @override
  String get aiApplyProposal => '应用建议';

  @override
  String aiTokenUsage(int input, int output) {
    return '输入 token：$input · 输出 token：$output';
  }

  @override
  String get aiStaleProposal => '生成此建议期间文档发生了变化。请重新执行操作。';

  @override
  String get gitAiStagedChangesChanged => '生成此提交消息期间，已暂存的更改发生了变化。请重新执行操作。';

  @override
  String get aiViewContext => '查看已发送的上下文';

  @override
  String get aiReviewExactContent => '查看确切内容';

  @override
  String get aiContentToChange => '要更改的内容';

  @override
  String get aiContentSentToAi => '发送给 AI 的内容';

  @override
  String get aiApiKey => 'API 密钥';

  @override
  String get aiApiKeyStoredHint => '密钥已存储在系统凭据存储中';

  @override
  String get aiApiKeyEnterHint => '输入提供商 API 密钥';

  @override
  String get aiReplaceApiKey => '替换 API 密钥';

  @override
  String get aiSaveApiKey => '安全保存 API 密钥';

  @override
  String get aiRemoveApiKey => '移除已保存的 API 密钥';

  @override
  String get aiCredentialSaved => 'API 密钥已保存到系统凭据存储中。';

  @override
  String get aiCredentialRemoved => '已移除保存的 API 密钥。';

  @override
  String get aiModelRouting => '模型路由';

  @override
  String get aiAutomaticRouting => '按任务自动选择';

  @override
  String get aiFixedModelRouting => '使用选中的模型';

  @override
  String get aiPreferredModel => '首选模型';

  @override
  String get aiModel => '模型';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests 个请求 · $input 个输入 token · $output 个输出 token';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '将内容发送给 $provider？';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '启用 $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      '只会发送每个 AI 审核对话框中显示的内容。请求不保存状态，建议需要审核，API 密钥存储在 Linux 系统凭据存储中。';

  @override
  String aiCloudConsentRequired(String provider) {
    return '请先在设置 → AI 中确认与 $provider 共享数据。';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return '已通过 $model 验证生成能力。有 $count 个兼容模型可用。';
  }

  @override
  String get aiColdStartObserved => '检测到本地模型冷启动。';

  @override
  String get aiNoCompatibleModels => '没有可用的兼容文本生成模型。';

  @override
  String get aiEnableProvider => '请先启用 AI 提供商。';

  @override
  String get aiDraftCommitMessage => '起草提交消息';

  @override
  String get aiDrafting => '正在起草…';

  @override
  String get aiDraftWithAi => '使用 AI 起草';

  @override
  String get generateOrUpdateMarkdownToc => '生成/更新目录';

  @override
  String get markdownTocTitle => '目录';

  @override
  String markdownTocUpdated(int count) {
    return '目录已更新，包含 $count 个条目。';
  }

  @override
  String get markdownTocNoHeadings => '请先添加至少一个节标题，再生成目录。';

  @override
  String get markdownTocMalformedMarkers => 'BusyMark 目录标记缺失、重复或顺序错误。';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return '标题级别 $level 跟在级别 $previousLevel 之后；请检查节的嵌套结构。';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText => '链接文本为空；请提供能描述其用途的可访问名称。';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return '请检查链接文本“$text”是否在上下文中描述了其用途。';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader => '表头单元格必须标识其列；请补全每个空表头。';

  @override
  String get mathRenderFailed => '无法渲染数学表达式。';

  @override
  String get inlineMath => '行内数学';

  @override
  String get displayMath => '显示数学';
}

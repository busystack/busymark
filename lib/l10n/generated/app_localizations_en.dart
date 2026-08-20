// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get feedbackReplyEmail => 'Reply email (optional)';

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
  String get preview => 'Preview';

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
  String get languageItalian => 'Italiano';

  @override
  String get languageNorwegian => 'Norsk';

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
  String get languageEstonian => 'Eesti';

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
  String get sourceSearchInvalidRegex => 'Invalid regular expression';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Large file: highlighting and folding are paused';

  @override
  String get noPreview => 'No preview';

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
      '<include> is missing from.';

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
  String get gitErrorAuthentication =>
      'Git authentication failed. In the snap, SSH remotes may require connecting the ssh-keys interface.';

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
    return '$fileName was exported with $count warning(s).';
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
    return '$count Markdown file(s) found';
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
  String get writersidePdfExportDescription =>
      'Choose an instance and PDF settings. BusyMark uses JetBrains’ official Writerside builder.';

  @override
  String get writersidePdfContent => 'Export content';

  @override
  String get writersidePdfSettings => 'PDF settings';

  @override
  String get writersidePdfConfigureHere => 'Configure for this export';

  @override
  String get writersidePdfProjectConfiguration => 'Use project configuration';

  @override
  String get writersidePdfConfigurationFile => 'PDF configuration file';

  @override
  String get writersidePdfPage => 'Page';

  @override
  String get writersidePdfKeymap => 'Keymap';

  @override
  String get writersidePdfNoKeymap => 'No keymap';

  @override
  String get writersidePdfTocTitle => 'Table of contents title';

  @override
  String get writersidePdfCover => 'Cover page';

  @override
  String get writersidePdfIncludeCover => 'Include cover page';

  @override
  String get writersidePdfCoverTitle => 'Cover title';

  @override
  String get writersidePdfCoverDescription => 'Cover description';

  @override
  String get writersidePdfCopyright => 'Copyright';

  @override
  String get writersidePdfCoverLogo => 'Cover logo';

  @override
  String get writersidePdfChooseCoverLogo => 'Choose cover logo';

  @override
  String get writersidePdfHeaderAndFooter => 'Header and footer';

  @override
  String get writersidePdfHeader => 'Header';

  @override
  String get writersidePdfFooter => 'Footer';

  @override
  String get writersidePdfAdvancedDescription =>
      'These values map the opened module to the builder’s source layout.';

  @override
  String get writersidePdfModuleName => 'Module name';

  @override
  String get writersidePdfSourceRoot => 'Source root';

  @override
  String get writersidePdfChooseSourceRoot => 'Choose source root';

  @override
  String get writersidePdfBuilderVersion => 'Builder version';

  @override
  String get writersidePdfAllowNetwork => 'Allow network during build';

  @override
  String get writersidePdfAllowNetworkDescription =>
      'Disabled by default. Enable only when the project intentionally needs remote build resources.';

  @override
  String get writersidePdfModuleNameRequired => 'Enter the module name.';

  @override
  String get writersidePdfSourceRootRequired => 'Choose the source root.';

  @override
  String get writersidePdfBuilderVersionInvalid =>
      'Enter a valid builder version.';

  @override
  String get writersidePdfBuilderRequired => 'Writerside builder required';

  @override
  String writersidePdfBuilderDownloadDescription(String image) {
    return 'BusyMark uses the official $image container image. Download it now? The image is large and is stored by Docker.';
  }

  @override
  String get writersidePdfDownloadingBuilder =>
      'Downloading Writerside builder…';

  @override
  String get exportingWritersidePdf => 'Exporting Writerside PDF…';

  @override
  String get writersidePdfDockerUnavailable =>
      'Docker is required for Writerside PDF export. Install and start Docker, then try again.';

  @override
  String get writersidePdfBuilderUnavailable =>
      'The requested Writerside builder image is not available.';

  @override
  String get writersidePdfConfigurationInvalid =>
      'The Writerside PDF configuration is invalid.';

  @override
  String get writersidePdfBuildFailed =>
      'The Writerside builder could not create the PDF.';

  @override
  String get writersidePdfInvalidOutput =>
      'The Writerside builder did not produce a valid PDF.';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'Local Ollama';

  @override
  String get aiDisabled => 'Disabled';

  @override
  String get aiLocalOnlyDescription =>
      'AI editing is explicit. BusyMark sends only the context shown for the selected provider and never applies a proposal without review.';

  @override
  String get aiProvider => 'AI provider';

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
    return 'Connected. $count installed model(s) found.';
  }

  @override
  String get aiNoModels =>
      'Ollama is running, but no installed models were found.';

  @override
  String get aiConnectionFailed =>
      'BusyMark could not verify AI text generation.';

  @override
  String get aiConfigureFirst =>
      'Enable an AI provider and verify a model in Settings → AI.';

  @override
  String get aiRewrite => 'Rewrite';

  @override
  String get aiShorten => 'Shorten';

  @override
  String get aiSummarize => 'Summarize';

  @override
  String get aiChangeTone => 'Change tone…';

  @override
  String get aiTranslate => 'Translate…';

  @override
  String get aiProofread => 'Proofread';

  @override
  String get aiDraft => 'Draft…';

  @override
  String get aiSelectionRequired => 'Select text for this AI action.';

  @override
  String get aiTonePrompt => 'Describe the target tone';

  @override
  String get aiLanguagePrompt => 'Target language';

  @override
  String get aiDraftPrompt => 'What should BusyMark draft?';

  @override
  String get aiGenerating => 'Generating proposal…';

  @override
  String get aiProposal => 'AI proposal';

  @override
  String aiContextDisclosure(int count) {
    return 'The selected provider will receive $count characters from the displayed context.';
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
  String get aiPrivacyDisabled =>
      'AI is disabled. BusyMark never sends document content without an explicit AI action.';

  @override
  String get aiPrivacyLocal =>
      'BusyMark sends only the context shown in the review dialog to the configured loopback Ollama service. Proposals are never applied without review.';

  @override
  String aiPrivacyCloud(String provider) {
    return 'BusyMark sends only the context shown in the review dialog to $provider. Requests are stateless and proposals are never applied without review.';
  }

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
    return 'Generation verified with $model. $count compatible model(s) available.';
  }

  @override
  String get aiColdStartObserved => 'A local model cold start was observed.';

  @override
  String get aiNoCompatibleModels =>
      'No compatible text-generation model is available.';

  @override
  String get aiEnableProvider => 'Enable an AI provider first.';

  @override
  String get aiExplainCode => 'Explain code';

  @override
  String get aiImproveCode => 'Improve code';

  @override
  String get aiDraftCommitMessage => 'Draft commit message';

  @override
  String get aiCodeBlockRequired =>
      'Place the cursor in a fenced code block first.';

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
    return 'Table of contents updated with $count entries.';
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
}

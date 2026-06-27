import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// Application name.
  ///
  /// In en, this message translates to:
  /// **'BusyMark'**
  String get appTitle;

  /// Short application description.
  ///
  /// In en, this message translates to:
  /// **'Markdown and Writerside-compatible documentation editor.'**
  String get appSubtitle;

  /// Menu item and tooltip for the About dialog.
  ///
  /// In en, this message translates to:
  /// **'About BusyMark'**
  String get aboutBusyMark;

  /// Short tagline shown under the app name in the About dialog.
  ///
  /// In en, this message translates to:
  /// **'Markdown and Writerside Editor'**
  String get aboutTagline;

  /// Label for the license row in the About dialog.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicenseLabel;

  /// Formal license name shown in the About dialog. Keep the legal license name exact.
  ///
  /// In en, this message translates to:
  /// **'Apache License 2.0'**
  String get aboutLicenseName;

  /// Label for the website row in the About dialog.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutWebsite;

  /// Label for the issue tracker row in the About dialog.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get aboutReportIssue;

  /// Settings section title for advanced actions.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// Settings section title for appearance options.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Button label that applies a dialog change.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Tooltip for navigating back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Editing button position option.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get bottomLeft;

  /// Editing button position option.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get bottomRight;

  /// Cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button label for choosing a file or path.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// File picker confirmation label for choosing a directory.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get chooseLocation;

  /// Copy command label.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Create action label.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Progress label while a project or topic is being created.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// Cut command label.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// Discard unsaved changes button label.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Editor view label.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// Generic file kind label.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Find command label.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// Folder kind label.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// Insert button label.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// Keyboard shortcuts dialog title and menu item.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcuts;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Native header bar main menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// Markdown format label.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get markdown;

  /// Open action label.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// Outline sidebar tab label.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get outline;

  /// Button label for overwriting a changed file.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// Paste command label.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Plain text paste command label.
  ///
  /// In en, this message translates to:
  /// **'Paste without formatting'**
  String get pasteWithoutFormatting;

  /// Preview view label.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Recent workspaces section title.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// Redo command label.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Save action label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Search action label and field hint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Select all command label.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Settings action label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Source view label.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// Split view label.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// System theme option.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// Theme setting label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Application language setting label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appLanguage;

  /// Language selector option that follows the operating system locale.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// Language selector option for English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language selector option for German.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Language selector option for Italian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// Language selector option for Norwegian.
  ///
  /// In en, this message translates to:
  /// **'Norsk'**
  String get languageNorwegian;

  /// Language selector option for French.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Language selector option for Russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// Language selector option for Ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get languageUkrainian;

  /// Language selector option for Polish.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get languagePolish;

  /// Language selector option for Spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Language selector option for Portuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// Language selector option for Arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Language selector option for Persian.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get languagePersian;

  /// Language selector option for Hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// Native header bar sidebar toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get toggleSidebar;

  /// Editing button position option.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get topLeft;

  /// Editing button position option.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get topRight;

  /// Undo command label.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Validate action label.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// Settings section title for validation options.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get validation;

  /// Native header bar view mode control label.
  ///
  /// In en, this message translates to:
  /// **'View mode'**
  String get viewMode;

  /// Welcome screen label and tooltip.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Writerside workspace kind label.
  ///
  /// In en, this message translates to:
  /// **'Writerside'**
  String get writerside;

  /// XML format label.
  ///
  /// In en, this message translates to:
  /// **'XML'**
  String get xml;

  /// Native file picker type label for Markdown files.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get fileTypeMarkdown;

  /// Native file picker type label for images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get fileTypeImages;

  /// Action label for opening a Markdown file.
  ///
  /// In en, this message translates to:
  /// **'Open Markdown File'**
  String get openMarkdownFile;

  /// Subtitle describing supported Markdown file extensions.
  ///
  /// In en, this message translates to:
  /// **'.md or .markdown'**
  String get markdownFileExtensions;

  /// Action label for opening a folder or Writerside project.
  ///
  /// In en, this message translates to:
  /// **'Open Folder or Writerside Project'**
  String get openFolderOrWritersideProject;

  /// Subtitle describing supported folder workspace types.
  ///
  /// In en, this message translates to:
  /// **'Markdown folder or Writerside-compatible project'**
  String get markdownFolderOrWritersideProject;

  /// Keyboard shortcut group for file commands.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get shortcutGroupFile;

  /// Keyboard shortcut label for creating a document.
  ///
  /// In en, this message translates to:
  /// **'New document'**
  String get shortcutNewDocument;

  /// Keyboard shortcut description for creating a document.
  ///
  /// In en, this message translates to:
  /// **'Create a new unsaved Markdown document'**
  String get shortcutNewDocumentDescription;

  /// Keyboard shortcut description for opening content.
  ///
  /// In en, this message translates to:
  /// **'Open a Markdown file, folder, or Writerside project'**
  String get shortcutOpenDescription;

  /// Keyboard shortcut description for saving content.
  ///
  /// In en, this message translates to:
  /// **'Save the current Markdown file'**
  String get shortcutSaveDescription;

  /// Keyboard shortcut description for search.
  ///
  /// In en, this message translates to:
  /// **'Search the current document'**
  String get shortcutFindDescription;

  /// Keyboard shortcut description for opening shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Show this keyboard shortcut reference'**
  String get shortcutKeyboardShortcutsDescription;

  /// Keyboard shortcut group for text editing commands.
  ///
  /// In en, this message translates to:
  /// **'Text Editing'**
  String get shortcutGroupTextEditing;

  /// Keyboard shortcut description for selecting all text.
  ///
  /// In en, this message translates to:
  /// **'Select all editor text'**
  String get shortcutSelectAllDescription;

  /// Keyboard shortcut description for cut.
  ///
  /// In en, this message translates to:
  /// **'Cut the selected text'**
  String get shortcutCutDescription;

  /// Keyboard shortcut description for copy.
  ///
  /// In en, this message translates to:
  /// **'Copy the selected text'**
  String get shortcutCopyDescription;

  /// Keyboard shortcut description for paste.
  ///
  /// In en, this message translates to:
  /// **'Paste from the clipboard'**
  String get shortcutPasteDescription;

  /// Keyboard shortcut description for plain text paste.
  ///
  /// In en, this message translates to:
  /// **'Paste clipboard text without formatting'**
  String get shortcutPastePlainTextDescription;

  /// Keyboard shortcut description for undo.
  ///
  /// In en, this message translates to:
  /// **'Undo the last edit'**
  String get shortcutUndoDescription;

  /// Keyboard shortcut description for redo.
  ///
  /// In en, this message translates to:
  /// **'Redo the last undone edit'**
  String get shortcutRedoDescription;

  /// Keyboard shortcut label for clearing selection.
  ///
  /// In en, this message translates to:
  /// **'Clear editor selection'**
  String get clearEditorSelection;

  /// Keyboard shortcut description for clearing selection.
  ///
  /// In en, this message translates to:
  /// **'Leave the current editor selection or search focus'**
  String get shortcutClearEditorSelectionDescription;

  /// Keyboard shortcut group for inline formatting.
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get shortcutGroupFormatting;

  /// Keyboard shortcut description for bold.
  ///
  /// In en, this message translates to:
  /// **'Toggle bold on the selected text'**
  String get shortcutBoldDescription;

  /// Keyboard shortcut description for italic.
  ///
  /// In en, this message translates to:
  /// **'Toggle italic on the selected text'**
  String get shortcutItalicDescription;

  /// Keyboard shortcut description for underline.
  ///
  /// In en, this message translates to:
  /// **'Toggle underline on the selected text'**
  String get shortcutUnderlineDescription;

  /// Keyboard shortcut description for link insertion.
  ///
  /// In en, this message translates to:
  /// **'Insert or edit a link'**
  String get shortcutLinkDescription;

  /// Keyboard shortcut description for inline code.
  ///
  /// In en, this message translates to:
  /// **'Toggle inline code on the selected text'**
  String get shortcutInlineCodeDescription;

  /// Keyboard shortcut description for strikethrough.
  ///
  /// In en, this message translates to:
  /// **'Toggle strikethrough on the selected text'**
  String get shortcutStrikethroughDescription;

  /// Keyboard shortcut group for block styles.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get shortcutGroupBlocks;

  /// Keyboard shortcut description for paragraph style.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to paragraph'**
  String get shortcutParagraphDescription;

  /// Keyboard shortcut description for heading 1.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to Heading 1'**
  String get shortcutHeading1Description;

  /// Keyboard shortcut description for heading 2.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to Heading 2'**
  String get shortcutHeading2Description;

  /// Keyboard shortcut description for heading 3.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to Heading 3'**
  String get shortcutHeading3Description;

  /// Keyboard shortcut description for heading 4.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to Heading 4'**
  String get shortcutHeading4Description;

  /// Keyboard shortcut description for heading 5.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to Heading 5'**
  String get shortcutHeading5Description;

  /// Keyboard shortcut description for heading 6.
  ///
  /// In en, this message translates to:
  /// **'Set the current block to Heading 6'**
  String get shortcutHeading6Description;

  /// Keyboard shortcut group for list commands.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get shortcutGroupLists;

  /// Keyboard shortcut label for numbered list formatting.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get numberedList;

  /// Keyboard shortcut description for numbered list.
  ///
  /// In en, this message translates to:
  /// **'Toggle numbered list formatting'**
  String get shortcutNumberedListDescription;

  /// Keyboard shortcut label for bulleted list formatting.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get bulletedList;

  /// Keyboard shortcut description for bulleted list.
  ///
  /// In en, this message translates to:
  /// **'Toggle bulleted list formatting'**
  String get shortcutBulletedListDescription;

  /// Keyboard shortcut label for checklist formatting.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// Keyboard shortcut description for checklist.
  ///
  /// In en, this message translates to:
  /// **'Toggle checklist formatting'**
  String get shortcutChecklistDescription;

  /// Welcome screen action for creating a Markdown file.
  ///
  /// In en, this message translates to:
  /// **'Create Markdown File'**
  String get createMarkdownFile;

  /// Welcome screen subtitle for creating a Markdown file.
  ///
  /// In en, this message translates to:
  /// **'Start an unsaved local Markdown document'**
  String get createMarkdownFileDescription;

  /// Welcome screen action for creating a Writerside project.
  ///
  /// In en, this message translates to:
  /// **'Create Writerside Project'**
  String get createWritersideProject;

  /// Welcome screen subtitle for creating a Writerside project.
  ///
  /// In en, this message translates to:
  /// **'Start a local Writerside-compatible project'**
  String get createWritersideProjectDescription;

  /// Default project name shown in the create project dialog.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get defaultProjectName;

  /// Default Writerside instance name shown in the create project dialog.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get defaultInstanceName;

  /// Default start topic title shown in the create project dialog.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get defaultStartTopicTitle;

  /// Create project dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// Create project dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Directory name'**
  String get directoryName;

  /// Create project dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Instance name'**
  String get instanceName;

  /// Create project dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Instance ID'**
  String get instanceId;

  /// Create project dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Start topic title'**
  String get startTopicTitle;

  /// Create dialog location section label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Validation message for missing project name.
  ///
  /// In en, this message translates to:
  /// **'Project name is required.'**
  String get projectNameRequired;

  /// Validation message for missing directory name.
  ///
  /// In en, this message translates to:
  /// **'Directory name is required.'**
  String get directoryNameRequired;

  /// Validation message for unsafe directory names.
  ///
  /// In en, this message translates to:
  /// **'Use a single safe directory name.'**
  String get useSingleSafeDirectoryName;

  /// Validation message for invalid Writerside instance IDs.
  ///
  /// In en, this message translates to:
  /// **'Use a lowercase identifier with letters, numbers, underscores, or hyphens.'**
  String get useLowercaseIdentifier;

  /// Validation message for missing start topic title.
  ///
  /// In en, this message translates to:
  /// **'Start topic title is required.'**
  String get startTopicTitleRequired;

  /// Fallback error shown when Writerside project creation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create Writerside project.'**
  String get createWritersideProjectFailed;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'BusyMark Settings'**
  String get settingsTitle;

  /// Word wrap setting label.
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get wordWrap;

  /// Editor font size setting label.
  ///
  /// In en, this message translates to:
  /// **'Editor font size'**
  String get editorFontSize;

  /// Validation setting label.
  ///
  /// In en, this message translates to:
  /// **'Validate on edit'**
  String get validateOnEdit;

  /// Settings action label for clearing recent workspaces.
  ///
  /// In en, this message translates to:
  /// **'Clear recent workspaces'**
  String get clearRecentWorkspaces;

  /// Settings label for WYSIWYG editing button position.
  ///
  /// In en, this message translates to:
  /// **'Editing buttons'**
  String get editingButtons;

  /// Description for WYSIWYG editing button position setting.
  ///
  /// In en, this message translates to:
  /// **'Choose where the floating WYSIWYG editing buttons appear.'**
  String get editingButtonsDescription;

  /// Settings section title for native window behavior.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get settingsWindowSectionTitle;

  /// Settings switch title for close confirmation when documents have unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Confirm before closing with unsaved changes'**
  String get settingsConfirmCloseWithUnsavedChangesTitle;

  /// Settings switch description for close confirmation when documents have unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Ask before closing BusyMark when documents have unsaved changes.'**
  String get settingsConfirmCloseWithUnsavedChangesDescription;

  /// Window close confirmation dialog title when documents have unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get closeUnsavedChangesTitle;

  /// Window close confirmation message when one document has unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'This document has unsaved changes. Save changes before closing BusyMark?'**
  String get closeUnsavedChangesSingleMessage;

  /// Window close confirmation message when multiple documents have unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Save changes before closing BusyMark?} =1{1 document has unsaved changes. Save changes before closing BusyMark?} other{{count} documents have unsaved changes. Save changes before closing BusyMark?}}'**
  String closeUnsavedChangesMultipleMessage(int count);

  /// Cancel button label in the window close unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get closeUnsavedChangesCancel;

  /// Discard button label in the window close unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get closeUnsavedChangesDiscard;

  /// Save button label in the window close unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get closeUnsavedChangesSave;

  /// Fallback file name in unsaved changes dialog.
  ///
  /// In en, this message translates to:
  /// **'current file'**
  String get currentFile;

  /// Unsaved changes dialog title.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// Unsaved changes confirmation message.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes in {fileName}. Save them before continuing?'**
  String unsavedChangesMessage(String fileName);

  /// File changed confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'File changed on disk'**
  String get fileChangedOnDisk;

  /// File changed confirmation dialog message.
  ///
  /// In en, this message translates to:
  /// **'This file changed on disk since you opened it. Overwrite it?'**
  String get fileChangedOnDiskMessage;

  /// Display name for a new unsaved Markdown document.
  ///
  /// In en, this message translates to:
  /// **'Untitled.md'**
  String get untitledMarkdownFileName;

  /// WYSIWYG toolbar tooltip for unordered list.
  ///
  /// In en, this message translates to:
  /// **'Unordered list'**
  String get unorderedList;

  /// WYSIWYG toolbar tooltip for ordered list.
  ///
  /// In en, this message translates to:
  /// **'Ordered list'**
  String get orderedList;

  /// WYSIWYG toolbar tooltip for task list.
  ///
  /// In en, this message translates to:
  /// **'Task list'**
  String get taskList;

  /// WYSIWYG toolbar tooltip for toggling task state.
  ///
  /// In en, this message translates to:
  /// **'Toggle task checked'**
  String get toggleTaskChecked;

  /// WYSIWYG toolbar tooltip for indenting a list item.
  ///
  /// In en, this message translates to:
  /// **'Indent list item'**
  String get indentListItem;

  /// WYSIWYG toolbar tooltip for outdenting a list item.
  ///
  /// In en, this message translates to:
  /// **'Outdent list item'**
  String get outdentListItem;

  /// Blockquote command label.
  ///
  /// In en, this message translates to:
  /// **'Blockquote'**
  String get blockquote;

  /// Code block command or preview label.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get codeBlock;

  /// Dialog title and toolbar tooltip for code block language.
  ///
  /// In en, this message translates to:
  /// **'Code block language'**
  String get codeBlockLanguage;

  /// Image command and document kind label.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// Inline image command label.
  ///
  /// In en, this message translates to:
  /// **'Inline image'**
  String get inlineImage;

  /// Table command label.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// Thematic break command label.
  ///
  /// In en, this message translates to:
  /// **'Thematic break'**
  String get thematicBreak;

  /// Bold command label.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// Italic command label.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// Underline command label.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// Strikethrough command label.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get strikethrough;

  /// Inline code command label.
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get inlineCode;

  /// Link command and preview label.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// Hard line break command label.
  ///
  /// In en, this message translates to:
  /// **'Hard line break'**
  String get hardLineBreak;

  /// Text style menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get textStyle;

  /// Paragraph style label.
  ///
  /// In en, this message translates to:
  /// **'Paragraph'**
  String get paragraph;

  /// Heading 1 style label.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get heading1;

  /// Heading 2 style label.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get heading2;

  /// Heading 3 style label.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get heading3;

  /// Heading 4 style label.
  ///
  /// In en, this message translates to:
  /// **'Heading 4'**
  String get heading4;

  /// Heading 5 style label.
  ///
  /// In en, this message translates to:
  /// **'Heading 5'**
  String get heading5;

  /// Heading 6 style label.
  ///
  /// In en, this message translates to:
  /// **'Heading 6'**
  String get heading6;

  /// Compact outline badge for a heading level.
  ///
  /// In en, this message translates to:
  /// **'H{level}'**
  String headingLevelAbbreviation(int level);

  /// Tooltip for deleting a table.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get deleteTable;

  /// Tooltip for a table column control.
  ///
  /// In en, this message translates to:
  /// **'Column {columnNumber}'**
  String tableColumnNumber(int columnNumber);

  /// Menu item for inserting a table column to the left.
  ///
  /// In en, this message translates to:
  /// **'Insert column left'**
  String get insertColumnLeft;

  /// Menu item for inserting a table column to the right.
  ///
  /// In en, this message translates to:
  /// **'Insert column right'**
  String get insertColumnRight;

  /// Menu item for deleting a table column.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get deleteColumn;

  /// Tooltip for a table row control.
  ///
  /// In en, this message translates to:
  /// **'Row {rowNumber}'**
  String tableRowNumber(int rowNumber);

  /// Menu item for inserting a table row above.
  ///
  /// In en, this message translates to:
  /// **'Insert row above'**
  String get insertRowAbove;

  /// Menu item for inserting a table row below.
  ///
  /// In en, this message translates to:
  /// **'Insert row below'**
  String get insertRowBelow;

  /// Menu item for deleting a table row.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get deleteRow;

  /// Hint for an empty table header cell.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get tableHeaderHint;

  /// Hint for an empty table body cell.
  ///
  /// In en, this message translates to:
  /// **'Cell'**
  String get tableCellHint;

  /// Code block language field label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Tooltip for hiding floating editing buttons.
  ///
  /// In en, this message translates to:
  /// **'Hide editing buttons'**
  String get hideEditingButtons;

  /// Tooltip for showing floating editing buttons.
  ///
  /// In en, this message translates to:
  /// **'Show editing buttons'**
  String get showEditingButtons;

  /// Image alt text field label.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get altText;

  /// Image alt text hint.
  ///
  /// In en, this message translates to:
  /// **'Describe the image'**
  String get describeTheImage;

  /// Table dialog columns field label.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// Table dialog rows field label.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get rows;

  /// Default header text for a newly inserted table column.
  ///
  /// In en, this message translates to:
  /// **'Header {columnNumber}'**
  String tableHeaderNumber(int columnNumber);

  /// Default cell text for newly inserted table cells.
  ///
  /// In en, this message translates to:
  /// **'Cell'**
  String get tableCellDefault;

  /// Placeholder shown when an image has no source.
  ///
  /// In en, this message translates to:
  /// **'No image source'**
  String get noImageSource;

  /// Tooltip for hiding the workspace sidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar'**
  String get hideSidebar;

  /// Tooltip for showing the workspace sidebar.
  ///
  /// In en, this message translates to:
  /// **'Show sidebar'**
  String get showSidebar;

  /// Tooltip for showing the preview pane.
  ///
  /// In en, this message translates to:
  /// **'Show preview'**
  String get showPreview;

  /// Tooltip for hiding the preview pane.
  ///
  /// In en, this message translates to:
  /// **'Hide preview'**
  String get hidePreview;

  /// Workspace kind label for an unsaved Markdown file.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Markdown file'**
  String get workspaceKindUnsavedMarkdown;

  /// Workspace kind label for a single Markdown file.
  ///
  /// In en, this message translates to:
  /// **'Single Markdown file'**
  String get workspaceKindSingleMarkdown;

  /// Workspace kind label for a Markdown folder.
  ///
  /// In en, this message translates to:
  /// **'Markdown folder'**
  String get workspaceKindMarkdownFolder;

  /// Workspace kind label for a Writerside module.
  ///
  /// In en, this message translates to:
  /// **'Writerside module'**
  String get workspaceKindWritersideModule;

  /// Diagnostics dialog title.
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get problems;

  /// Count of diagnostics in the workspace.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No diagnostics} =1{1 diagnostic} other{{count} diagnostics}}'**
  String diagnosticCount(int count);

  /// Files sidebar tab label.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// Writerside table of contents sidebar tab label.
  ///
  /// In en, this message translates to:
  /// **'TOC'**
  String get toc;

  /// Workspace detail label for an unsaved Markdown file.
  ///
  /// In en, this message translates to:
  /// **'Markdown - unsaved'**
  String get markdownUnsaved;

  /// Workspace detail with kind and file count.
  ///
  /// In en, this message translates to:
  /// **'{kind} - {count, plural, =1{1 file} other{{count} files}}'**
  String workspaceDetail(String kind, int count);

  /// Empty state shown when there are no files.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// Empty state shown when there is no Writerside TOC.
  ///
  /// In en, this message translates to:
  /// **'No Writerside TOC'**
  String get noWritersideToc;

  /// Fallback label for a Writerside TOC section.
  ///
  /// In en, this message translates to:
  /// **'TOC section'**
  String get tocSection;

  /// Create new Writerside topic action label.
  ///
  /// In en, this message translates to:
  /// **'New Topic'**
  String get newTopic;

  /// Create new child Writerside topic action label.
  ///
  /// In en, this message translates to:
  /// **'New Child Topic'**
  String get newChildTopic;

  /// Default topic title in the create topic dialog.
  ///
  /// In en, this message translates to:
  /// **'New topic'**
  String get defaultNewTopicTitle;

  /// Create topic dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Topic title'**
  String get topicTitle;

  /// Create topic dialog field label.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// Validation message for missing topic title.
  ///
  /// In en, this message translates to:
  /// **'Topic title is required.'**
  String get topicTitleRequired;

  /// Validation message for missing file name.
  ///
  /// In en, this message translates to:
  /// **'File name is required.'**
  String get fileNameRequired;

  /// Validation message for unsafe file names.
  ///
  /// In en, this message translates to:
  /// **'Use a single safe file name.'**
  String get useSingleSafeFileName;

  /// Validation message for an unexpected file extension.
  ///
  /// In en, this message translates to:
  /// **'Use the {extension} extension for the selected format.'**
  String useExpectedExtension(String extension);

  /// Validation message for invalid topic IDs.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers, underscores, or hyphens before the extension.'**
  String get useIdentifierCharacters;

  /// Validation message for duplicate topic IDs.
  ///
  /// In en, this message translates to:
  /// **'Topic ID already exists.'**
  String get topicIdAlreadyExists;

  /// Fallback error shown when topic creation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create Writerside topic.'**
  String get createWritersideTopicFailed;

  /// Empty state shown when a document has no outline.
  ///
  /// In en, this message translates to:
  /// **'No outline'**
  String get noOutline;

  /// Tooltip for expanding a foldable source section.
  ///
  /// In en, this message translates to:
  /// **'Expand {kind}'**
  String expandKind(String kind);

  /// Tooltip for collapsing a foldable source section.
  ///
  /// In en, this message translates to:
  /// **'Collapse {kind}'**
  String collapseKind(String kind);

  /// Fold kind label for a section.
  ///
  /// In en, this message translates to:
  /// **'section'**
  String get foldKindSection;

  /// Fold kind label for a list.
  ///
  /// In en, this message translates to:
  /// **'list'**
  String get foldKindList;

  /// Fold kind label for a blockquote.
  ///
  /// In en, this message translates to:
  /// **'quote'**
  String get foldKindQuote;

  /// Fold kind label for an XML tag.
  ///
  /// In en, this message translates to:
  /// **'tag'**
  String get foldKindTag;

  /// Empty state shown when there is no preview.
  ///
  /// In en, this message translates to:
  /// **'No preview'**
  String get noPreview;

  /// Preview label for a note admonition.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Preview label for a tip admonition.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// Preview label for a warning admonition.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Preview label for a tabs block.
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get tabs;

  /// Preview label for a tab block.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get tab;

  /// Preview label for a procedure block.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get procedure;

  /// Preview label for a procedure step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// Preview label for a topic element.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// Preview label for a chapter element.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapter;

  /// Snackbar shown when a link target cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open {target}'**
  String couldNotOpenTarget(String target);

  /// Snackbar shown when a link target path is missing.
  ///
  /// In en, this message translates to:
  /// **'Link target not found: {targetPath}'**
  String linkTargetNotFound(String targetPath);

  /// Snackbar shown when a file type cannot be opened in the editor.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this file type in editor'**
  String get cannotOpenFileTypeInEditor;

  /// Snackbar shown when a link anchor is missing.
  ///
  /// In en, this message translates to:
  /// **'Anchor not found: {anchor}'**
  String anchorNotFound(String anchor);

  /// Diagnostics empty state.
  ///
  /// In en, this message translates to:
  /// **'No problems found'**
  String get noProblemsFound;

  /// Search empty state.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Search result subtitle with file path and line number.
  ///
  /// In en, this message translates to:
  /// **'{relativePath} - Line {lineNumber}'**
  String searchResultLine(String relativePath, int lineNumber);

  /// Fallback search result title.
  ///
  /// In en, this message translates to:
  /// **'Untitled result'**
  String get untitledResult;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Markdown file'**
  String get documentKindMarkdownFile;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Writerside Markdown topic'**
  String get documentKindWritersideMarkdownTopic;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Writerside XML topic'**
  String get documentKindWritersideXmlTopic;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Writerside tree'**
  String get documentKindWritersideTree;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Configuration file'**
  String get documentKindConfigurationFile;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Variables file'**
  String get documentKindVariablesFile;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Categories file'**
  String get documentKindCategoriesFile;

  /// Search result document kind label.
  ///
  /// In en, this message translates to:
  /// **'Resource file'**
  String get documentKindResourceFile;

  /// Workspace error message shown when opening a path fails.
  ///
  /// In en, this message translates to:
  /// **'Open failed: {error}'**
  String workspaceErrorOpenFailed(String error);

  /// Workspace error message shown when Writerside project creation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create Writerside project: {error}'**
  String workspaceErrorCreateWritersideProjectFailed(String error);

  /// Workspace error message shown when Writerside topic creation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create Writerside topic: {error}'**
  String workspaceErrorCreateWritersideTopicFailed(String error);

  /// Workspace error message shown when opening a file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String workspaceErrorCouldNotOpenFile(String error);

  /// Workspace error message shown when an untitled file needs a save location.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save this Markdown file.'**
  String get workspaceErrorChooseWhereToSaveMarkdown;

  /// Workspace error message shown when a save is blocked by external changes.
  ///
  /// In en, this message translates to:
  /// **'Save blocked: file changed on disk.'**
  String get workspaceErrorSaveBlockedFileChangedOnDisk;

  /// Workspace error message shown when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String workspaceErrorSaveFailed(String error);

  /// Workspace error message shown when validation fails.
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {error}'**
  String workspaceErrorValidationFailed(String error);

  /// Detail for a missing path error.
  ///
  /// In en, this message translates to:
  /// **'Path does not exist: {path}'**
  String errorPathDoesNotExist(String path);

  /// Detail for a non-empty target directory error.
  ///
  /// In en, this message translates to:
  /// **'Target directory already exists and is not empty: {path}'**
  String errorTargetDirectoryNotEmpty(String path);

  /// Detail for a target path that is not a directory.
  ///
  /// In en, this message translates to:
  /// **'Target path already exists and is not a directory: {path}'**
  String errorTargetPathNotDirectory(String path);

  /// Detail for a generated file conflict.
  ///
  /// In en, this message translates to:
  /// **'Generated file already exists: {path}'**
  String errorGeneratedFileAlreadyExists(String path);

  /// Detail for missing parent directory input.
  ///
  /// In en, this message translates to:
  /// **'Parent directory is required.'**
  String get errorParentDirectoryRequired;

  /// Detail for a missing parent directory.
  ///
  /// In en, this message translates to:
  /// **'Parent directory does not exist: {path}'**
  String errorParentDirectoryMissing(String path);

  /// Detail for a missing project name.
  ///
  /// In en, this message translates to:
  /// **'Project name is required.'**
  String get errorProjectNameRequired;

  /// Detail for a missing directory name.
  ///
  /// In en, this message translates to:
  /// **'Directory name is required.'**
  String get errorDirectoryNameRequired;

  /// Detail for an unsafe directory name.
  ///
  /// In en, this message translates to:
  /// **'Directory name must be a single safe path segment.'**
  String get errorDirectoryNameUnsafe;

  /// Detail for an invalid Writerside instance ID.
  ///
  /// In en, this message translates to:
  /// **'Instance ID must start with a lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens.'**
  String get errorInstanceIdInvalid;

  /// Detail for an invalid topic file name.
  ///
  /// In en, this message translates to:
  /// **'Topic file name must be a Markdown file name without path separators.'**
  String get errorTopicFileInvalid;

  /// Detail for a missing topic title.
  ///
  /// In en, this message translates to:
  /// **'Topic title is required.'**
  String get errorTopicTitleRequired;

  /// Detail for a missing Writerside module root.
  ///
  /// In en, this message translates to:
  /// **'Writerside module root does not exist: {path}'**
  String errorWritersideModuleRootMissing(String path);

  /// Detail shown when creating a topic without an open Writerside module.
  ///
  /// In en, this message translates to:
  /// **'A Writerside module must be open to create a topic.'**
  String get errorWritersideModuleNotOpen;

  /// Detail shown when creating a topic without a Writerside instance tree.
  ///
  /// In en, this message translates to:
  /// **'The Writerside module has no help instance tree.'**
  String get errorWritersideInstanceTreeMissing;

  /// Detail for a missing Writerside tree file.
  ///
  /// In en, this message translates to:
  /// **'Writerside tree file does not exist: {path}'**
  String errorWritersideTreeFileMissing(String path);

  /// Detail for a duplicate topic ID.
  ///
  /// In en, this message translates to:
  /// **'Topic ID \"{topicId}\" already exists in this help module.'**
  String errorTopicIdAlreadyExists(String topicId);

  /// Detail for an existing topic file.
  ///
  /// In en, this message translates to:
  /// **'Topic file already exists: {path}'**
  String errorTopicFileAlreadyExists(String path);

  /// Detail for a missing reference topic in a tree.
  ///
  /// In en, this message translates to:
  /// **'Reference topic is not present in the selected tree: {topic}'**
  String errorReferenceTopicMissing(String topic);

  /// Detail for an unsafe topics root directory.
  ///
  /// In en, this message translates to:
  /// **'Topics root must be a safe relative directory.'**
  String get errorTopicsRootUnsafe;

  /// Detail for an unsafe topic file name.
  ///
  /// In en, this message translates to:
  /// **'Topic file name must be a single safe path segment.'**
  String get errorTopicFileNameUnsafe;

  /// Detail for a topic file extension mismatch.
  ///
  /// In en, this message translates to:
  /// **'Topic file extension must match the selected format ({extension}).'**
  String errorTopicFileExtensionMismatch(String extension);

  /// Detail for a topic file name with invalid characters.
  ///
  /// In en, this message translates to:
  /// **'Topic file name must contain only letters, numbers, underscores, and hyphens.'**
  String get errorTopicFileNameInvalid;

  /// Fallback detail for an unknown coded application error.
  ///
  /// In en, this message translates to:
  /// **'Unknown error: {code}'**
  String errorUnknown(String code);

  /// Diagnostic shown when file metadata cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read file metadata: {error}'**
  String diagnosticWorkspaceFileStatFailed(String error);

  /// Diagnostic shown when workspace scanning skips files.
  ///
  /// In en, this message translates to:
  /// **'Large workspace detected. Some files were skipped to keep the app responsive.'**
  String get diagnosticWorkspaceScanSkipped;

  /// Diagnostic shown when a workspace entry cannot be inspected.
  ///
  /// In en, this message translates to:
  /// **'Could not inspect workspace entry: {error}'**
  String diagnosticWorkspaceScanInspectFailed(String error);

  /// Diagnostic shown when a file is too large to parse automatically.
  ///
  /// In en, this message translates to:
  /// **'File is larger than the beta auto-parse limit.'**
  String get diagnosticWorkspaceFileTooLarge;

  /// Diagnostic shown when a Markdown file cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read Markdown file: {error}'**
  String diagnosticWorkspaceFileReadFailed(String error);

  /// Markdown parser diagnostic for malformed Writerside heading attributes.
  ///
  /// In en, this message translates to:
  /// **'Malformed Writerside heading attribute block.'**
  String get diagnosticMarkdownAttributeMalformed;

  /// Markdown parser diagnostic for duplicate heading IDs.
  ///
  /// In en, this message translates to:
  /// **'Duplicate heading ID \"{id}\".'**
  String diagnosticMarkdownHeadingDuplicateId(String id);

  /// Markdown parser diagnostic for additional H1 headings in Writerside mode.
  ///
  /// In en, this message translates to:
  /// **'Additional top-level H1 headings are treated as chapters.'**
  String get diagnosticWritersideTopicH1ConvertedToChapter;

  /// Diagnostic for a Writerside Markdown topic without a title.
  ///
  /// In en, this message translates to:
  /// **'Writerside Markdown topic has no H1 or front matter title.'**
  String get diagnosticWritersideMarkdownTopicMissingTitle;

  /// Diagnostic for a Writerside XML topic without a title.
  ///
  /// In en, this message translates to:
  /// **'XML topic is missing title.'**
  String get diagnosticWritersideXmlTopicMissingTitle;

  /// Diagnostic for a Writerside topic file without a title.
  ///
  /// In en, this message translates to:
  /// **'Topic \"{fileName}\" is missing a title.'**
  String diagnosticWritersideTopicFileMissingTitle(String fileName);

  /// Markdown parser diagnostic for unclosed front matter.
  ///
  /// In en, this message translates to:
  /// **'Front matter is not closed.'**
  String get diagnosticMarkdownFrontMatterMalformed;

  /// Markdown parser diagnostic for unsafe raw HTML.
  ///
  /// In en, this message translates to:
  /// **'Unsafe HTML element.'**
  String get diagnosticMarkdownRawHtmlUnsafe;

  /// Markdown parser diagnostic for a missing link target.
  ///
  /// In en, this message translates to:
  /// **'Link target does not exist: {targetPath}'**
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath);

  /// Markdown parser diagnostic for a missing local anchor.
  ///
  /// In en, this message translates to:
  /// **'Anchor \"{anchor}\" does not exist.'**
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor);

  /// Markdown parser diagnostic for a missing image alt text.
  ///
  /// In en, this message translates to:
  /// **'Image \"{destination}\" is missing alt text.'**
  String diagnosticMarkdownImageMissingAlt(String destination);

  /// Markdown parser diagnostic for a missing image file.
  ///
  /// In en, this message translates to:
  /// **'Image does not exist: {destination}'**
  String diagnosticMarkdownImageMissingFile(String destination);

  /// XML parser diagnostic for invalid XML.
  ///
  /// In en, this message translates to:
  /// **'Invalid XML: {message}'**
  String diagnosticInvalidXml(String message);

  /// Writerside parser diagnostic for an invalid writerside.cfg root element.
  ///
  /// In en, this message translates to:
  /// **'writerside.cfg root must be <ihp>.'**
  String get diagnosticWritersideConfigInvalidRoot;

  /// Writerside parser diagnostic for a snippets declaration without src.
  ///
  /// In en, this message translates to:
  /// **'snippets declaration is missing src.'**
  String get diagnosticWritersideConfigMissingSnippetsSrc;

  /// Writerside parser diagnostic for an instance-groups declaration without src.
  ///
  /// In en, this message translates to:
  /// **'instance-groups declaration is missing src.'**
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc;

  /// Writerside parser diagnostic for an unsupported keymaps mode.
  ///
  /// In en, this message translates to:
  /// **'Unsupported keymaps mode: {mode}'**
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode);

  /// Writerside parser diagnostic for an instance declaration without src.
  ///
  /// In en, this message translates to:
  /// **'Instance declaration is missing src.'**
  String get diagnosticWritersideConfigMissingInstanceSrc;

  /// Writerside parser diagnostic for a config with no instance.
  ///
  /// In en, this message translates to:
  /// **'writerside.cfg does not register an instance.'**
  String get diagnosticWritersideConfigMissingInstance;

  /// Writerside parser diagnostic for an invalid tree root element.
  ///
  /// In en, this message translates to:
  /// **'.tree root must be <instance-profile>.'**
  String get diagnosticWritersideTreeInvalidRoot;

  /// Writerside parser diagnostic for an instance profile without id.
  ///
  /// In en, this message translates to:
  /// **'Instance profile is missing id.'**
  String get diagnosticWritersideTreeMissingId;

  /// Writerside parser diagnostic for a tree filename and ID mismatch.
  ///
  /// In en, this message translates to:
  /// **'Tree file stem does not match instance id \"{id}\".'**
  String diagnosticWritersideTreeIdMismatch(String id);

  /// Writerside parser diagnostic for a tree missing start-page.
  ///
  /// In en, this message translates to:
  /// **'Non-library instance is missing start-page.'**
  String get diagnosticWritersideTreeMissingStartPage;

  /// Writerside diagnostic for a missing start page.
  ///
  /// In en, this message translates to:
  /// **'Start page \"{startPage}\" does not exist.'**
  String diagnosticWritersideStartPageMissing(String startPage);

  /// Writerside parser diagnostic for a duplicate topic in a TOC.
  ///
  /// In en, this message translates to:
  /// **'Topic \"{topic}\" appears more than once in this instance TOC.'**
  String diagnosticWritersideTreeDuplicateTopic(String topic);

  /// Writerside parser diagnostic for a malformed variable declaration.
  ///
  /// In en, this message translates to:
  /// **'Variable declaration must have name and value.'**
  String get diagnosticWritersideVariableMalformedDeclaration;

  /// Writerside parser diagnostic for a duplicate variable name.
  ///
  /// In en, this message translates to:
  /// **'Variable \"{name}\" is declared more than once.'**
  String diagnosticWritersideVariableDuplicateName(String name);

  /// Writerside parser diagnostic for a category without id.
  ///
  /// In en, this message translates to:
  /// **'Category is missing id.'**
  String get diagnosticWritersideCategoryMissingId;

  /// Writerside parser diagnostic for a duplicate category ID.
  ///
  /// In en, this message translates to:
  /// **'Category \"{id}\" is declared more than once.'**
  String diagnosticWritersideCategoryDuplicateId(String id);

  /// Writerside parser diagnostic for a duplicate category order.
  ///
  /// In en, this message translates to:
  /// **'Category order \"{order}\" is declared more than once.'**
  String diagnosticWritersideCategoryDuplicateOrder(String order);

  /// Writerside parser diagnostic for an invalid XML topic root.
  ///
  /// In en, this message translates to:
  /// **'.topic root must be <topic>.'**
  String get diagnosticWritersideTopicInvalidRoot;

  /// Writerside parser diagnostic for an XML topic missing root id.
  ///
  /// In en, this message translates to:
  /// **'XML topic is missing root id.'**
  String get diagnosticWritersideTopicMissingRootId;

  /// Writerside parser diagnostic for an XML topic root ID mismatch.
  ///
  /// In en, this message translates to:
  /// **'XML topic root id \"{id}\" must match filename \"{expectedId}\".'**
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId);

  /// Writerside parser diagnostic for a duplicate XML element ID.
  ///
  /// In en, this message translates to:
  /// **'Element id \"{elementId}\" appears more than once.'**
  String diagnosticWritersideTopicDuplicateElementId(String elementId);

  /// Writerside parser diagnostic for an anchor without href.
  ///
  /// In en, this message translates to:
  /// **'<a> is missing href.'**
  String get diagnosticWritersideTopicAnchorMissingHref;

  /// Writerside module diagnostic for a missing writerside.cfg.
  ///
  /// In en, this message translates to:
  /// **'Writerside mode requires writerside.cfg.'**
  String get diagnosticWritersideConfigMissing;

  /// Writerside module diagnostic for a missing build config directory.
  ///
  /// In en, this message translates to:
  /// **'Configured build config directory is missing: {relativePath}'**
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  );

  /// Writerside module diagnostic for a missing API specifications directory.
  ///
  /// In en, this message translates to:
  /// **'Configured API specifications directory is missing: {relativePath}'**
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  );

  /// Writerside module diagnostic for a missing snippets directory.
  ///
  /// In en, this message translates to:
  /// **'Configured snippets directory is missing: {relativePath}'**
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  );

  /// Writerside module diagnostic for a missing variables file.
  ///
  /// In en, this message translates to:
  /// **'Configured variables file is missing: {relativePath}'**
  String diagnosticWritersideConfigMissingVarsFile(String relativePath);

  /// Writerside module diagnostic for a missing categories file.
  ///
  /// In en, this message translates to:
  /// **'Configured categories file is missing: {relativePath}'**
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath);

  /// Writerside module diagnostic for a missing instance groups file.
  ///
  /// In en, this message translates to:
  /// **'Configured instance groups file is missing: {relativePath}'**
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  );

  /// Writerside module diagnostic for a missing registered instance tree.
  ///
  /// In en, this message translates to:
  /// **'Registered instance tree \"{source}\" does not exist.'**
  String diagnosticWritersideConfigMissingInstanceTree(String source);

  /// Writerside module diagnostic for a topic file read failure.
  ///
  /// In en, this message translates to:
  /// **'Could not read topic file: {error}'**
  String diagnosticWritersideTopicReadFailed(String error);

  /// Writerside module diagnostic for a missing default topics directory.
  ///
  /// In en, this message translates to:
  /// **'Default topics directory is missing: {relativePath}'**
  String diagnosticWritersideDefaultTopicsDirectoryMissing(String relativePath);

  /// Writerside module diagnostic for a missing topics directory.
  ///
  /// In en, this message translates to:
  /// **'Configured topics directory is missing: {relativePath}'**
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath);

  /// Writerside module diagnostic for a missing images directory.
  ///
  /// In en, this message translates to:
  /// **'Configured images directory is missing: {relativePath}'**
  String diagnosticWritersideImagesDirectoryMissing(String relativePath);

  /// Writerside module diagnostic for a duplicate topic element ID.
  ///
  /// In en, this message translates to:
  /// **'Element id \"{id}\" appears more than once.'**
  String diagnosticWritersideTopicDuplicateId(String id);

  /// Writerside module diagnostic for a TOC reference to a missing topic.
  ///
  /// In en, this message translates to:
  /// **'TOC references missing topic \"{topic}\".'**
  String diagnosticWritersideTreeMissingTopic(String topic);

  /// Writerside module diagnostic for an invalid external href.
  ///
  /// In en, this message translates to:
  /// **'External href \"{href}\" is invalid.'**
  String diagnosticWritersideTreeInvalidHref(String href);

  /// Writerside module diagnostic for an undeclared variable.
  ///
  /// In en, this message translates to:
  /// **'Variable \"%{name}%\" is not declared.'**
  String diagnosticWritersideVariableUnresolved(String name);

  /// Writerside module diagnostic for an unresolved topic link.
  ///
  /// In en, this message translates to:
  /// **'Topic link \"{destination}\" does not resolve.'**
  String diagnosticWritersideTopicLinkUnresolved(String destination);

  /// Writerside module diagnostic for an unresolved topic anchor.
  ///
  /// In en, this message translates to:
  /// **'Anchor \"{anchor}\" does not exist in \"{targetName}\".'**
  String diagnosticWritersideAnchorUnresolved(String anchor, String targetName);

  /// Writerside module diagnostic for an include without a from attribute.
  ///
  /// In en, this message translates to:
  /// **'<include> is missing from.'**
  String get diagnosticWritersideIncludeMissingFrom;

  /// Writerside module diagnostic for a missing include source.
  ///
  /// In en, this message translates to:
  /// **'Include source \"{from}\" does not exist.'**
  String diagnosticWritersideIncludeSourceMissing(String from);

  /// Writerside module diagnostic for a missing include element.
  ///
  /// In en, this message translates to:
  /// **'Include element \"{elementId}\" does not exist in \"{from}\".'**
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  );

  /// Writerside module diagnostic for an unresolved seealso category.
  ///
  /// In en, this message translates to:
  /// **'Seealso category \"{ref}\" is not declared.'**
  String diagnosticWritersideCategoryUnresolved(String ref);

  /// Writerside module diagnostic for an ambiguous topic reference.
  ///
  /// In en, this message translates to:
  /// **'Topic reference \"{reference}\" is ambiguous.'**
  String diagnosticWritersideTopicAmbiguousReference(String reference);

  /// Fallback text for an unknown diagnostic code.
  ///
  /// In en, this message translates to:
  /// **'Unknown diagnostic: {code}'**
  String diagnosticUnknown(String code);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'it',
    'no',
    'pl',
    'pt',
    'ru',
    'uk',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

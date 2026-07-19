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
import 'app_localizations_nb.dart';
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
    Locale('nb'),
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

  /// Menu action that stages the selected file or folder in Git.
  ///
  /// In en, this message translates to:
  /// **'Add to Git'**
  String get addToGit;

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

  /// Menu action that copies the selected file, folder, or workspace name.
  ///
  /// In en, this message translates to:
  /// **'Copy name'**
  String get copyName;

  /// Menu action that copies the selected file, folder, or workspace path.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

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

  /// Delete command label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

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

  /// Menu action and sidebar title for showing Git history for a single file.
  ///
  /// In en, this message translates to:
  /// **'File History'**
  String get fileHistory;

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

  /// Menu action that opens the selected file or folder location in the system file manager.
  ///
  /// In en, this message translates to:
  /// **'Open in Files'**
  String get openInFiles;

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

  /// Keyboard shortcuts label for the sidebar panel toggle.
  ///
  /// In en, this message translates to:
  /// **'Sidebar panel'**
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

  /// Header title when a folder or Writerside workspace has no open editor tab.
  ///
  /// In en, this message translates to:
  /// **'No open file'**
  String get noOpenFile;

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

  /// Keyboard shortcut description for opening the Markdown and HTML reference.
  ///
  /// In en, this message translates to:
  /// **'Open the Markdown and HTML reference'**
  String get shortcutMarkdownAndHtmlDescription;

  /// Keyboard shortcut description for opening settings.
  ///
  /// In en, this message translates to:
  /// **'Open BusyMark settings'**
  String get shortcutSettingsDescription;

  /// Keyboard shortcut label for moving to the next editor tab.
  ///
  /// In en, this message translates to:
  /// **'Next tab'**
  String get shortcutNextTab;

  /// Keyboard shortcut description for moving to the next editor tab.
  ///
  /// In en, this message translates to:
  /// **'Move to the next open editor tab'**
  String get shortcutNextTabDescription;

  /// Keyboard shortcut label for moving to the previous editor tab.
  ///
  /// In en, this message translates to:
  /// **'Previous tab'**
  String get shortcutPreviousTab;

  /// Keyboard shortcut description for moving to the previous editor tab.
  ///
  /// In en, this message translates to:
  /// **'Move to the previous open editor tab'**
  String get shortcutPreviousTabDescription;

  /// Keyboard shortcut label for closing the active editor tab.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get shortcutCloseTab;

  /// Keyboard shortcut description for closing the active editor tab.
  ///
  /// In en, this message translates to:
  /// **'Close the active editor tab'**
  String get shortcutCloseTabDescription;

  /// Keyboard shortcut label for closing all editor tabs.
  ///
  /// In en, this message translates to:
  /// **'Close all tabs'**
  String get shortcutCloseAllTabs;

  /// Keyboard shortcut description for closing all editor tabs.
  ///
  /// In en, this message translates to:
  /// **'Close all open editor tabs'**
  String get shortcutCloseAllTabsDescription;

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

  /// Keyboard shortcut group for sidebar view switching.
  ///
  /// In en, this message translates to:
  /// **'Sidebar'**
  String get shortcutGroupSidebar;

  /// Tooltip for the sidebar view selector button.
  ///
  /// In en, this message translates to:
  /// **'Sidebar view'**
  String get sidebarViewMenu;

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

  /// Editor setting label for saving files automatically.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSave;

  /// Editor setting description for saving files automatically.
  ///
  /// In en, this message translates to:
  /// **'Save file changes automatically after a short idle delay.'**
  String get autoSaveDescription;

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

  /// Settings section title for privacy options.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Settings switch title for loading remote images.
  ///
  /// In en, this message translates to:
  /// **'Load remote images'**
  String get allowRemoteImages;

  /// Settings switch description for loading remote images.
  ///
  /// In en, this message translates to:
  /// **'Allow Markdown preview and editor images to load from http and https URLs.'**
  String get allowRemoteImagesDescription;

  /// Settings action label for clearing per-workspace remote image permissions.
  ///
  /// In en, this message translates to:
  /// **'Clear remote image permissions'**
  String get clearRemoteImagePermissions;

  /// Settings action description for clearing per-workspace remote image permissions.
  ///
  /// In en, this message translates to:
  /// **'Forget workspaces that were allowed to load remote images.'**
  String get clearRemoteImagePermissionsDescription;

  /// Settings action label for clearing trusted Git workspaces.
  ///
  /// In en, this message translates to:
  /// **'Clear trusted Git workspaces'**
  String get clearGitWorkspaceTrust;

  /// Settings action description for clearing trusted Git workspaces.
  ///
  /// In en, this message translates to:
  /// **'Ask before enabling Git features for previously trusted workspaces.'**
  String get clearGitWorkspaceTrustDescription;

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

  /// HTML block command label.
  ///
  /// In en, this message translates to:
  /// **'HTML block'**
  String get htmlBlock;

  /// Keyboard shortcut description for inserting or editing an HTML block.
  ///
  /// In en, this message translates to:
  /// **'Insert or edit an HTML block'**
  String get shortcutHtmlBlockDescription;

  /// Badge label for HTML rendered in the WYSIWYG editor.
  ///
  /// In en, this message translates to:
  /// **'Rendered HTML'**
  String get renderedHtml;

  /// Dialog title and tooltip for editing raw HTML source.
  ///
  /// In en, this message translates to:
  /// **'Edit HTML'**
  String get editHtml;

  /// Text field label for raw HTML source.
  ///
  /// In en, this message translates to:
  /// **'HTML source'**
  String get htmlSource;

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

  /// Placeholder label shown when a remote image is blocked.
  ///
  /// In en, this message translates to:
  /// **'Remote image blocked'**
  String get remoteImageBlocked;

  /// Tooltip for a blocked remote image placeholder.
  ///
  /// In en, this message translates to:
  /// **'Choose whether BusyMark can load remote images.'**
  String get remoteImageBlockedTooltip;

  /// Dialog title for remote image loading permission.
  ///
  /// In en, this message translates to:
  /// **'Remote images are blocked'**
  String get remoteImagesBlockedTitle;

  /// Dialog message explaining the privacy risk of remote images.
  ///
  /// In en, this message translates to:
  /// **'This document references images from the internet. Loading them can reveal network information to the image host.'**
  String get remoteImagesBlockedMessage;

  /// Dialog button that allows remote images for the current workspace.
  ///
  /// In en, this message translates to:
  /// **'Load for this workspace'**
  String get loadRemoteImagesForWorkspace;

  /// Dialog button that enables remote images globally.
  ///
  /// In en, this message translates to:
  /// **'Always load remote images'**
  String get alwaysLoadRemoteImages;

  /// Tooltip for hiding the workspace sidebar panel.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar panel'**
  String get hideSidebar;

  /// Tooltip for showing the workspace sidebar panel.
  ///
  /// In en, this message translates to:
  /// **'Show sidebar panel'**
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

  /// Menu action and dialog title for creating a new file.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get newFile;

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

  /// Rename command label.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Confirmation dialog title before deleting a file.
  ///
  /// In en, this message translates to:
  /// **'Delete file?'**
  String get confirmDeleteFileTitle;

  /// Confirmation dialog title before deleting a folder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder?'**
  String get confirmDeleteFolderTitle;

  /// Confirmation dialog message before deleting a file.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String confirmDeleteFileMessage(String name);

  /// Confirmation dialog message before deleting a folder.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and all files inside it? This cannot be undone.'**
  String confirmDeleteFolderMessage(String name);

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

  /// Tooltip for moving to the previous source search match.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get sourceSearchPreviousMatch;

  /// Tooltip for moving to the next source search match.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get sourceSearchNextMatch;

  /// Tooltip for toggling case-sensitive source search.
  ///
  /// In en, this message translates to:
  /// **'Case sensitive'**
  String get sourceSearchCaseSensitive;

  /// Tooltip for toggling whole-word source search.
  ///
  /// In en, this message translates to:
  /// **'Whole word'**
  String get sourceSearchWholeWord;

  /// Tooltip for toggling regular-expression source search.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get sourceSearchRegex;

  /// Status banner shown when source highlighting and folding are disabled for a large file.
  ///
  /// In en, this message translates to:
  /// **'Large file: highlighting and folding are paused'**
  String get sourceLargeFileFeaturesPaused;

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

  /// Workspace error message shown when creating, renaming, moving, or deleting a file fails.
  ///
  /// In en, this message translates to:
  /// **'File operation failed: {error}'**
  String workspaceErrorFileOperationFailed(String error);

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

  /// Detail for a missing directory.
  ///
  /// In en, this message translates to:
  /// **'Directory does not exist: {path}'**
  String errorDirectoryMissing(String path);

  /// Detail for a file operation target that already exists.
  ///
  /// In en, this message translates to:
  /// **'Path already exists: {path}'**
  String errorPathAlreadyExists(String path);

  /// Detail for a missing file name in a file operation.
  ///
  /// In en, this message translates to:
  /// **'File name is required.'**
  String get errorFileNameRequired;

  /// Detail for an unsafe file name in a file operation.
  ///
  /// In en, this message translates to:
  /// **'File name must be a single safe path segment.'**
  String get errorFileNameUnsafe;

  /// Detail for an invalid file operation target.
  ///
  /// In en, this message translates to:
  /// **'Cannot move a folder into itself.'**
  String get errorFileOperationInvalidTarget;

  /// Detail for a file operation outside the workspace root.
  ///
  /// In en, this message translates to:
  /// **'File operation must stay inside the workspace.'**
  String get errorFileOperationOutsideRoot;

  /// Detail for a file operation attempted on the workspace root.
  ///
  /// In en, this message translates to:
  /// **'The workspace root cannot be changed from the file tree.'**
  String get errorFileOperationRoot;

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

  /// Close action label.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Git sidebar tab label.
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get git;

  /// Title for the Git diff viewer.
  ///
  /// In en, this message translates to:
  /// **'Git diff'**
  String get gitDiff;

  /// Git empty state title when Git cannot be used.
  ///
  /// In en, this message translates to:
  /// **'Git is unavailable'**
  String get gitUnavailableTitle;

  /// Git empty state message when Git cannot be used.
  ///
  /// In en, this message translates to:
  /// **'{reason, select, other{Install Git or configure BusyMark to use an available Git executable. {reason}}}'**
  String gitUnavailableMessage(String reason);

  /// Git empty state title shown before repository-controlled commands may run.
  ///
  /// In en, this message translates to:
  /// **'Trust this workspace for Git?'**
  String get gitTrustRequiredTitle;

  /// Security warning shown before Git repository access is enabled for a workspace.
  ///
  /// In en, this message translates to:
  /// **'Git repositories can run programs through hooks, filters, and other configuration. Trust this workspace before BusyMark reads repository data or enables Git actions.'**
  String get gitTrustRequiredMessage;

  /// Action label for trusting a workspace before enabling Git.
  ///
  /// In en, this message translates to:
  /// **'Trust workspace'**
  String get gitTrustWorkspace;

  /// Git empty state title for non-repository workspaces.
  ///
  /// In en, this message translates to:
  /// **'Not a Git repository'**
  String get gitNotRepositoryTitle;

  /// Git empty state message for non-repository workspaces.
  ///
  /// In en, this message translates to:
  /// **'This workspace is not inside a Git repository.'**
  String get gitNotRepositoryMessage;

  /// Action label for git init.
  ///
  /// In en, this message translates to:
  /// **'Initialize repository'**
  String get gitInitializeRepository;

  /// Detached HEAD label.
  ///
  /// In en, this message translates to:
  /// **'Detached HEAD'**
  String get gitDetachedHead;

  /// Detached HEAD label with short commit.
  ///
  /// In en, this message translates to:
  /// **'Detached at {commit}'**
  String gitDetachedHeadAt(String commit);

  /// Repository label when no upstream branch is configured.
  ///
  /// In en, this message translates to:
  /// **'No upstream'**
  String get gitNoUpstream;

  /// Count of local commits not pushed to the upstream branch.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unpushed commit} other{{count} unpushed commits}}'**
  String gitAheadCount(int count);

  /// Count of upstream commits not pulled into the local branch.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 commit to pull} other{{count} commits to pull}}'**
  String gitBehindCount(int count);

  /// Git clean state label.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get gitClean;

  /// Git conflicts group label.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get gitConflicts;

  /// Git changes view label.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get gitChanges;

  /// Git history view label.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get gitHistory;

  /// Git branch menu label.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get gitBranches;

  /// Git pull action label.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get gitPull;

  /// Git push action label.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get gitPush;

  /// Git commit action label.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get gitCommit;

  /// Tooltip for selecting a Git file for the next commit.
  ///
  /// In en, this message translates to:
  /// **'Select for commit'**
  String get gitSelectForCommit;

  /// Tooltip for removing a Git file from the next commit selection.
  ///
  /// In en, this message translates to:
  /// **'Leave out of commit'**
  String get gitRemoveFromCommit;

  /// Git discard action label.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get gitDiscard;

  /// Action label for opening a file from a Git row or diff.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get gitOpenFile;

  /// Tooltip for marking a conflicted Git file as resolved.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get gitMarkResolved;

  /// Git untracked files group label.
  ///
  /// In en, this message translates to:
  /// **'Unversioned Files'**
  String get gitUntracked;

  /// Commit message field label.
  ///
  /// In en, this message translates to:
  /// **'Commit message'**
  String get gitCommitMessage;

  /// Commit panel selected files section label.
  ///
  /// In en, this message translates to:
  /// **'Selected files'**
  String get gitCommitSelectedFiles;

  /// Commit validation error when no files are selected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one file before committing.'**
  String get gitCommitNoSelectedFiles;

  /// Commit validation error when the message is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a commit message.'**
  String get gitCommitMessageRequired;

  /// Git create branch action label.
  ///
  /// In en, this message translates to:
  /// **'Create branch'**
  String get gitCreateBranch;

  /// Git branch dropdown action for creating a new branch.
  ///
  /// In en, this message translates to:
  /// **'+ New Branch'**
  String get gitNewBranch;

  /// Branch name field label.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get gitBranchName;

  /// Git switch branch action label.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get gitSwitchBranch;

  /// Git empty state when there are no changes.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get gitNoChanges;

  /// Git empty state when history is empty.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get gitNoHistory;

  /// Git empty state when branch list is empty.
  ///
  /// In en, this message translates to:
  /// **'No branches'**
  String get gitNoBranches;

  /// Git diff empty state.
  ///
  /// In en, this message translates to:
  /// **'No diff to show'**
  String get gitNoDiff;

  /// Git diff binary file message.
  ///
  /// In en, this message translates to:
  /// **'Binary file. BusyMark does not render binary patches.'**
  String get gitBinaryFile;

  /// Git diff banner for unsaved editor changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved editor changes are not included until saved.'**
  String get gitUnsavedChangesBanner;

  /// Confirmation title for discarding Git changes.
  ///
  /// In en, this message translates to:
  /// **'Discard Git changes?'**
  String get gitConfirmDiscardTitle;

  /// Confirmation body for discarding tracked changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The selected tracked file will be restored from Git.} other{The selected tracked files will be restored from Git.}}'**
  String gitConfirmDiscardTracked(int count);

  /// Confirmation body for deleting untracked files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The selected untracked file will be deleted.} other{The selected untracked files will be deleted.}}'**
  String gitConfirmDiscardUntracked(int count);

  /// Confirmation body for discarding mixed tracked and untracked files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The selected file will be restored or deleted based on its Git status.} other{The selected files will be restored or deleted based on their Git status.}}'**
  String gitConfirmDiscardMixed(int count);

  /// Confirmation title for switching branches.
  ///
  /// In en, this message translates to:
  /// **'Switch to {branch}?'**
  String gitConfirmSwitchBranchTitle(String branch);

  /// Confirmation body for switching branches.
  ///
  /// In en, this message translates to:
  /// **'BusyMark will reload the workspace from disk after Git switches branches.'**
  String get gitConfirmSwitchBranchMessage;

  /// Confirmation title for pushing with set-upstream.
  ///
  /// In en, this message translates to:
  /// **'Set upstream branch?'**
  String get gitConfirmPushSetUpstreamTitle;

  /// Confirmation body for pushing with set-upstream.
  ///
  /// In en, this message translates to:
  /// **'This branch has no upstream. BusyMark can push {branch} and set its upstream when exactly one remote is configured.'**
  String gitConfirmPushSetUpstreamMessage(String branch);

  /// Project history action label.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get gitProjectHistory;

  /// Current file history action label.
  ///
  /// In en, this message translates to:
  /// **'Current file'**
  String get gitFileHistory;

  /// Diff additions and deletions count.
  ///
  /// In en, this message translates to:
  /// **'+{additions} -{deletions}'**
  String gitAdditionsDeletions(int additions, int deletions);

  /// Tooltip for a changed file action menu.
  ///
  /// In en, this message translates to:
  /// **'File actions'**
  String get gitFileActions;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get gitStatusAdded;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get gitStatusDeleted;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get gitStatusRenamed;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get gitStatusCopied;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Untracked'**
  String get gitStatusUntracked;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Conflicted'**
  String get gitStatusConflicted;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get gitStatusIgnored;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Type changed'**
  String get gitStatusTypeChanged;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get gitStatusModified;

  /// Git file status label.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get gitStatusUnknown;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Git is unavailable.'**
  String get gitErrorUnavailable;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'This workspace is not a Git repository.'**
  String get gitErrorNotRepository;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'BusyMark blocked an unsafe Git path.'**
  String get gitErrorUnsafePath;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid branch name.'**
  String get gitErrorInvalidBranchName;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'No Git remote is configured.'**
  String get gitErrorNoRemote;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'No upstream branch is configured.'**
  String get gitErrorNoUpstream;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Multiple remotes are configured. Choose an upstream outside this BusyMark version.'**
  String get gitErrorMultipleRemotes;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Save or discard BusyMark editor changes before switching branches.'**
  String get gitErrorDirtyWorkspace;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Branch has diverged. Resolve merge or rebase outside this BusyMark version.'**
  String get gitErrorDiverged;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Git authentication failed. In the snap, SSH remotes may require connecting the ssh-keys interface.'**
  String get gitErrorAuthentication;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Git network operation failed.'**
  String get gitErrorNetwork;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Git reported unresolved conflicts.'**
  String get gitErrorConflict;

  /// Git error message.
  ///
  /// In en, this message translates to:
  /// **'Git command failed.'**
  String get gitErrorCommandFailed;

  /// Markdown and HTML reference dialog title and menu item.
  ///
  /// In en, this message translates to:
  /// **'Markdown and HTML'**
  String get markdownAndHtml;

  /// Reference section title for Markdown block syntax.
  ///
  /// In en, this message translates to:
  /// **'Markdown Blocks'**
  String get markdownHtmlMarkdownBlocks;

  /// Reference section description for Markdown block syntax.
  ///
  /// In en, this message translates to:
  /// **'Block structures supported in Markdown source and preview.'**
  String get markdownHtmlMarkdownBlocksDescription;

  /// Reference section title for Markdown inline syntax.
  ///
  /// In en, this message translates to:
  /// **'Inline Markdown'**
  String get markdownHtmlInlineFormatting;

  /// Reference section description for Markdown inline syntax.
  ///
  /// In en, this message translates to:
  /// **'Formatting that can appear inside paragraphs, list items, and table cells.'**
  String get markdownHtmlInlineFormattingDescription;

  /// Reference section title for supported raw HTML block tags.
  ///
  /// In en, this message translates to:
  /// **'Raw HTML Blocks'**
  String get markdownHtmlRawHtmlBlocks;

  /// Reference section description for supported raw HTML block tags.
  ///
  /// In en, this message translates to:
  /// **'Safe block-level HTML tags rendered through BusyMark preview widgets.'**
  String get markdownHtmlRawHtmlBlocksDescription;

  /// Reference section title for supported raw HTML inline tags.
  ///
  /// In en, this message translates to:
  /// **'Raw HTML Inline Tags'**
  String get markdownHtmlRawHtmlInline;

  /// Reference section description for supported raw HTML inline tags.
  ///
  /// In en, this message translates to:
  /// **'Safe inline HTML tags rendered without showing literal tags.'**
  String get markdownHtmlRawHtmlInlineDescription;

  /// Reference section title for raw HTML safety rules.
  ///
  /// In en, this message translates to:
  /// **'Safety Rules'**
  String get markdownHtmlSafety;

  /// Reference section description for raw HTML safety rules.
  ///
  /// In en, this message translates to:
  /// **'Raw HTML is parsed and sanitized before preview rendering.'**
  String get markdownHtmlSafetyDescription;

  /// Reference row label for Markdown headings.
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get markdownHtmlHeadings;

  /// Reference row label for Markdown paragraphs.
  ///
  /// In en, this message translates to:
  /// **'Paragraphs'**
  String get markdownHtmlParagraphs;

  /// Reference row label for list syntax.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get markdownHtmlLists;

  /// Reference row label for HTML container tags.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get markdownHtmlHtmlContainers;

  /// Reference row label for HTML text block tags.
  ///
  /// In en, this message translates to:
  /// **'Text blocks'**
  String get markdownHtmlHtmlTextBlocks;

  /// Reference row label for HTML figure and image tags.
  ///
  /// In en, this message translates to:
  /// **'Figures and images'**
  String get markdownHtmlHtmlFigures;

  /// Reference row label for HTML preformatted/code tags.
  ///
  /// In en, this message translates to:
  /// **'Preformatted code'**
  String get markdownHtmlHtmlPreformatted;

  /// Reference row label for HTML details/summary tags.
  ///
  /// In en, this message translates to:
  /// **'Disclosure blocks'**
  String get markdownHtmlHtmlDisclosure;

  /// Reference row label for HTML description list tags.
  ///
  /// In en, this message translates to:
  /// **'Description lists'**
  String get markdownHtmlHtmlDescriptionLists;

  /// Reference row label for HTML inline formatting tags.
  ///
  /// In en, this message translates to:
  /// **'Formatting tags'**
  String get markdownHtmlHtmlFormattingTags;

  /// Reference row label for HTML inline code-related tags.
  ///
  /// In en, this message translates to:
  /// **'Inline code tags'**
  String get markdownHtmlHtmlInlineCodeTags;

  /// Reference row label for HTML inline semantic tags that render as text.
  ///
  /// In en, this message translates to:
  /// **'Semantic text tags'**
  String get markdownHtmlHtmlNeutralInlineTags;

  /// Reference row label for sanitized preview behavior.
  ///
  /// In en, this message translates to:
  /// **'Sanitized preview'**
  String get markdownHtmlSanitizedPreview;

  /// Reference row description for sanitized preview behavior.
  ///
  /// In en, this message translates to:
  /// **'Allowed HTML is converted to BusyMark preview blocks, not rendered in a browser.'**
  String get markdownHtmlSanitizedPreviewDescription;

  /// Reference row label for raw source preservation.
  ///
  /// In en, this message translates to:
  /// **'Source is preserved'**
  String get markdownHtmlSourcePreserved;

  /// Reference row description for raw source preservation.
  ///
  /// In en, this message translates to:
  /// **'Unedited raw HTML is saved back exactly as source text.'**
  String get markdownHtmlSourcePreservedDescription;

  /// Reference row label for Markdown inside raw HTML.
  ///
  /// In en, this message translates to:
  /// **'Markdown inside HTML'**
  String get markdownHtmlMarkdownInsideHtml;

  /// Reference row description for Markdown inside raw HTML.
  ///
  /// In en, this message translates to:
  /// **'Markdown markers inside raw HTML render as literal text.'**
  String get markdownHtmlMarkdownInsideHtmlDescription;

  /// Reference row label for blocked HTML content.
  ///
  /// In en, this message translates to:
  /// **'Blocked active content'**
  String get markdownHtmlBlockedContent;

  /// Reference row description for blocked HTML content.
  ///
  /// In en, this message translates to:
  /// **'Scripts, styles, frames, forms, SVG, MathML, events, and unsafe attributes are blocked.'**
  String get markdownHtmlBlockedContentDescription;

  /// Reference row label for safe URL policy.
  ///
  /// In en, this message translates to:
  /// **'Safe URLs only'**
  String get markdownHtmlSafeUrls;

  /// Reference row description for safe URL policy.
  ///
  /// In en, this message translates to:
  /// **'Links allow http, https, mailto, tel, relative, and fragment URLs; unsafe schemes are blocked.'**
  String get markdownHtmlSafeUrlsDescription;
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
    'nb',
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
    case 'nb':
      return AppLocalizationsNb();
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

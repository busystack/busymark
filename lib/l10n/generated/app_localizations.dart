// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
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
    Locale('et'),
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
  /// **'Editor for Markdown files and Writerside-compatible documentation projects.'**
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

  /// Label for the source-code repository row in the About dialog.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSourceCode;

  /// Menu action and dialog title for reporting an issue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssue;

  /// Feedback category field label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackCategory;

  /// Placeholder for the feedback category selector.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get feedbackChooseCategory;

  /// Feedback category for a problem or bug.
  ///
  /// In en, this message translates to:
  /// **'Problem or bug'**
  String get feedbackCategoryProblem;

  /// Feedback category for a feature request.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get feedbackCategoryFeature;

  /// Feedback category for a privacy or security concern.
  ///
  /// In en, this message translates to:
  /// **'Privacy or security concern'**
  String get feedbackCategoryPrivacySecurity;

  /// Feedback category for a usability concern.
  ///
  /// In en, this message translates to:
  /// **'Usability concern'**
  String get feedbackCategoryUsability;

  /// Feedback category for other concerns.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// Feedback subject field label.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get feedbackSubject;

  /// Detailed feedback message field label.
  ///
  /// In en, this message translates to:
  /// **'Detailed message'**
  String get feedbackMessage;

  /// Optional reply email field label.
  ///
  /// In en, this message translates to:
  /// **'Reply email (optional)'**
  String get feedbackReplyEmail;

  /// Checkbox label for optional technical details.
  ///
  /// In en, this message translates to:
  /// **'Include technical details'**
  String get feedbackIncludeTechnicalDetails;

  /// Disclosure explaining exactly which optional technical details are submitted.
  ///
  /// In en, this message translates to:
  /// **'When enabled, this adds only your Linux operating-system version and BusyMark application locale. No logs, files, account data, or other diagnostics are attached.'**
  String get feedbackTechnicalDetailsDisclosure;

  /// Button that submits feedback.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// Button label while feedback is being submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get feedbackSubmitting;

  /// Validation error for a missing feedback category.
  ///
  /// In en, this message translates to:
  /// **'Choose a category.'**
  String get feedbackCategoryRequired;

  /// Validation error for feedback subject length.
  ///
  /// In en, this message translates to:
  /// **'Subject must be between 3 and 120 characters.'**
  String get feedbackSubjectLength;

  /// Validation error for feedback message length.
  ///
  /// In en, this message translates to:
  /// **'Message must be between 10 and 5,000 characters.'**
  String get feedbackMessageLength;

  /// Validation error for an invalid optional reply email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address or leave this field empty.'**
  String get feedbackReplyEmailInvalid;

  /// Feedback submission error for a connection failure.
  ///
  /// In en, this message translates to:
  /// **'BusyMark could not connect. Check your internet connection and try again.'**
  String get feedbackConnectionFailure;

  /// Feedback submission error for a timeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Try again.'**
  String get feedbackTimeoutFailure;

  /// Feedback submission error when the server rate limit is reached.
  ///
  /// In en, this message translates to:
  /// **'Too many reports were sent from this connection. Wait and try again.'**
  String get feedbackRateLimitedFailure;

  /// Feedback submission error when the server rejects invalid request data.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this report. Check the form fields and try again.'**
  String get feedbackRejectedFailure;

  /// Generic feedback submission server error.
  ///
  /// In en, this message translates to:
  /// **'The server could not accept the report. Try again later.'**
  String get feedbackServerFailure;

  /// Success message containing the server reference ID.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent. Reference ID: {id}'**
  String feedbackSuccess(String id);

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

  /// Menu action that copies the active document file name.
  ///
  /// In en, this message translates to:
  /// **'Copy file name'**
  String get copyFileName;

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

  /// Outline action that raises a heading section, including descendant headings, by one rank.
  ///
  /// In en, this message translates to:
  /// **'Promote section'**
  String get promoteSection;

  /// Outline action that lowers a heading section, including descendant headings, by one rank.
  ///
  /// In en, this message translates to:
  /// **'Demote section'**
  String get demoteSection;

  /// Outline action that swaps a heading section with its previous sibling section.
  ///
  /// In en, this message translates to:
  /// **'Move section up'**
  String get moveSectionUp;

  /// Outline action that swaps a heading section with its next sibling section.
  ///
  /// In en, this message translates to:
  /// **'Move section down'**
  String get moveSectionDown;

  /// Confirmation title before deleting a Markdown heading section.
  ///
  /// In en, this message translates to:
  /// **'Delete section?'**
  String get confirmDeleteSectionTitle;

  /// Confirmation message before deleting a Markdown heading section.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” and all content in its section? This cannot be undone.'**
  String confirmDeleteSectionMessage(String name);

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

  /// Destructive button that throws away unsaved editor changes. Translate it distinctly from Cancel.
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

  /// Title and command label for the searchable command palette.
  ///
  /// In en, this message translates to:
  /// **'Command Palette'**
  String get commandPalette;

  /// Search hint in the command palette.
  ///
  /// In en, this message translates to:
  /// **'Type a command'**
  String get commandPaletteHint;

  /// Empty state in the command palette.
  ///
  /// In en, this message translates to:
  /// **'No matching commands'**
  String get commandPaletteEmpty;

  /// Reason shown for a disabled contextual command.
  ///
  /// In en, this message translates to:
  /// **'Unavailable in the current editor context'**
  String get commandUnavailableInContext;

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

  /// Command that toggles full-screen window mode.
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

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

  /// Tooltip for the workspace path action menu button.
  ///
  /// In en, this message translates to:
  /// **'Path actions'**
  String get pathActions;

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

  /// Reading view label.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

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

  /// Language selector option for Estonian.
  ///
  /// In en, this message translates to:
  /// **'Eesti'**
  String get languageEstonian;

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

  /// Keyboard shortcut description for deleting the selected Files item or removing the selected topic from the table of contents.
  ///
  /// In en, this message translates to:
  /// **'Delete the selected Files item, or remove the selected topic from the table of contents'**
  String get shortcutDeleteTreeItemDescription;

  /// Keyboard shortcut group for general application commands.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get shortcutGroupGeneral;

  /// Keyboard shortcut label for opening the content creation chooser.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get shortcutNewDocument;

  /// Keyboard shortcut description for creating Markdown files or Writerside projects.
  ///
  /// In en, this message translates to:
  /// **'Create a Markdown file or Writerside project'**
  String get shortcutNewDocumentDescription;

  /// Keyboard shortcut description for opening content.
  ///
  /// In en, this message translates to:
  /// **'Open a Markdown file, folder, or Writerside project'**
  String get shortcutOpenDescription;

  /// Keyboard shortcut description for saving content.
  ///
  /// In en, this message translates to:
  /// **'Save the current document'**
  String get shortcutSaveDescription;

  /// Keyboard shortcut description for search.
  ///
  /// In en, this message translates to:
  /// **'Search the current workspace'**
  String get shortcutSearchDescription;

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

  /// Keyboard shortcut label for moving to the next tab.
  ///
  /// In en, this message translates to:
  /// **'Next tab'**
  String get shortcutNextTab;

  /// Keyboard shortcut description for moving to the next tab.
  ///
  /// In en, this message translates to:
  /// **'Move to the next open tab'**
  String get shortcutNextTabDescription;

  /// Keyboard shortcut label for moving to the previous tab.
  ///
  /// In en, this message translates to:
  /// **'Previous tab'**
  String get shortcutPreviousTab;

  /// Keyboard shortcut description for moving to the previous tab.
  ///
  /// In en, this message translates to:
  /// **'Move to the previous open tab'**
  String get shortcutPreviousTabDescription;

  /// Keyboard shortcut label for closing the active tab.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get shortcutCloseTab;

  /// Keyboard shortcut description for closing the active tab.
  ///
  /// In en, this message translates to:
  /// **'Close the active tab'**
  String get shortcutCloseTabDescription;

  /// Keyboard shortcut label for closing all tabs.
  ///
  /// In en, this message translates to:
  /// **'Close all tabs'**
  String get shortcutCloseAllTabs;

  /// Keyboard shortcut description for closing all tabs.
  ///
  /// In en, this message translates to:
  /// **'Close all open tabs'**
  String get shortcutCloseAllTabsDescription;

  /// Keyboard shortcut group for text editing commands.
  ///
  /// In en, this message translates to:
  /// **'Text Editing'**
  String get shortcutGroupTextEditing;

  /// Keyboard shortcut description for selecting source text or visual-editor blocks.
  ///
  /// In en, this message translates to:
  /// **'In Source mode, select all text; in Editor mode, press twice to select every block'**
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

  /// Keyboard shortcut label for inserting indentation.
  ///
  /// In en, this message translates to:
  /// **'Insert indentation'**
  String get shortcutInsertIndentation;

  /// Keyboard shortcut description for inserting indentation.
  ///
  /// In en, this message translates to:
  /// **'Insert indentation at the cursor'**
  String get shortcutInsertIndentationDescription;

  /// Keyboard shortcut label for outdenting in Source mode.
  ///
  /// In en, this message translates to:
  /// **'Outdent source'**
  String get shortcutOutdentSource;

  /// Keyboard shortcut description for outdenting in Source mode.
  ///
  /// In en, this message translates to:
  /// **'Remove one indentation level in Source mode'**
  String get shortcutOutdentSourceDescription;

  /// Keyboard shortcut label for closing search or clearing a block selection.
  ///
  /// In en, this message translates to:
  /// **'Close search or clear block selection'**
  String get shortcutEscape;

  /// Keyboard shortcut description for closing search or clearing a block selection.
  ///
  /// In en, this message translates to:
  /// **'Close workspace search or clear a block selection in Editor mode'**
  String get shortcutEscapeDescription;

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
  /// **'Editing buttons position'**
  String get editingButtonsPosition;

  /// Description for WYSIWYG editing button position setting.
  ///
  /// In en, this message translates to:
  /// **'Choose where the floating WYSIWYG editing buttons appear.'**
  String get editingButtonsPositionDescription;

  /// Settings label for WYSIWYG editing button direction.
  ///
  /// In en, this message translates to:
  /// **'Editing buttons direction'**
  String get editingButtonsDirection;

  /// Description for WYSIWYG editing button direction setting.
  ///
  /// In en, this message translates to:
  /// **'Choose whether the floating WYSIWYG editing buttons are arranged horizontally or vertically.'**
  String get editingButtonsDirectionDescription;

  /// Editing button direction option.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// Editing button direction option.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

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

  /// Destructive button that closes BusyMark without saving editor changes. Translate it distinctly from Cancel.
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

  /// Confirmation message before replacing workspace state when several documents are dirty.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document has unsaved changes. Save it before continuing?} other{{count} documents have unsaved changes. Save them before continuing?}}'**
  String unsavedChangesMultipleMessage(int count);

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

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @openVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get openVideo;

  /// No description provided for @pauseVideo.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get pauseVideo;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable'**
  String get videoUnavailable;

  /// No description provided for @videoPreview.
  ///
  /// In en, this message translates to:
  /// **'Video preview'**
  String get videoPreview;

  /// No description provided for @diagnosticWritersideVideoMissingSource.
  ///
  /// In en, this message translates to:
  /// **'Video is missing its src attribute.'**
  String get diagnosticWritersideVideoMissingSource;

  /// No description provided for @diagnosticWritersideVideoUnsupportedSource.
  ///
  /// In en, this message translates to:
  /// **'Unsupported video source: {source}'**
  String diagnosticWritersideVideoUnsupportedSource(String source);

  /// No description provided for @diagnosticWritersideVideoMissingFile.
  ///
  /// In en, this message translates to:
  /// **'Video file does not exist: {source}'**
  String diagnosticWritersideVideoMissingFile(String source);

  /// No description provided for @diagnosticWritersideVideoMissingPreview.
  ///
  /// In en, this message translates to:
  /// **'Video preview image does not exist: {preview}'**
  String diagnosticWritersideVideoMissingPreview(String preview);

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

  /// Default editable text inserted into a new HTML block.
  ///
  /// In en, this message translates to:
  /// **'HTML content'**
  String get htmlContentDefault;

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

  /// Menu item for using unspecified Markdown table-column alignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment: Unspecified'**
  String get tableAlignmentUnspecified;

  /// Menu item for left-aligning a Markdown table column.
  ///
  /// In en, this message translates to:
  /// **'Alignment: Left'**
  String get tableAlignmentLeft;

  /// Menu item for centering a Markdown table column.
  ///
  /// In en, this message translates to:
  /// **'Alignment: Center'**
  String get tableAlignmentCenter;

  /// Menu item for right-aligning a Markdown table column.
  ///
  /// In en, this message translates to:
  /// **'Alignment: Right'**
  String get tableAlignmentRight;

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

  /// Default selected text inserted by a source-editor formatting command.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get editorPlaceholderText;

  /// Default selected code inserted by a source-editor code command.
  ///
  /// In en, this message translates to:
  /// **'code'**
  String get editorPlaceholderCode;

  /// Default selected image description inserted by a source-editor image command.
  ///
  /// In en, this message translates to:
  /// **'alt text'**
  String get editorPlaceholderAltText;

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

  /// Tooltip for the Writerside TOC action menu button.
  ///
  /// In en, this message translates to:
  /// **'TOC actions'**
  String get tocActions;

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

  /// Create new sibling Writerside topic action label.
  ///
  /// In en, this message translates to:
  /// **'New Sibling Topic'**
  String get newSiblingTopic;

  /// Context-menu action that renames a Writerside topic file.
  ///
  /// In en, this message translates to:
  /// **'Rename Topic File'**
  String get renameTopicFile;

  /// Create topic dialog label for selecting TOC placement.
  ///
  /// In en, this message translates to:
  /// **'TOC placement'**
  String get topicPlacement;

  /// TOC placement option for the root level.
  ///
  /// In en, this message translates to:
  /// **'At TOC root'**
  String get tocRoot;

  /// TOC placement option after the selected topic.
  ///
  /// In en, this message translates to:
  /// **'After selected topic'**
  String get afterSelectedTopic;

  /// TOC placement option inside the selected topic.
  ///
  /// In en, this message translates to:
  /// **'Inside selected topic'**
  String get insideSelectedTopic;

  /// Action that moves a cut TOC entry after the selected topic.
  ///
  /// In en, this message translates to:
  /// **'Paste After'**
  String get pasteAfterTopic;

  /// Action that moves a cut TOC entry inside the selected topic.
  ///
  /// In en, this message translates to:
  /// **'Paste as Child'**
  String get pasteAsChildTopic;

  /// Action that removes an entry from a Writerside table of contents without deleting its topic file.
  ///
  /// In en, this message translates to:
  /// **'Remove from TOC'**
  String get removeFromToc;

  /// Confirmation title before removing a Writerside TOC entry.
  ///
  /// In en, this message translates to:
  /// **'Remove from TOC?'**
  String get confirmRemoveFromTocTitle;

  /// Confirmation message before removing a Writerside TOC entry without deleting its topic file.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this table of contents? The topic file will be kept.'**
  String confirmRemoveFromTocMessage(String name);

  /// Confirmation title before deleting a Writerside topic file.
  ///
  /// In en, this message translates to:
  /// **'Delete topic file?'**
  String get confirmDeleteTopicTitle;

  /// Confirmation message before deleting a Writerside topic file and removing its TOC entries.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and remove it from every table of contents? This cannot be undone.'**
  String confirmDeleteTopicMessage(String name);

  /// Writerside action that safely deletes a topic after checking usages.
  ///
  /// In en, this message translates to:
  /// **'Safe Delete Topic File…'**
  String get safeDeleteTopicFile;

  /// Writerside action and dialog title for removing a topic from one table of contents.
  ///
  /// In en, this message translates to:
  /// **'Remove TOC Element'**
  String get removeTocElement;

  /// Action that opens the Writerside topic usages review.
  ///
  /// In en, this message translates to:
  /// **'Review Usages'**
  String get reviewUsages;

  /// Action that deletes a Writerside topic source file.
  ///
  /// In en, this message translates to:
  /// **'Delete Topic File'**
  String get deleteTopicFile;

  /// Short action label for removing an item without deleting its source file.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// Summary in the dialog for removing a topic from one Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'Remove “{topic}” from the selected instance. The topic file will be kept.'**
  String topicRemovalSummary(String topic);

  /// Summary in the Writerside safe-delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete “{topic}” and safely update its references throughout this Writerside project.'**
  String safeDeleteTopicSummary(String topic);

  /// Disclosure that children of a removed TOC element are promoted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 child topic will move up one level.} other{{count} child topics will move up one level.}}'**
  String childTopicsPromoted(int count);

  /// Warning that blocks deletion of a Writerside start-page topic.
  ///
  /// In en, this message translates to:
  /// **'This topic is used as an instance start page. Review its usages and assign another start page before continuing.'**
  String get topicIsStartPageRemovalWarning;

  /// Heading with the number of Writerside topic usages.
  ///
  /// In en, this message translates to:
  /// **'Usages ({count})'**
  String topicUsagesCount(int count);

  /// Safe-delete message when no breaking references were found.
  ///
  /// In en, this message translates to:
  /// **'No references that would be broken were found.'**
  String get noBreakingTopicUsages;

  /// Description above Writerside topic usage groups.
  ///
  /// In en, this message translates to:
  /// **'BusyMark found the following references to this topic.'**
  String get topicUsagesFound;

  /// Usage group label for Writerside TOC elements.
  ///
  /// In en, this message translates to:
  /// **'TOC elements'**
  String get topicUsageTocElements;

  /// Usage group label for Writerside instance start pages.
  ///
  /// In en, this message translates to:
  /// **'Start pages'**
  String get topicUsageStartPages;

  /// Usage group label for links to a Writerside topic.
  ///
  /// In en, this message translates to:
  /// **'Topic links'**
  String get topicUsageTopicLinks;

  /// Usage group label for Writerside include elements.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get topicUsageIncludes;

  /// Number of references that use a Writerside topic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 usage} other{{count} usages}}'**
  String usageCount(int count);

  /// Heading for Writerside topic removal options.
  ///
  /// In en, this message translates to:
  /// **'Refactoring options'**
  String get refactoringOptions;

  /// Option to rewrite Writerside topic usages during removal.
  ///
  /// In en, this message translates to:
  /// **'Update usages automatically'**
  String get updateUsagesAutomatically;

  /// Description of automatic Writerside usage updates.
  ///
  /// In en, this message translates to:
  /// **'Remove TOC references and includes, and preserve link text.'**
  String get updateUsagesAutomaticallyDescription;

  /// Message when some Writerside usages cannot be updated automatically.
  ///
  /// In en, this message translates to:
  /// **'Some usages require manual changes before this refactoring.'**
  String get manualUsageUpdatesRequired;

  /// Option to redirect an old Writerside page to another topic.
  ///
  /// In en, this message translates to:
  /// **'Set redirect to'**
  String get setRedirectTo;

  /// Description when no Writerside page redirect is selected.
  ///
  /// In en, this message translates to:
  /// **'Do not redirect the old published page.'**
  String get noRedirectDescription;

  /// Field label for a Writerside redirect destination.
  ///
  /// In en, this message translates to:
  /// **'Redirect target'**
  String get redirectTarget;

  /// Instruction shown when unresolved usages block topic removal.
  ///
  /// In en, this message translates to:
  /// **'Review and update the remaining usages before continuing, or enable automatic updates when available.'**
  String get remainingUsagesBlockRemoval;

  /// Writerside usages sidebar title.
  ///
  /// In en, this message translates to:
  /// **'Usages of {topic}'**
  String usagesOfTopic(String topic);

  /// Empty state in the Writerside usages review.
  ///
  /// In en, this message translates to:
  /// **'No usages found'**
  String get noUsagesFound;

  /// Marker for a usage outside the selected Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'outside selected instance'**
  String get outsideSelectedInstance;

  /// Action to return from usage review and continue the topic refactoring.
  ///
  /// In en, this message translates to:
  /// **'Do Refactor'**
  String get doRefactor;

  /// Dialog title after a topic is removed from its last table of contents.
  ///
  /// In en, this message translates to:
  /// **'Topic file is no longer used'**
  String get orphanTopicTitle;

  /// Action that keeps an orphaned Writerside topic file.
  ///
  /// In en, this message translates to:
  /// **'Keep Topic File'**
  String get keepTopicFile;

  /// Prompt to delete or keep an orphaned Writerside topic file.
  ///
  /// In en, this message translates to:
  /// **'“{topic}” is no longer used anywhere in this Writerside project. Delete the file, or keep it for use in another instance.'**
  String orphanTopicMessage(String topic);

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

  /// Placeholder for the active-document replacement field.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get sourceSearchReplacement;

  /// Tooltip for replacing the current search match.
  ///
  /// In en, this message translates to:
  /// **'Replace current'**
  String get sourceSearchReplaceCurrent;

  /// Tooltip for replacing the current match and moving to the next.
  ///
  /// In en, this message translates to:
  /// **'Replace and find next'**
  String get sourceSearchReplaceAndFindNext;

  /// Tooltip for replacing every active-document search match.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get sourceSearchReplaceAll;

  /// Action that previews replacements across the workspace.
  ///
  /// In en, this message translates to:
  /// **'Replace in Workspace'**
  String get workspaceReplace;

  /// Action and dialog title for reviewing workspace replacements.
  ///
  /// In en, this message translates to:
  /// **'Review replacements'**
  String get reviewReplacements;

  /// Action that applies selected workspace replacements.
  ///
  /// In en, this message translates to:
  /// **'Apply replacements'**
  String get applyReplacements;

  /// Heading for files excluded from a workspace replacement.
  ///
  /// In en, this message translates to:
  /// **'Skipped files'**
  String get skippedFiles;

  /// Source label for a workspace replacement preview using a dirty document buffer.
  ///
  /// In en, this message translates to:
  /// **'Unsaved editor content'**
  String get workspaceReplaceDirtyBuffer;

  /// Source label for a workspace replacement preview using disk content.
  ///
  /// In en, this message translates to:
  /// **'Saved disk content'**
  String get workspaceReplaceDiskContent;

  /// Checkbox label for selecting every replacement match in a file.
  ///
  /// In en, this message translates to:
  /// **'Select all {count} matches'**
  String selectFileMatches(int count);

  /// Summary shown after applying workspace replacements.
  ///
  /// In en, this message translates to:
  /// **'Replaced {matches} matches in {files} files; skipped {skipped}.'**
  String workspaceReplaceApplied(int matches, int files, int skipped);

  /// Dialog title for selecting a line-ending style.
  ///
  /// In en, this message translates to:
  /// **'Normalize line endings'**
  String get normalizeLineEndings;

  /// Prompt shown before saving a document with mixed line endings.
  ///
  /// In en, this message translates to:
  /// **'This document contains mixed line endings. Choose a format.'**
  String get mixedLineEndingsSavePrompt;

  /// Prompt shown before replacing content in a mixed-line-ending file.
  ///
  /// In en, this message translates to:
  /// **'{fileName} uses mixed line endings. Choose the format to use before replacing.'**
  String workspaceReplaceMixedLineEndings(String fileName);

  /// Workspace replacement issue for a file above the size limit.
  ///
  /// In en, this message translates to:
  /// **'Skipped an oversized file.'**
  String get workspaceReplaceIssueOversized;

  /// Workspace replacement issue for an unreadable file.
  ///
  /// In en, this message translates to:
  /// **'Skipped a file that could not be read.'**
  String get workspaceReplaceIssueUnreadable;

  /// Workspace replacement issue for invalid UTF-8 content.
  ///
  /// In en, this message translates to:
  /// **'Skipped a file that is not valid UTF-8.'**
  String get workspaceReplaceIssueInvalidUtf8;

  /// Workspace replacement issue when the match limit is reached.
  ///
  /// In en, this message translates to:
  /// **'The replacement preview was truncated.'**
  String get workspaceReplaceIssueTruncated;

  /// Workspace replacement issue for stale disk content.
  ///
  /// In en, this message translates to:
  /// **'Skipped a file that changed after the preview.'**
  String get workspaceReplaceIssueFileChanged;

  /// Workspace replacement issue for stale in-memory content.
  ///
  /// In en, this message translates to:
  /// **'Skipped an editor buffer that changed after the preview.'**
  String get workspaceReplaceIssueBufferChanged;

  /// Workspace replacement issue for mixed line endings without a selected format.
  ///
  /// In en, this message translates to:
  /// **'Choose LF or CRLF normalization before replacing.'**
  String get workspaceReplaceIssueNormalizationRequired;

  /// Workspace replacement issue when a concurrent edit prevents safe transactional rollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback stopped because the file changed concurrently. Some replacements may remain; displaced content was preserved at the path below.'**
  String get workspaceReplaceIssuePartialConflict;

  /// Workspace replacement issue when the transactional file commit fails.
  ///
  /// In en, this message translates to:
  /// **'The reviewed replacement could not be committed; no files were changed.'**
  String get workspaceReplaceIssueApplyFailed;

  /// Title of the external-file comparison dialog.
  ///
  /// In en, this message translates to:
  /// **'External changes — {fileName}'**
  String externalChangesTitle(String fileName);

  /// Persistent banner shown when an open file is deleted externally.
  ///
  /// In en, this message translates to:
  /// **'This file was deleted on disk.'**
  String get externalFileDeleted;

  /// Persistent banner shown when a dirty file changes externally.
  ///
  /// In en, this message translates to:
  /// **'This file changed on disk while you have unsaved edits.'**
  String get externalFileChanged;

  /// Persistent recovery review banner.
  ///
  /// In en, this message translates to:
  /// **'Recovered unsaved content for {fileName}. Inspect it, then save, save as, or discard it.'**
  String recoveredDocumentReview(String fileName);

  /// Action that compares the editor buffer with the disk version.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// Action that replaces the editor buffer with the disk version.
  ///
  /// In en, this message translates to:
  /// **'Reload from Disk'**
  String get reloadFromDisk;

  /// Action that keeps the editor buffer after an external change.
  ///
  /// In en, this message translates to:
  /// **'Keep Mine'**
  String get keepMine;

  /// Action that saves the current document to another path.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// Source search status shown when the regular expression is invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid regular expression'**
  String get sourceSearchInvalidRegex;

  /// Status banner shown when source highlighting and folding are disabled for a large file.
  ///
  /// In en, this message translates to:
  /// **'Large file: highlighting and folding are paused'**
  String get sourceLargeFileFeaturesPaused;

  /// Empty state shown when there is no content to read.
  ///
  /// In en, this message translates to:
  /// **'Nothing to read'**
  String get nothingToRead;

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

  /// Notice shown after crash recovery restores documents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Recovered 1 unsaved document. Review it before saving or discarding it.} other{Recovered {count} unsaved documents. Review each one before saving or discarding it.}}'**
  String workspaceRecoveryRestored(int count);

  /// Notice shown when recovery data is partly or wholly malformed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One damaged recovery record could not be restored. The original recovery file was preserved for inspection.} other{{count} damaged recovery records could not be restored. Valid recovery records remain available.}}'**
  String workspaceRecoveryDamaged(int count);

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
  /// **'The Writerside module has no instance tree.'**
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

  /// Detail shown when a selected Writerside TOC entry no longer exists.
  ///
  /// In en, this message translates to:
  /// **'The selected TOC entry no longer exists.'**
  String get errorWritersideTocNodeMissing;

  /// Detail shown when a Writerside TOC move would create a cycle.
  ///
  /// In en, this message translates to:
  /// **'A TOC entry cannot be moved into itself or one of its children.'**
  String get errorWritersideTocInvalidMove;

  /// Detail shown when attempting to delete the start topic of a Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'The start topic {topic} cannot be deleted. Choose another start page first.'**
  String errorWritersideStartTopicDelete(String topic);

  /// Error shown when generic file deletion is attempted for a Writerside topic.
  ///
  /// In en, this message translates to:
  /// **'Use Safe Delete for Writerside topic files.'**
  String get errorWritersideSafeDeleteRequired;

  /// Error shown when safe-delete usage analysis cannot complete reliably.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the topic usage scan. No files were changed.'**
  String get errorWritersideTopicUsageScanFailed;

  /// Error shown when unresolved topic usages block removal.
  ///
  /// In en, this message translates to:
  /// **'Some topic usages still require attention. Review them before continuing.'**
  String get errorWritersideTopicUsagesRemain;

  /// Error shown when a safe-delete redirect target is stale or conflicts.
  ///
  /// In en, this message translates to:
  /// **'The selected redirect target is no longer valid. Choose it again.'**
  String get errorWritersideRedirectInvalid;

  /// Error shown when safe-delete recovery leaves files requiring manual review.
  ///
  /// In en, this message translates to:
  /// **'Topic removal could not be fully rolled back. Review these paths before continuing: {paths}'**
  String errorWritersideRollbackFailed(String paths);

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

  /// Menu action that opens the diff for a file in Git history.
  ///
  /// In en, this message translates to:
  /// **'Show diff'**
  String get gitShowDiff;

  /// Readable old-to-new line range shown for a Git diff hunk.
  ///
  /// In en, this message translates to:
  /// **'old {oldRange} → new {newRange}'**
  String gitDiffHunkRange(String oldRange, String newRange);

  /// Line range text for an empty side of a Git diff hunk.
  ///
  /// In en, this message translates to:
  /// **'no lines'**
  String get gitDiffNoLines;

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

  /// Git staged changes group label.
  ///
  /// In en, this message translates to:
  /// **'Staged'**
  String get gitStaged;

  /// Git unstaged changes group label.
  ///
  /// In en, this message translates to:
  /// **'Unstaged'**
  String get gitUnstaged;

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

  /// Tooltip for the Git action menu button.
  ///
  /// In en, this message translates to:
  /// **'Git actions'**
  String get gitActions;

  /// Git pull action label.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get gitPull;

  /// Git fetch action label.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get gitFetch;

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

  /// Tooltip for staging a Git file.
  ///
  /// In en, this message translates to:
  /// **'Stage file'**
  String get gitSelectForCommit;

  /// Tooltip for unstaging a Git file.
  ///
  /// In en, this message translates to:
  /// **'Unstage file'**
  String get gitRemoveFromCommit;

  /// Action that rolls a tracked file back to HEAD.
  ///
  /// In en, this message translates to:
  /// **'Rollback'**
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
  /// **'Untracked'**
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

  /// Commit validation error when the repository index is empty.
  ///
  /// In en, this message translates to:
  /// **'Stage at least one file before committing.'**
  String get gitCommitNoSelectedFiles;

  /// Number of repository files currently staged for commit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 staged file} other{{count} staged files}}'**
  String gitStagedFileCount(int count);

  /// Marker for a staged repository file outside the opened workspace.
  ///
  /// In en, this message translates to:
  /// **'Outside workspace'**
  String get gitOutsideWorkspace;

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
  /// **'New Branch'**
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

  /// Git diff binary file message with file size.
  ///
  /// In en, this message translates to:
  /// **'Binary file ({size} bytes). BusyMark does not render binary patches.'**
  String gitBinaryFileInfo(int size);

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
  /// **'{count, plural, =1{All staged and unstaged changes in the selected tracked file will be restored to HEAD.} other{All staged and unstaged changes in the selected tracked files will be restored to HEAD.}}'**
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
  /// **'Project History'**
  String get gitProjectHistory;

  /// Current file history action label.
  ///
  /// In en, this message translates to:
  /// **'File History'**
  String get gitFileHistory;

  /// File History empty state when no Markdown file is active.
  ///
  /// In en, this message translates to:
  /// **'File History requires an open Markdown file.'**
  String get gitFileHistoryRequiresOpenFile;

  /// Action to load another page of Git history.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get gitLoadMore;

  /// Historical comparison between a commit and its parent.
  ///
  /// In en, this message translates to:
  /// **'Changes in this commit'**
  String get gitChangesInCommit;

  /// Historical comparison between a commit and the working-tree file.
  ///
  /// In en, this message translates to:
  /// **'Compare with current'**
  String get gitCompareWithCurrent;

  /// Action to restore one file from a selected commit.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get gitRestoreVersion;

  /// Confirmation title for restoring a historical file version.
  ///
  /// In en, this message translates to:
  /// **'Restore this file version?'**
  String get gitConfirmRestoreTitle;

  /// Confirmation body for restoring a historical file version.
  ///
  /// In en, this message translates to:
  /// **'BusyMark will replace the current working-tree file with the selected committed version. The restored file will remain unstaged.'**
  String get gitConfirmRestoreMessage;

  /// Tooltip for actions on a selected Git commit.
  ///
  /// In en, this message translates to:
  /// **'Commit actions'**
  String get gitCommitActions;

  /// Project History action that moves the current branch to the selected commit.
  ///
  /// In en, this message translates to:
  /// **'Reset current branch to here…'**
  String get gitResetCurrentBranchToHere;

  /// Title for choosing how to reset the current branch to a selected commit.
  ///
  /// In en, this message translates to:
  /// **'Reset {branch} to {commit}?'**
  String gitResetCurrentBranchTitle(String branch, String commit);

  /// Explanation shown before resetting the current branch.
  ///
  /// In en, this message translates to:
  /// **'This moves branch {branch} to commit {commit}. Choose how Git updates the index and working tree.'**
  String gitResetCurrentBranchMessage(String branch, String commit);

  /// Action that confirms resetting the current Git branch.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get gitReset;

  /// Git soft reset mode label.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get gitResetModeSoft;

  /// Git soft reset mode explanation.
  ///
  /// In en, this message translates to:
  /// **'Move the branch only. Keep the index and working tree unchanged; differences from the selected commit remain staged.'**
  String get gitResetModeSoftDescription;

  /// Git mixed reset mode label.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get gitResetModeMixed;

  /// Git mixed reset mode explanation.
  ///
  /// In en, this message translates to:
  /// **'Move the branch and reset the index. Keep the working tree unchanged, leaving differences unstaged.'**
  String get gitResetModeMixedDescription;

  /// Git hard reset mode label.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gitResetModeHard;

  /// Git hard reset mode explanation.
  ///
  /// In en, this message translates to:
  /// **'Move the branch and reset the index and working tree. Tracked changes are discarded; obstructing untracked files may be deleted.'**
  String get gitResetModeHardDescription;

  /// Git keep reset mode label.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get gitResetModeKeep;

  /// Git keep reset mode explanation.
  ///
  /// In en, this message translates to:
  /// **'Move the branch and reset tracked files while preserving local changes. Git aborts if those changes conflict with the reset.'**
  String get gitResetModeKeepDescription;

  /// Diff additions and deletions count.
  ///
  /// In en, this message translates to:
  /// **'+{additions} -{deletions}'**
  String gitAdditionsDeletions(int additions, int deletions);

  /// Tooltip for a file action menu.
  ///
  /// In en, this message translates to:
  /// **'File actions'**
  String get fileActions;

  /// Tooltip for a general action menu.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

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

  /// Git reset error shown when the editor has unsaved content.
  ///
  /// In en, this message translates to:
  /// **'Save or discard BusyMark editor changes before resetting the current branch.'**
  String get gitErrorResetDirtyWorkspace;

  /// Git error shown when historical restoration is blocked because the current file is staged.
  ///
  /// In en, this message translates to:
  /// **'Unstage this file before restoring a historical version.'**
  String get gitErrorRestoreStagedFile;

  /// Git reset error shown while HEAD is detached.
  ///
  /// In en, this message translates to:
  /// **'Check out a branch before resetting it.'**
  String get gitErrorResetDetachedHead;

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

  /// Menu action and dialog title for exporting the active document or Writerside module as PDF.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// Introductory text in the PDF export options dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose the page layout for a polished, self-contained PDF.'**
  String get pdfExportDescription;

  /// Privacy note explaining image handling during PDF export.
  ///
  /// In en, this message translates to:
  /// **'Remote images are not downloaded during export. Local images are included when available.'**
  String get pdfRemoteImagesNote;

  /// PDF export page-size setting.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get pdfPageSize;

  /// A4 PDF page-size option.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get pdfPageSizeA4;

  /// US Letter PDF page-size option.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get pdfPageSizeLetter;

  /// PDF export page-orientation setting.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get pdfOrientation;

  /// Portrait PDF page-orientation option.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get pdfPortrait;

  /// Landscape PDF page-orientation option.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get pdfLandscape;

  /// PDF export page-margin setting.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get pdfMargins;

  /// Narrow PDF page-margin option.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get pdfMarginNarrow;

  /// Normal PDF page-margin option.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get pdfMarginNormal;

  /// Wide PDF page-margin option.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get pdfMarginWide;

  /// Toggle for page numbers in an exported PDF.
  ///
  /// In en, this message translates to:
  /// **'Include page numbers'**
  String get pdfIncludePageNumbers;

  /// Button label that starts an export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Progress dialog title while a PDF is being exported.
  ///
  /// In en, this message translates to:
  /// **'Exporting PDF…'**
  String get exportingPdf;

  /// File picker label for PDF documents.
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get fileTypePdf;

  /// PDF export success message.
  ///
  /// In en, this message translates to:
  /// **'{fileName} was exported.'**
  String pdfExported(String fileName);

  /// PDF export success message when some content fell back or was omitted.
  ///
  /// In en, this message translates to:
  /// **'{fileName} was exported with {count} warning(s).'**
  String pdfExportedWithWarnings(String fileName, int count);

  /// Error shown when the bundled PDF compiler is unavailable.
  ///
  /// In en, this message translates to:
  /// **'The PDF export component is missing. Reinstall BusyMark and try again.'**
  String get pdfExportUnavailable;

  /// Error shown when PDF compilation times out.
  ///
  /// In en, this message translates to:
  /// **'PDF export took too long and was stopped.'**
  String get pdfExportTimedOut;

  /// Generic PDF export failure message.
  ///
  /// In en, this message translates to:
  /// **'BusyMark could not export this document as PDF.'**
  String get pdfExportFailed;

  /// Status shown while a fenced visualization is rendering.
  ///
  /// In en, this message translates to:
  /// **'Rendering…'**
  String get visualizationRendering;

  /// Status shown when a visualization displays its last valid result while newer source renders or is invalid.
  ///
  /// In en, this message translates to:
  /// **'Showing the last valid render'**
  String get visualizationStale;

  /// Action that reveals the original source fence for a visualization.
  ///
  /// In en, this message translates to:
  /// **'Show source'**
  String get visualizationShowSource;

  /// Action that returns from visualization source to its rendered output.
  ///
  /// In en, this message translates to:
  /// **'Show render'**
  String get visualizationShowRender;

  /// Action that resets diagram zoom to fit its card.
  ///
  /// In en, this message translates to:
  /// **'Fit to width'**
  String get visualizationFitWidth;

  /// Action that saves a rendered diagram as an SVG or PNG file.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get visualizationSaveImage;

  /// Action that copies a rendered diagram to the image clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy image'**
  String get visualizationCopyImage;

  /// Confirmation after copying a rendered diagram to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Image copied'**
  String get visualizationImageCopied;

  /// Action that opens the complete interactive OpenAPI reference window.
  ///
  /// In en, this message translates to:
  /// **'Open API Reference'**
  String get visualizationOpenApiReference;

  /// OpenAPI validation success state.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get visualizationValid;

  /// OpenAPI validation failure state.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get visualizationInvalid;

  /// OpenAPI server count label.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get visualizationServers;

  /// OpenAPI path count label.
  ///
  /// In en, this message translates to:
  /// **'Paths'**
  String get visualizationPaths;

  /// OpenAPI operation count label.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get visualizationOperations;

  /// OpenAPI tag summary label.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get visualizationTags;

  /// Empty state for the filtered OpenAPI operation list.
  ///
  /// In en, this message translates to:
  /// **'No matching operations'**
  String get visualizationNoOperations;

  /// Hint for the OpenAPI operation search field.
  ///
  /// In en, this message translates to:
  /// **'Search operations'**
  String get visualizationSearchOperations;

  /// Fallback message for a failed visualization render.
  ///
  /// In en, this message translates to:
  /// **'This visualization could not be rendered.'**
  String get visualizationRenderFailed;

  /// Action that retries a failed visualization render.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get visualizationRetry;

  /// Confirmation after saving a rendered diagram.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName}'**
  String visualizationSaved(String fileName);

  /// Keyboard-shortcut description for PDF export.
  ///
  /// In en, this message translates to:
  /// **'Export the active document or Writerside module as a PDF.'**
  String get shortcutExportPdfDescription;

  /// Heading for the Writerside instances shown in the TOC sidebar.
  ///
  /// In en, this message translates to:
  /// **'Instances'**
  String get instances;

  /// Action that creates a Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'New instance'**
  String get newInstance;

  /// Action that creates a Writerside library instance for reusable TOC sections.
  ///
  /// In en, this message translates to:
  /// **'New TOC library'**
  String get newTocLibrary;

  /// Action and dialog title for editing a Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'Edit instance'**
  String get editInstance;

  /// Action that opens the selected Writerside instance tree file.
  ///
  /// In en, this message translates to:
  /// **'Open TOC file'**
  String get openTocFile;

  /// Dialog title for creating a Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'Create instance'**
  String get createInstance;

  /// Dialog title for creating a Writerside TOC library instance.
  ///
  /// In en, this message translates to:
  /// **'Create TOC library'**
  String get createTocLibrary;

  /// Group title for choosing the initial content of a Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get instanceContent;

  /// Field for choosing how a Writerside instance is initialized.
  ///
  /// In en, this message translates to:
  /// **'Create from'**
  String get instanceContentSource;

  /// Option to create a Writerside instance without imported topics.
  ///
  /// In en, this message translates to:
  /// **'Empty instance'**
  String get emptyInstance;

  /// Option to initialize a Writerside instance from Markdown files.
  ///
  /// In en, this message translates to:
  /// **'Local Markdown files'**
  String get markdownFiles;

  /// Action to choose a folder containing Markdown files.
  ///
  /// In en, this message translates to:
  /// **'Choose Markdown folder'**
  String get chooseMarkdownFolder;

  /// Validation shown when an imported instance has no source folder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder containing Markdown files.'**
  String get errorWritersideInstanceImportSourceRequired;

  /// Group title for the local appearance of a Writerside instance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get instanceAppearance;

  /// Writerside instance icon-color field.
  ///
  /// In en, this message translates to:
  /// **'Icon color'**
  String get instanceColor;

  /// Writerside instance version field.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get instanceVersion;

  /// Explanation of an inherited Writerside project version.
  ///
  /// In en, this message translates to:
  /// **'The project version is {version} when this field is empty.'**
  String instanceVersionInherited(String version);

  /// Writerside instance publication web-path field.
  ///
  /// In en, this message translates to:
  /// **'Web path'**
  String get instanceWebPath;

  /// Writerside instance status field.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get instanceStatus;

  /// Regular Writerside instance status.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get instanceStatusRelease;

  /// Writerside early-access instance status.
  ///
  /// In en, this message translates to:
  /// **'Early access'**
  String get instanceStatusEap;

  /// Writerside deprecated instance status.
  ///
  /// In en, this message translates to:
  /// **'Deprecated'**
  String get instanceStatusDeprecated;

  /// Per-instance Writerside search-engine indexing setting.
  ///
  /// In en, this message translates to:
  /// **'Allow search engine indexing'**
  String get allowSearchEngineIndexing;

  /// Description of the Writerside indexing setting.
  ///
  /// In en, this message translates to:
  /// **'Allow external search engines to index this output.'**
  String get allowSearchEngineIndexingDescription;

  /// Per-instance Writerside offline artifact setting.
  ///
  /// In en, this message translates to:
  /// **'Offline artifact'**
  String get offlineArtifact;

  /// Description of the Writerside offline artifact setting.
  ///
  /// In en, this message translates to:
  /// **'Bundle resources so the built documentation is self-contained.'**
  String get offlineArtifactDescription;

  /// Group title for Writerside instance build and publication settings.
  ///
  /// In en, this message translates to:
  /// **'Output settings'**
  String get instanceOutputSettings;

  /// Group title for the source directory of a Writerside Markdown import.
  ///
  /// In en, this message translates to:
  /// **'Markdown source'**
  String get markdownImportSource;

  /// Group title for files selected for a Writerside Markdown import.
  ///
  /// In en, this message translates to:
  /// **'Markdown files'**
  String get markdownImportFiles;

  /// Action that clears all items in a multiple selection.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get selectNone;

  /// Count of discovered Markdown import files.
  ///
  /// In en, this message translates to:
  /// **'{count} Markdown file(s) found'**
  String markdownFilesFound(int count);

  /// Empty state for a Writerside Markdown import source.
  ///
  /// In en, this message translates to:
  /// **'No Markdown files were found in this directory.'**
  String get noMarkdownFilesFound;

  /// Option to copy media used by imported Markdown files.
  ///
  /// In en, this message translates to:
  /// **'Copy referenced media'**
  String get copyReferencedMedia;

  /// Description of the Writerside Markdown media import option.
  ///
  /// In en, this message translates to:
  /// **'Copy local images and video referenced by the selected files while preserving relative paths.'**
  String get copyReferencedMediaDescription;

  /// Confirmation title before refactoring a Writerside instance ID.
  ///
  /// In en, this message translates to:
  /// **'Rename instance ID?'**
  String get instanceIdRenameWarningTitle;

  /// Warning shown before a Writerside instance ID refactor.
  ///
  /// In en, this message translates to:
  /// **'BusyMark will rename the .tree file and update Writerside project references from “{oldId}” to “{newId}”. Publication scripts are not changed and must be updated separately.'**
  String instanceIdRenameWarning(String oldId, String newId);

  /// Confirmation action for a Writerside instance ID refactor.
  ///
  /// In en, this message translates to:
  /// **'Rename and update references'**
  String get renameAndUpdateReferences;

  /// Explanation shown while creating a Writerside TOC library.
  ///
  /// In en, this message translates to:
  /// **'A TOC library stores reusable sections and does not produce its own output.'**
  String get tocLibraryDescription;

  /// Default name for a new Writerside TOC library instance.
  ///
  /// In en, this message translates to:
  /// **'Shared TOC'**
  String get defaultTocLibraryName;

  /// Automatic Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get instanceColorAutomatic;

  /// Blue Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get instanceColorBlue;

  /// Green Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get instanceColorGreen;

  /// Orange Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get instanceColorOrange;

  /// Purple Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get instanceColorPurple;

  /// Red Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get instanceColorRed;

  /// Teal Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get instanceColorTeal;

  /// Yellow Writerside instance icon color option.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get instanceColorYellow;

  /// Validation error for an empty Writerside instance name.
  ///
  /// In en, this message translates to:
  /// **'Enter an instance name.'**
  String get errorWritersideInstanceNameRequired;

  /// Error for a duplicate Writerside instance ID.
  ///
  /// In en, this message translates to:
  /// **'An instance with ID “{id}” already exists.'**
  String errorWritersideInstanceIdExists(String id);

  /// Error for an existing Writerside instance tree path.
  ///
  /// In en, this message translates to:
  /// **'The instance tree already exists: {path}'**
  String errorWritersideInstanceTreeExists(String path);

  /// Error for a missing Writerside Markdown import source.
  ///
  /// In en, this message translates to:
  /// **'The Markdown source directory does not exist: {path}'**
  String errorWritersideInstanceImportSourceMissing(String path);

  /// Validation error when no Markdown import files are selected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one Markdown file to import.'**
  String get errorWritersideInstanceImportSelectionRequired;

  /// Error for an invalid Writerside Markdown import file.
  ///
  /// In en, this message translates to:
  /// **'This is not a readable Markdown file inside the selected source: {path}'**
  String errorWritersideInstanceImportFileInvalid(String path);

  /// Error for a colliding Writerside Markdown import target.
  ///
  /// In en, this message translates to:
  /// **'Import would overwrite an existing project file: {path}'**
  String errorWritersideInstanceImportTargetExists(String path);

  /// Concurrent-change error for a Writerside instance mutation.
  ///
  /// In en, this message translates to:
  /// **'Instance files changed on disk. Review them and try again.'**
  String get errorWritersideInstanceFilesChanged;

  /// Error when a Writerside instance mutation rollback is incomplete.
  ///
  /// In en, this message translates to:
  /// **'BusyMark could not completely roll back the instance change. Review these files before continuing: {paths}'**
  String errorWritersideInstanceRollbackFailed(String paths);

  /// Error when Markdown import is requested for a TOC library.
  ///
  /// In en, this message translates to:
  /// **'A TOC library cannot import Markdown topics.'**
  String get errorWritersideInstanceLibraryImport;

  /// Validation error for an invalid Writerside instance web path.
  ///
  /// In en, this message translates to:
  /// **'The web path must be a single line.'**
  String get errorWritersideInstanceWebPathInvalid;

  /// Error when an instance tree, project config, or build profiles file cannot be safely edited.
  ///
  /// In en, this message translates to:
  /// **'The Writerside instance configuration is invalid. Correct its diagnostics and try again.'**
  String get errorWritersideInstanceConfigurationInvalid;

  /// Error when a temporary file for an instance mutation cannot be created.
  ///
  /// In en, this message translates to:
  /// **'BusyMark could not stage the instance changes safely.'**
  String get errorWritersideInstanceTemporaryFile;

  /// Diagnostic for an unsupported Writerside instance status.
  ///
  /// In en, this message translates to:
  /// **'Unknown instance status “{status}”. Use release, eap, or deprecated.'**
  String diagnosticWritersideTreeInvalidStatus(String status);

  /// Diagnostic for a duplicate Writerside instance ID.
  ///
  /// In en, this message translates to:
  /// **'The instance ID “{id}” is used by more than one tree file.'**
  String diagnosticWritersideDuplicateInstanceId(String id);

  /// Diagnostic for an invalid Writerside build profiles root.
  ///
  /// In en, this message translates to:
  /// **'buildprofiles.xml must have a <buildprofiles> root element.'**
  String get diagnosticWritersideBuildProfilesInvalidRoot;

  /// Diagnostic for an invalid Writerside build profile Boolean.
  ///
  /// In en, this message translates to:
  /// **'The {name} value “{value}” must be true or false.'**
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  );

  /// Diagnostic for a Writerside build profile without an instance attribute.
  ///
  /// In en, this message translates to:
  /// **'A <build-profile> element must specify an instance ID.'**
  String get diagnosticWritersideBuildProfileMissingInstance;

  /// Diagnostic for an incomplete Writerside tree include.
  ///
  /// In en, this message translates to:
  /// **'A tree <include> must specify both from and element-id.'**
  String get diagnosticWritersideTreeInvalidInclude;

  /// Diagnostic for a Writerside tree snippet without an ID.
  ///
  /// In en, this message translates to:
  /// **'A tree <snippet> must specify an id.'**
  String get diagnosticWritersideTreeMissingSnippetId;

  /// Diagnostic for an incomplete Writerside ref/in pair.
  ///
  /// In en, this message translates to:
  /// **'A cross-instance TOC reference must specify both ref and in.'**
  String get diagnosticWritersideTreeInvalidCrossInstanceReference;

  /// Diagnostic for conflicting Writerside TOC targets.
  ///
  /// In en, this message translates to:
  /// **'A TOC element cannot target more than one topic, reference, link, or redirect.'**
  String get diagnosticWritersideTreeConflictingTargets;

  /// Diagnostic for a duplicate Writerside tree element ID.
  ///
  /// In en, this message translates to:
  /// **'Tree element ID “{id}” is declared more than once.'**
  String diagnosticWritersideTreeDuplicateElementId(String id);

  /// Diagnostic for an invalid Writerside instance groups root.
  ///
  /// In en, this message translates to:
  /// **'The instance groups file must have an <instance-groups> root element.'**
  String get diagnosticWritersideInstanceGroupsInvalidRoot;

  /// Diagnostic for an invalid Writerside instance group.
  ///
  /// In en, this message translates to:
  /// **'An instance group must specify a non-empty id and instances list.'**
  String get diagnosticWritersideInstanceGroupInvalid;

  /// Diagnostic for a duplicate Writerside instance group ID.
  ///
  /// In en, this message translates to:
  /// **'Instance group ID “{id}” is declared more than once.'**
  String diagnosticWritersideInstanceGroupDuplicateId(String id);

  /// Diagnostic for a tree include from another Writerside module.
  ///
  /// In en, this message translates to:
  /// **'TOC include “{source}#{id}” belongs to external module “{origin}” and cannot be expanded in this workspace.'**
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  );

  /// Diagnostic for a missing reusable tree element.
  ///
  /// In en, this message translates to:
  /// **'Tree element “{id}” does not exist in registered tree “{source}”.'**
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  );

  /// Diagnostic for a circular Writerside tree include.
  ///
  /// In en, this message translates to:
  /// **'Tree include “{source}#{id}” creates a cycle.'**
  String diagnosticWritersideTreeCircularInclude(String source, String id);

  /// Diagnostic for an unknown Writerside instance group.
  ///
  /// In en, this message translates to:
  /// **'Instance condition references unknown group “@{group}”.'**
  String diagnosticWritersideUnknownInstanceGroup(String group);

  /// Diagnostic for a missing Writerside reference instance.
  ///
  /// In en, this message translates to:
  /// **'Cross-instance reference targets unknown instance “{instance}”.'**
  String diagnosticWritersideReferenceInstanceMissing(String instance);

  /// Diagnostic for a missing topic in a cross-instance Writerside reference.
  ///
  /// In en, this message translates to:
  /// **'Topic “{topic}” is not in referenced instance “{instance}”.'**
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  );

  /// Button label that downloads a required component.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Menu action and dialog title for exporting a Writerside instance as PDF.
  ///
  /// In en, this message translates to:
  /// **'Export Writerside as PDF'**
  String get exportWritersideAsPdf;

  /// Introduction to Writerside PDF export.
  ///
  /// In en, this message translates to:
  /// **'Choose an instance and PDF settings. BusyMark uses JetBrains’ official Writerside builder.'**
  String get writersidePdfExportDescription;

  /// Group title for selecting Writerside PDF content.
  ///
  /// In en, this message translates to:
  /// **'Export content'**
  String get writersidePdfContent;

  /// Label for the source of Writerside PDF settings.
  ///
  /// In en, this message translates to:
  /// **'PDF settings'**
  String get writersidePdfSettings;

  /// Option to configure Writerside PDF settings in the export dialog.
  ///
  /// In en, this message translates to:
  /// **'Configure for this export'**
  String get writersidePdfConfigureHere;

  /// Option to use an existing Writerside PDF configuration file.
  ///
  /// In en, this message translates to:
  /// **'Use project configuration'**
  String get writersidePdfProjectConfiguration;

  /// Writerside PDF configuration file selector label.
  ///
  /// In en, this message translates to:
  /// **'PDF configuration file'**
  String get writersidePdfConfigurationFile;

  /// Writerside PDF page settings group title.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get writersidePdfPage;

  /// Writerside PDF keymap selector label.
  ///
  /// In en, this message translates to:
  /// **'Keymap'**
  String get writersidePdfKeymap;

  /// Writerside PDF option that omits a keymap layout.
  ///
  /// In en, this message translates to:
  /// **'No keymap'**
  String get writersidePdfNoKeymap;

  /// Writerside PDF table-of-contents title field.
  ///
  /// In en, this message translates to:
  /// **'Table of contents title'**
  String get writersidePdfTocTitle;

  /// Writerside PDF cover-page settings group title.
  ///
  /// In en, this message translates to:
  /// **'Cover page'**
  String get writersidePdfCover;

  /// Toggle that includes a cover page in a Writerside PDF.
  ///
  /// In en, this message translates to:
  /// **'Include cover page'**
  String get writersidePdfIncludeCover;

  /// Writerside PDF cover title field.
  ///
  /// In en, this message translates to:
  /// **'Cover title'**
  String get writersidePdfCoverTitle;

  /// Writerside PDF cover description field.
  ///
  /// In en, this message translates to:
  /// **'Cover description'**
  String get writersidePdfCoverDescription;

  /// Writerside PDF cover copyright field.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get writersidePdfCopyright;

  /// Writerside PDF cover logo path field.
  ///
  /// In en, this message translates to:
  /// **'Cover logo'**
  String get writersidePdfCoverLogo;

  /// Action that selects a Writerside PDF cover logo.
  ///
  /// In en, this message translates to:
  /// **'Choose cover logo'**
  String get writersidePdfChooseCoverLogo;

  /// Writerside PDF header and footer settings group title.
  ///
  /// In en, this message translates to:
  /// **'Header and footer'**
  String get writersidePdfHeaderAndFooter;

  /// Writerside PDF page header field.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get writersidePdfHeader;

  /// Writerside PDF page footer field.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get writersidePdfFooter;

  /// Description of advanced Writerside PDF settings.
  ///
  /// In en, this message translates to:
  /// **'These values map the opened module to the builder’s source layout.'**
  String get writersidePdfAdvancedDescription;

  /// Writerside builder module-name field.
  ///
  /// In en, this message translates to:
  /// **'Module name'**
  String get writersidePdfModuleName;

  /// Writerside builder source-root field.
  ///
  /// In en, this message translates to:
  /// **'Source root'**
  String get writersidePdfSourceRoot;

  /// Action that selects the Writerside builder source root.
  ///
  /// In en, this message translates to:
  /// **'Choose source root'**
  String get writersidePdfChooseSourceRoot;

  /// JetBrains Writerside builder image version field.
  ///
  /// In en, this message translates to:
  /// **'Builder version'**
  String get writersidePdfBuilderVersion;

  /// Toggle that allows network access in the Writerside builder container.
  ///
  /// In en, this message translates to:
  /// **'Allow network during build'**
  String get writersidePdfAllowNetwork;

  /// Security guidance for Writerside builder network access.
  ///
  /// In en, this message translates to:
  /// **'Disabled by default. Enable only when the project intentionally needs remote build resources.'**
  String get writersidePdfAllowNetworkDescription;

  /// Validation error for a missing Writerside module name.
  ///
  /// In en, this message translates to:
  /// **'Enter the module name.'**
  String get writersidePdfModuleNameRequired;

  /// Validation error for a missing Writerside source root.
  ///
  /// In en, this message translates to:
  /// **'Choose the source root.'**
  String get writersidePdfSourceRootRequired;

  /// Validation error for an invalid Writerside builder version.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid builder version.'**
  String get writersidePdfBuilderVersionInvalid;

  /// Dialog title when the Writerside builder image is not installed.
  ///
  /// In en, this message translates to:
  /// **'Writerside builder required'**
  String get writersidePdfBuilderRequired;

  /// Consent prompt before downloading the Writerside builder image.
  ///
  /// In en, this message translates to:
  /// **'BusyMark uses the official {image} container image. Download it now? The image is large and is stored by Docker.'**
  String writersidePdfBuilderDownloadDescription(String image);

  /// Progress title while downloading the Writerside builder image.
  ///
  /// In en, this message translates to:
  /// **'Downloading Writerside builder…'**
  String get writersidePdfDownloadingBuilder;

  /// Progress title while building a Writerside PDF.
  ///
  /// In en, this message translates to:
  /// **'Exporting Writerside PDF…'**
  String get exportingWritersidePdf;

  /// Error shown when Docker is unavailable for Writerside PDF export.
  ///
  /// In en, this message translates to:
  /// **'Docker is required for Writerside PDF export. Install and start Docker, then try again.'**
  String get writersidePdfDockerUnavailable;

  /// Error shown when the Writerside builder image cannot be used.
  ///
  /// In en, this message translates to:
  /// **'The requested Writerside builder image is not available.'**
  String get writersidePdfBuilderUnavailable;

  /// Error shown for an invalid Writerside PDF configuration.
  ///
  /// In en, this message translates to:
  /// **'The Writerside PDF configuration is invalid.'**
  String get writersidePdfConfigurationInvalid;

  /// Error shown when the Writerside PDF build fails.
  ///
  /// In en, this message translates to:
  /// **'The Writerside builder could not create the PDF.'**
  String get writersidePdfBuildFailed;

  /// Error shown when the Writerside builder output is missing or invalid.
  ///
  /// In en, this message translates to:
  /// **'The Writerside builder did not produce a valid PDF.'**
  String get writersidePdfInvalidOutput;

  /// Settings section and editing menu label for artificial-intelligence features.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// AI provider option for a loopback Ollama service.
  ///
  /// In en, this message translates to:
  /// **'Local Ollama'**
  String get aiLocalOllama;

  /// AI provider option that disables AI features.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get aiDisabled;

  /// Privacy description for BusyMark local AI.
  ///
  /// In en, this message translates to:
  /// **'AI editing is explicit. BusyMark sends only the context shown for the selected provider and never applies a proposal without review.'**
  String get aiLocalOnlyDescription;

  /// Label for an AI provider selection.
  ///
  /// In en, this message translates to:
  /// **'AI provider'**
  String get aiProvider;

  /// Settings label for the provider selected by default for AI actions.
  ///
  /// In en, this message translates to:
  /// **'Default provider'**
  String get aiDefaultProvider;

  /// Settings label for choosing which AI provider configuration to edit.
  ///
  /// In en, this message translates to:
  /// **'Configure provider'**
  String get aiConfigureProvider;

  /// Dialog title shown before selecting the AI provider for an action.
  ///
  /// In en, this message translates to:
  /// **'Choose AI provider'**
  String get aiChooseProvider;

  /// Settings label for the local Ollama origin.
  ///
  /// In en, this message translates to:
  /// **'Ollama endpoint'**
  String get aiOllamaEndpoint;

  /// Settings label for the installed Ollama model.
  ///
  /// In en, this message translates to:
  /// **'Ollama model'**
  String get aiOllamaModel;

  /// Button that verifies generation with the configured AI provider and model.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get aiTestConnection;

  /// Status while BusyMark verifies the configured AI provider and model.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get aiTestingConnection;

  /// Successful Ollama connection status.
  ///
  /// In en, this message translates to:
  /// **'Connected. {count} installed model(s) found.'**
  String aiConnectionReady(int count);

  /// AI model setting shown before a model has been selected or discovered.
  ///
  /// In en, this message translates to:
  /// **'No model selected.'**
  String get aiNoModels;

  /// Generic failure shown while testing AI generation.
  ///
  /// In en, this message translates to:
  /// **'BusyMark could not verify AI text generation.'**
  String get aiConnectionFailed;

  /// Message shown when an AI action is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Enable an AI provider and verify a model in Settings → AI.'**
  String get aiConfigureFirst;

  /// No description provided for @aiEditWithAi.
  ///
  /// In en, this message translates to:
  /// **'Edit with AI'**
  String get aiEditWithAi;

  /// Selected-text context-menu action that opens AI refinement.
  ///
  /// In en, this message translates to:
  /// **'Refine with AI'**
  String get aiRefineWithAi;

  /// No description provided for @aiInstruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get aiInstruction;

  /// No description provided for @aiChangeTarget.
  ///
  /// In en, this message translates to:
  /// **'What may change'**
  String get aiChangeTarget;

  /// No description provided for @aiSharedContext.
  ///
  /// In en, this message translates to:
  /// **'Context shared with AI'**
  String get aiSharedContext;

  /// No description provided for @aiTargetSelection.
  ///
  /// In en, this message translates to:
  /// **'Selected content'**
  String get aiTargetSelection;

  /// No description provided for @aiTargetInsertAfterBlock.
  ///
  /// In en, this message translates to:
  /// **'Insert after current block'**
  String get aiTargetInsertAfterBlock;

  /// No description provided for @aiTargetCurrentBlock.
  ///
  /// In en, this message translates to:
  /// **'Current block'**
  String get aiTargetCurrentBlock;

  /// No description provided for @aiTargetCurrentSection.
  ///
  /// In en, this message translates to:
  /// **'Current section'**
  String get aiTargetCurrentSection;

  /// No description provided for @aiTargetCompleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Complete document'**
  String get aiTargetCompleteDocument;

  /// No description provided for @aiContextNone.
  ///
  /// In en, this message translates to:
  /// **'No document context'**
  String get aiContextNone;

  /// No description provided for @aiContextSelection.
  ///
  /// In en, this message translates to:
  /// **'Selected content'**
  String get aiContextSelection;

  /// No description provided for @aiContextCurrentBlock.
  ///
  /// In en, this message translates to:
  /// **'Current block'**
  String get aiContextCurrentBlock;

  /// No description provided for @aiContextCurrentSection.
  ///
  /// In en, this message translates to:
  /// **'Current section'**
  String get aiContextCurrentSection;

  /// No description provided for @aiContextCompleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Complete document'**
  String get aiContextCompleteDocument;

  /// Progress text while an AI proposal streams.
  ///
  /// In en, this message translates to:
  /// **'Generating proposal…'**
  String get aiGenerating;

  /// Title of the AI proposal review dialog.
  ///
  /// In en, this message translates to:
  /// **'AI proposal'**
  String get aiProposal;

  /// Button that starts generation after the user reviews the AI instruction, change target, and shared context.
  ///
  /// In en, this message translates to:
  /// **'Generate proposal'**
  String get aiGenerateProposal;

  /// Disclosure of AI context size.
  ///
  /// In en, this message translates to:
  /// **'The selected provider will receive {count} characters from the displayed context.'**
  String aiContextDisclosure(int count);

  /// Label for original text in an AI proposal review.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get aiOriginal;

  /// Label for proposed text in an AI proposal review.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get aiSuggested;

  /// Button that applies a reviewed AI proposal.
  ///
  /// In en, this message translates to:
  /// **'Apply proposal'**
  String get aiApplyProposal;

  /// Local Ollama token usage for one proposal.
  ///
  /// In en, this message translates to:
  /// **'{input} input tokens · {output} output tokens'**
  String aiTokenUsage(int input, int output);

  /// Message for an AI result based on an old editor revision.
  ///
  /// In en, this message translates to:
  /// **'The document changed while this proposal was generated. Run the action again.'**
  String get aiStaleProposal;

  /// Warning shown when an AI commit-message proposal was generated from an obsolete staged diff.
  ///
  /// In en, this message translates to:
  /// **'The staged changes changed while this commit message was generated. Run the action again.'**
  String get gitAiStagedChangesChanged;

  /// Action that reveals the exact AI input context.
  ///
  /// In en, this message translates to:
  /// **'View context sent'**
  String get aiViewContext;

  /// Action that reveals the exact content affected by and shared with an AI edit.
  ///
  /// In en, this message translates to:
  /// **'Review exact content'**
  String get aiReviewExactContent;

  /// Label for the exact Markdown that an AI proposal may change.
  ///
  /// In en, this message translates to:
  /// **'Content to change'**
  String get aiContentToChange;

  /// Label for the exact document context that will be sent to the configured AI provider.
  ///
  /// In en, this message translates to:
  /// **'Content sent to AI'**
  String get aiContentSentToAi;

  /// Label for a cloud AI provider API key.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiApiKey;

  /// Hint when a cloud API key is already stored.
  ///
  /// In en, this message translates to:
  /// **'A key is stored in the system credential store'**
  String get aiApiKeyStoredHint;

  /// Hint for entering a cloud provider API key.
  ///
  /// In en, this message translates to:
  /// **'Enter a provider API key'**
  String get aiApiKeyEnterHint;

  /// Action that replaces a stored cloud provider key.
  ///
  /// In en, this message translates to:
  /// **'Replace API key'**
  String get aiReplaceApiKey;

  /// Action that saves a cloud provider key to the system credential store.
  ///
  /// In en, this message translates to:
  /// **'Save API key securely'**
  String get aiSaveApiKey;

  /// Action that removes a cloud provider key from the system credential store.
  ///
  /// In en, this message translates to:
  /// **'Remove saved API key'**
  String get aiRemoveApiKey;

  /// Confirmation after saving an AI provider key.
  ///
  /// In en, this message translates to:
  /// **'API key saved in the system credential store.'**
  String get aiCredentialSaved;

  /// Confirmation after removing an AI provider key.
  ///
  /// In en, this message translates to:
  /// **'The saved API key was removed.'**
  String get aiCredentialRemoved;

  /// Settings label for AI model routing.
  ///
  /// In en, this message translates to:
  /// **'Model routing'**
  String get aiModelRouting;

  /// AI model routing option that chooses by task class.
  ///
  /// In en, this message translates to:
  /// **'Automatic by task'**
  String get aiAutomaticRouting;

  /// AI model routing option that always uses the preferred model.
  ///
  /// In en, this message translates to:
  /// **'Use selected model'**
  String get aiFixedModelRouting;

  /// Settings label for a preferred cloud AI model.
  ///
  /// In en, this message translates to:
  /// **'Preferred model'**
  String get aiPreferredModel;

  /// Label for selecting a model for one AI request.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// Local monthly AI usage summary.
  ///
  /// In en, this message translates to:
  /// **'{requests} requests · {input} input tokens · {output} output tokens'**
  String aiUsageThisMonth(int requests, int input, int output);

  /// Cloud AI data-sharing confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Send content to {provider}?'**
  String aiCloudConsentTitle(String provider);

  /// Action that confirms use of a cloud AI provider.
  ///
  /// In en, this message translates to:
  /// **'Enable {provider}'**
  String aiCloudConsentEnable(String provider);

  /// Cloud AI data-sharing and credential disclosure.
  ///
  /// In en, this message translates to:
  /// **'Only content shown in each AI review dialog is sent. Requests are stateless, proposals require review, and the API key is stored in the Linux system credential store.'**
  String get aiCloudConsentMessage;

  /// AI action error when cloud consent is missing.
  ///
  /// In en, this message translates to:
  /// **'Confirm {provider} data sharing in Settings → AI first.'**
  String aiCloudConsentRequired(String provider);

  /// Successful AI model generation qualification.
  ///
  /// In en, this message translates to:
  /// **'Generation verified with {model}. {count} compatible model(s) available.'**
  String aiGenerationVerified(String model, int count);

  /// Additional model qualification status when local generation required a cold start.
  ///
  /// In en, this message translates to:
  /// **'A local model cold start was observed.'**
  String get aiColdStartObserved;

  /// AI connection status when no compatible generation model is available.
  ///
  /// In en, this message translates to:
  /// **'No compatible text-generation model is available.'**
  String get aiNoCompatibleModels;

  /// AI settings error when no provider is enabled.
  ///
  /// In en, this message translates to:
  /// **'Enable an AI provider first.'**
  String get aiEnableProvider;

  /// AI action that drafts a Git commit message.
  ///
  /// In en, this message translates to:
  /// **'Draft commit message'**
  String get aiDraftCommitMessage;

  /// Progress label while AI drafts a commit message.
  ///
  /// In en, this message translates to:
  /// **'Drafting…'**
  String get aiDrafting;

  /// Action that drafts a Git commit message with AI.
  ///
  /// In en, this message translates to:
  /// **'Draft with AI'**
  String get aiDraftWithAi;

  /// Deterministic action that creates or refreshes a Markdown table of contents.
  ///
  /// In en, this message translates to:
  /// **'Generate/update table of contents'**
  String get generateOrUpdateMarkdownToc;

  /// Heading inserted above a generated Markdown table of contents.
  ///
  /// In en, this message translates to:
  /// **'Table of contents'**
  String get markdownTocTitle;

  /// Confirmation after generating a Markdown table of contents.
  ///
  /// In en, this message translates to:
  /// **'Table of contents updated with {count} entries.'**
  String markdownTocUpdated(int count);

  /// Message when a Markdown document has no section headings for a generated table of contents.
  ///
  /// In en, this message translates to:
  /// **'Add at least one section heading before generating a table of contents.'**
  String get markdownTocNoHeadings;

  /// Message when a generated Markdown table-of-contents region cannot be safely updated.
  ///
  /// In en, this message translates to:
  /// **'The BusyMark table-of-contents markers are missing, duplicated, or out of order.'**
  String get markdownTocMalformedMarkers;

  /// Accessibility diagnostic for a skipped Markdown heading level.
  ///
  /// In en, this message translates to:
  /// **'Heading level {level} follows level {previousLevel}; review the section nesting.'**
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel);

  /// Accessibility diagnostic for a Markdown link without text.
  ///
  /// In en, this message translates to:
  /// **'Link text is empty; provide an accessible name that describes its purpose.'**
  String get diagnosticMarkdownLinkEmptyText;

  /// Accessibility hint for potentially non-descriptive Markdown link text.
  ///
  /// In en, this message translates to:
  /// **'Review whether the link text “{text}” describes its purpose in context.'**
  String diagnosticMarkdownLinkReviewText(String text);

  /// Accessibility diagnostic for an empty Markdown table header cell.
  ///
  /// In en, this message translates to:
  /// **'Table header cells must identify their columns; complete each empty header.'**
  String get diagnosticMarkdownTableEmptyHeader;

  /// Tooltip and diagnostic text shown when a mathematical expression cannot be rendered.
  ///
  /// In en, this message translates to:
  /// **'The mathematical expression could not be rendered.'**
  String get mathRenderFailed;

  /// Editor action that inserts an inline mathematical expression.
  ///
  /// In en, this message translates to:
  /// **'Inline math'**
  String get inlineMath;

  /// Editor action that inserts a display mathematical expression.
  ///
  /// In en, this message translates to:
  /// **'Display math'**
  String get displayMath;
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
    'et',
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
    case 'et':
      return AppLocalizationsEt();
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

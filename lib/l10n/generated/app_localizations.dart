import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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

  /// Tooltip for the main application menu button.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenuTooltip;

  /// Main menu item that opens settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsMenuItem;

  /// Main menu item that opens the keyboard shortcuts dialog.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcutsMenuItem;

  /// Main menu item that opens the about dialog.
  ///
  /// In en, this message translates to:
  /// **'About BusyMark'**
  String get aboutBusyMarkMenuItem;

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

  /// Settings switch title for always-on-top window behavior.
  ///
  /// In en, this message translates to:
  /// **'Keep BusyMark on top'**
  String get settingsAlwaysOnTopTitle;

  /// Settings switch description for always-on-top window behavior.
  ///
  /// In en, this message translates to:
  /// **'Keep the BusyMark window above other windows when supported by the desktop environment.'**
  String get settingsAlwaysOnTopDescription;

  /// Settings switch description shown when native always-on-top window behavior is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Always-on-top is not available on this desktop environment.'**
  String get settingsAlwaysOnTopUnsupportedDescription;

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

  /// Non-blocking error shown when a native window setting cannot be applied.
  ///
  /// In en, this message translates to:
  /// **'Could not apply the window setting.'**
  String get windowSettingApplyFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

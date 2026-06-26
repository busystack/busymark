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
      'Markdown and Writerside-compatible documentation editor.';

  @override
  String get mainMenuTooltip => 'Main menu';

  @override
  String get settingsMenuItem => 'Settings';

  @override
  String get keyboardShortcutsMenuItem => 'Keyboard Shortcuts';

  @override
  String get aboutBusyMarkMenuItem => 'About BusyMark';

  @override
  String get settingsWindowSectionTitle => 'Window';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirm before closing with unsaved changes';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Ask before closing BusyMark when documents have unsaved changes.';

  @override
  String get settingsAlwaysOnTopTitle => 'Keep BusyMark on top';

  @override
  String get settingsAlwaysOnTopDescription =>
      'Keep the BusyMark window above other windows when supported by the desktop environment.';

  @override
  String get settingsAlwaysOnTopUnsupportedDescription =>
      'Always-on-top is not available on this desktop environment.';

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
  String get windowSettingApplyFailed => 'Could not apply the window setting.';
}

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;
import 'package:ubuntu_localizations/ubuntu_localizations.dart';

import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

const busyMarkLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
  UbuntuLocalizations.delegate,
];

extension BusyMarkLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

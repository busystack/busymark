import 'package:busymark/src/git/application/shared_git_presentation.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:flutter/material.dart';
import '../../../../busystack_git_flutter/test/support/actions_presentation_contract.dart';

void main() {
  test(
    'view Actions require three-bar artwork even without a GTK icon catalog',
    () {
      expect(busyMarkGitIcons[git.GitGlyph.actions], YaruIcons.menu);
      expect(
        busyMarkGitIcons[git.GitGlyph.actions],
        isNot(YaruIcons.view_more),
      );
      expect(
        busyMarkGitIcons[git.GitGlyph.actions],
        isNot(YaruIcons.view_more_horizontal),
      );
    },
  );
  actionsPresentationContract(
    presentation: const BusyMarkGitPresentation(),
    icons: busyMarkGitIcons,
    actionsGlyph: BusyMarkGlyphs.mainMenu,
    contextGlyph: BusyMarkGlyphs.menuHorizontal,
    nativeReference: (activate) => BusyMarkHeaderIconButton(
      tooltip: 'Native reference',
      icon: BusyMarkGlyphs.mainMenu,
      focusBorderRadius: BusyMarkRadius.headerButton,
      onPressed: activate,
    ),
    shell: (child, brightness, direction) => MaterialApp(
      theme: buildBusyMarkTheme(
        brightness: brightness,
        accentColor: busyMarkDefaultAccentColor,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Directionality(textDirection: direction, child: child),
      ),
    ),
  );
}

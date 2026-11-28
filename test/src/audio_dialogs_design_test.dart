import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/editor/audio_authoring.dart';
import 'package:busymark/src/editor/audio_dialogs.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<BuildContext> mount(
    WidgetTester tester, {
    required Locale locale,
    required Brightness brightness,
    double scale = 1,
    FocusNode? focus,
  }) async {
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: busyMarkLocalizationsDelegates,
        theme: buildBusyMarkTheme(
          brightness: brightness,
          accentColor: const Color(0xff3584e4),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            host = context;
            return Scaffold(
              body: BusyMarkGroupedTextEntry(
                label: 'Document',
                focusNode: focus,
              ),
            );
          },
        ),
      ),
    );
    return host;
  }

  Finder action(String label) => find.byWidgetPredicate(
    (widget) => widget is BusyMarkDialogButton && widget.label == label,
  );
  final entry = find.descendant(
    of: find.byType(BusyMarkDialogShell),
    matching: find.byType(EditableText),
  );

  testWidgets(
    'Insert Audio wraps localized choices and errors and restores focus',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(520, 620));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final host = await mount(
        tester,
        locale: const Locale('ru'),
        brightness: Brightness.light,
        scale: 1.45,
        focus: focus,
      );
      focus.requestFocus();
      await tester.pump();
      Future<AudioInsertion?> open() => showBusyMarkModalDialog<AudioInsertion>(
        host,
        builder: (_) => const InsertAudioDialog(canLinkFile: true),
      );
      final result = open();
      await tester.pumpAndSettle();

      final labels = host.l10n;
      expect(find.byType(BusyMarkModalShortcutBoundary), findsOneWidget);
      expect(find.byType(BusyMarkDialogShell), findsOneWidget);
      expect(find.byType(BusyMarkGroupedList), findsNWidgets(2));
      expect(find.byType(BusyMarkActionRow), findsNWidgets(2));
      expect(
        tester.getSize(find.text(labels.audioCopyFile)).height,
        greaterThan(36),
      );
      expect(
        tester
            .widget<BusyMarkDialogButton>(action(labels.insertAudio))
            .suggested,
        isTrue,
      );
      await tester.tap(action(labels.insertAudio));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.text(labels.audioInvalidUrl)).height,
        greaterThan(36),
      );
      await tester.enterText(entry, 'https://example.org/sound.ogg?v=1#t=3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect((await result)?.url, 'https://example.org/sound.ogg?v=1#t=3');
      expect(focus.hasFocus, isTrue);

      final linked = open();
      await tester.pumpAndSettle();
      await tester.tap(find.text(labels.audioLinkFile));
      await tester.pumpAndSettle();
      expect((await linked)?.link, isTrue);
    },
  );

  testWidgets(
    'Russian Audio Properties scales with shared destructive actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(520, 620));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final host = await mount(
        tester,
        locale: const Locale('ru'),
        brightness: Brightness.dark,
        scale: 1.45,
      );
      final labels = host.l10n;
      const original = "<audio controls src='clip.wav'></audio>";
      Future<String?> open() => showBusyMarkModalDialog<String>(
        host,
        builder: (_) => AudioPropertiesDialog(
          audio: parseAuthoredAudio(original)!,
          localPath: '/docs/clip.wav',
        ),
      );
      final result = open();
      await tester.pumpAndSettle();
      expect(find.byType(BusyMarkDialogShell), findsOneWidget);
      expect(find.byType(BusyMarkActionRow), findsNWidgets(2));
      expect(
        tester
            .widget<BusyMarkDialogButton>(action(labels.audioRemove))
            .destructive,
        isTrue,
      );
      expect(tester.widget<EditableText>(entry).controller.text, original);
      expect(tester.takeException(), isNull);
      await tester.enterText(entry, '<audio');
      await tester.tap(action(labels.apply));
      await tester.pump();
      expect(find.text(labels.audioInvalidMarkup), findsOneWidget);
      const replacement = "<audio controls src='new.wav'></audio>";
      await tester.enterText(entry, replacement);
      await tester.tap(action(labels.apply));
      await tester.pumpAndSettle();
      expect(await result, replacement);

      final dismissed = open();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await dismissed, isNull);
    },
  );
}

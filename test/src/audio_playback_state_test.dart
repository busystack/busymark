import 'dart:io';

import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/editor/audio_playback.dart';
import 'package:busymark/src/editor/document_audio_view.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('playback button has an accessible name and action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: busyMarkLocalizationsDelegates,
          home: Material(
            child: BusyMarkAudioTransport(
              owner: 'owned',
              label: 'Recorded introduction',
              start: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final play = find.bySemanticsLabel('Play');
      expect(play, findsOneWidget);
      expect(find.byType(BusyMarkCompactIconButton), findsOneWidget);
      expect(
        tester
            .getSemantics(play)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('seekable audio uses shared sliders, selector and loop state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const channel = MethodChannel('com.busymark.app/audio_player');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'position' => {'position': 1.0, 'duration': 5.0, 'seekable': true},
        _ => true,
      };
    });
    final playback = AudioPlayback.shared;
    final owner = Object();
    addTearDown(() async {
      await playback.close(owner);
      messenger.setMockMethodCallHandler(channel, null);
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: busyMarkLocalizationsDelegates,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: const Color(0xff3584e4),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.45)),
          child: child!,
        ),
        home: Material(
          child: ListenableBuilder(
            listenable: playback,
            builder: (context, _) => BusyMarkAudioTransport(
              owner: owner,
              label: 'Test audio',
              start: () async {},
            ),
          ),
        ),
      ),
    );
    expect(await playback.open(owner, File('/owned.wav')), isTrue);
    final arguments = calls.single.arguments as Map;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('state', {'id': arguments['id'], 'state': 'playing'}),
      ),
      (_) {},
    );
    await tester.pump();
    final player = find.byType(BusyMarkAudioTransport);
    final labels = tester.element(player).l10n;
    final sliders = tester.widgetList<BusyMarkRangeSlider>(
      find.byType(BusyMarkRangeSlider),
    );
    expect(sliders.map((slider) => slider.label), [
      labels.audioPosition,
      labels.audioVolume,
    ]);
    final rate = tester.widget<BusyMarkPopupSelector<double>>(
      find.byType(BusyMarkPopupSelector<double>),
    );
    expect(rate.enabled, isTrue);
    expect(rate.options.map((option) => option.value), [
      0.5,
      0.75,
      1.0,
      1.25,
      1.5,
      2.0,
    ]);
    final loop = find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkCompactIconButton &&
          widget.tooltip == labels.audioLoop,
    );
    expect(tester.widget<BusyMarkCompactIconButton>(loop).selected, isFalse);
    await tester.tap(loop);
    await tester.pump();
    expect(tester.widget<BusyMarkCompactIconButton>(loop).selected, isTrue);
    expect(calls.last.method, 'audio');
    expect((calls.last.arguments as Map)['loop'], isTrue);
    expect(tester.takeException(), isNull);
    await playback.close(owner);
    await tester.pump();
  });

  test('a native pause event before the method reply stays paused', () async {
    const channel = MethodChannel('com.busymark.app/audio_player');
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    Future<void> send(int? id, String state) => messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall('state', {'id': id, 'state': state})),
      (_) {},
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = (call.arguments as Map).cast<String, Object>();
      final id = arguments['id']! as int;
      calls.add(call.method);
      switch (call.method) {
        case 'open':
        case 'play':
          await send(id, 'playing');
          return true;
        case 'pause':
          await send(id, 'paused');
          return true;
        case 'position':
          return {'position': 1.0, 'duration': 4.0, 'seekable': true};
        default:
          return true;
      }
    });
    final playback = AudioPlayback.shared;
    final owner = Object();
    addTearDown(() async {
      await playback.close(owner);
      messenger.setMockMethodCallHandler(channel, null);
    });
    expect(await playback.open(owner, File('/owned.wav')), true);
    expect(playback.state, AudioPlaybackState.playing);
    await playback.toggle(owner);
    expect(playback.state, AudioPlaybackState.paused);
    await playback.toggle(owner);
    expect(playback.state, AudioPlaybackState.playing);
    expect(calls.where((method) => method != 'position'), [
      'open',
      'pause',
      'play',
    ]);
    await playback.close(owner);
    await send(null, 'playing');
    expect(playback.state, AudioPlaybackState.ready);
  });
}

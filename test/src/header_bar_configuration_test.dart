import 'dart:async';
import 'dart:io';

import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rapid navigation applies only monotonic complete configurations',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      const channel = MethodChannel(
        'com.busymark.test/headerbar-atomic-navigation',
      );
      final atomicCalls = <Map<Object?, Object?>>[];
      Map<Object?, Object?>? initializePayload;
      final firstApplyStarted = Completer<void>();
      final releaseFirstApply = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') {
              initializePayload = Map<Object?, Object?>.from(
                call.arguments! as Map<Object?, Object?>,
              );
              return true;
            }
            if (call.method != 'applyConfiguration') {
              fail('Unexpected legacy call: ${call.method}');
            }
            final payload = Map<Object?, Object?>.from(
              call.arguments! as Map<Object?, Object?>,
            );
            atomicCalls.add(payload);
            if (atomicCalls.length == 1) {
              firstApplyStarted.complete();
              await releaseFirstApply.future;
            }
            return payload['revision'];
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = LinuxHeaderBarService(
        channel: channel,
        sessionId: 'navigation-session',
      );
      await service.initialize();
      final workspace = _configuration(
        title: 'Workspace',
        documentControlsVisible: true,
        searchVisible: true,
        sidebarVisible: true,
        sidebarToggleVisible: true,
        backVisible: true,
      );
      final settings = _configuration(title: 'Settings', backVisible: true);

      final workspaceApplied = service.configurationSynchronizer
          .setConfiguration(workspace);
      await firstApplyStarted.future;
      final settingsApplied = service.configurationSynchronizer
          .setConfiguration(settings);
      final duplicateSettingsApplied = service.configurationSynchronizer
          .setConfiguration(settings);
      releaseFirstApply.complete();
      await Future.wait([
        workspaceApplied,
        settingsApplied,
        duplicateSettingsApplied,
      ]);

      expect(atomicCalls, hasLength(2));
      expect(initializePayload, {'sessionId': 'navigation-session'});
      expect(atomicCalls.map((payload) => payload['sessionId']).toSet(), {
        'navigation-session',
      });
      expect(atomicCalls.map((payload) => payload['revision']), [1, 2]);
      expect(atomicCalls.map((payload) => payload['title']), [
        'Workspace',
        'Settings',
      ]);
      expect(atomicCalls.last, {
        'sessionId': 'navigation-session',
        'revision': 2,
        'title': 'Settings',
        'viewMode': 'editor',
        'searchQuery': '',
        'textDirection': 'ltr',
        'canRefresh': false,
        'canExportPdf': false,
        'canExportHtml': false,
        'documentControlsVisible': false,
        'searchActive': false,
        'searchVisible': false,
        'sidebarVisible': false,
        'sidebarToggleVisible': false,
        'backVisible': true,
        'fullScreen': false,
        'modalBarrierVisible': false,
        'modalBarrierDepth': 0,
        'sidebarWidth': 300.0,
        'labels': _labels.toMap(),
        'theme': _theme.toMap(),
      });
      expect(
        service.configurationSynchronizer.appliedConfiguration?.title,
        'Settings',
      );
    },
  );

  test('a new Dart session can restart native revisions from one', () async {
    if (!Platform.isLinux) {
      return;
    }
    const channel = MethodChannel(
      'com.busymark.test/headerbar-hot-restart-session',
    );
    var activeSession = 'previous-session';
    var nativeRevision = 42;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final payload = Map<Object?, Object?>.from(
            call.arguments! as Map<Object?, Object?>,
          );
          final sessionId = payload['sessionId']! as String;
          if (call.method == 'initialize') {
            if (sessionId != activeSession) {
              activeSession = sessionId;
              nativeRevision = -1;
            }
            return true;
          }
          expect(call.method, 'applyConfiguration');
          expect(sessionId, activeSession);
          final revision = payload['revision']! as int;
          if (revision > nativeRevision) {
            nativeRevision = revision;
          }
          return nativeRevision;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(
      channel: channel,
      sessionId: 'restarted-session',
    );

    expect(
      await service.configurationSynchronizer.setConfiguration(
        _configuration(title: 'Welcome'),
      ),
      true,
    );
    expect(service.isAvailable, true);
    expect(activeSession, 'restarted-session');
    expect(nativeRevision, 1);
    expect(calls.map((call) => call.method), [
      'initialize',
      'applyConfiguration',
    ]);
  });

  test('modal depth is an atomic overlay on the latest page state', () async {
    if (!Platform.isLinux) {
      return;
    }
    const channel = MethodChannel('com.busymark.test/headerbar-atomic-modal');
    final atomicCalls = <Map<Object?, Object?>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'initialize') {
            return true;
          }
          expect(call.method, 'applyConfiguration');
          final payload = Map<Object?, Object?>.from(
            call.arguments! as Map<Object?, Object?>,
          );
          atomicCalls.add(payload);
          return payload['revision'];
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(channel: channel);
    await service.initialize();
    await service.configurationSynchronizer.setConfiguration(
      _configuration(title: 'Settings', backVisible: true),
    );
    await service.setModalBarrierDepth(1);
    await service.setModalBarrierDepth(2);
    await service.setModalBarrierDepth(1);
    await service.setModalBarrierDepth(0);

    expect(atomicCalls, hasLength(5));
    expect(atomicCalls.map((payload) => payload['revision']), [1, 2, 3, 4, 5]);
    expect(atomicCalls.map((payload) => payload['modalBarrierVisible']), [
      false,
      true,
      true,
      true,
      false,
    ]);
    expect(atomicCalls.map((payload) => payload['modalBarrierDepth']), [
      0,
      1,
      2,
      1,
      0,
    ]);
    expect(
      atomicCalls.every((payload) => payload['title'] == 'Settings'),
      true,
    );
  });

  test('modal barrier is retained before the first page publishes', () async {
    if (!Platform.isLinux) {
      return;
    }
    const channel = MethodChannel(
      'com.busymark.test/headerbar-atomic-early-modal',
    );
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') {
            return true;
          }
          if (call.method == 'applyConfiguration') {
            final payload = Map<Object?, Object?>.from(
              call.arguments! as Map<Object?, Object?>,
            );
            return payload['revision'];
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(channel: channel);
    await service.initialize();
    await service.setModalBarrierDepth(1);
    await service.configurationSynchronizer.setConfiguration(
      _configuration(title: 'Welcome'),
    );

    expect(
      calls
          .where((call) => call.method == 'setModalBarrierDepth')
          .single
          .arguments,
      1,
    );
    final atomicPayload =
        calls
                .where((call) => call.method == 'applyConfiguration')
                .single
                .arguments
            as Map<Object?, Object?>;
    expect(atomicPayload['modalBarrierVisible'], true);
    expect(atomicPayload['modalBarrierDepth'], 1);
  });

  test('older runners fall back once to the ordered legacy protocol', () async {
    if (!Platform.isLinux) {
      return;
    }
    const channel = MethodChannel(
      'com.busymark.test/headerbar-atomic-fallback',
    );
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'initialize') {
            return true;
          }
          if (call.method == 'applyConfiguration') {
            throw MissingPluginException();
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(channel: channel);
    await service.initialize();
    await service.configurationSynchronizer.setConfiguration(
      _configuration(title: 'Welcome'),
    );
    await service.configurationSynchronizer.setConfiguration(
      _configuration(title: 'Settings', backVisible: true),
    );

    expect(
      calls.where((method) => method == 'applyConfiguration'),
      hasLength(1),
    );
    expect(calls.where((method) => method == 'setTitleRange'), hasLength(2));
    expect(calls.last, 'setModalBarrierVisible');
    expect(service.isAvailable, true);
  });

  test(
    'failed atomic apply keeps the last success and retries the same desired state',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      const channel = MethodChannel('com.busymark.test/headerbar-atomic-retry');
      final atomicCalls = <Map<Object?, Object?>>[];
      var initializeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') {
              initializeCalls++;
              return true;
            }
            expect(call.method, 'applyConfiguration');
            final payload = Map<Object?, Object?>.from(
              call.arguments! as Map<Object?, Object?>,
            );
            atomicCalls.add(payload);
            if (atomicCalls.length == 2) {
              throw PlatformException(code: 'native_update_failed');
            }
            return payload['revision'];
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = LinuxHeaderBarService(channel: channel);
      final availabilityChanges = <bool>[];
      service.addListener(
        () => availabilityChanges.add(service.usesNativeHeaderBar),
      );
      await service.initialize();
      final workspace = _configuration(title: 'Workspace');
      final settings = _configuration(title: 'Settings', backVisible: true);

      expect(
        await service.configurationSynchronizer.setConfiguration(workspace),
        true,
      );
      expect(
        await service.configurationSynchronizer.setConfiguration(settings),
        false,
      );

      expect(service.usesNativeHeaderBar, false);
      expect(
        service.configurationSynchronizer.appliedConfiguration?.title,
        'Workspace',
      );
      expect(
        service.configurationSynchronizer.desiredConfiguration?.title,
        'Settings',
      );

      expect(
        await service.configurationSynchronizer.setConfiguration(settings),
        true,
      );
      expect(service.usesNativeHeaderBar, true);
      expect(
        service.configurationSynchronizer.appliedConfiguration?.title,
        'Settings',
      );
      expect(initializeCalls, 2);
      expect(availabilityChanges, [true, false, true]);
      expect(atomicCalls.map((payload) => payload['revision']), [1, 2, 2]);
      expect(atomicCalls.map((payload) => payload['title']), [
        'Workspace',
        'Settings',
        'Settings',
      ]);
    },
  );

  test('theme map contains the native semantic visual roles', () {
    expect(_theme.toMap().keys, {
      'preferDark',
      'backgroundColor',
      'sidebarBackgroundColor',
      'foregroundColor',
      'sidebarBorderColor',
      'modalBarrierColor',
      'tooltip',
    });
    expect(
      _theme.toMap(),
      containsPair('sidebarBorderColor', 'rgba(1,2,3,0.067)'),
    );
    expect(
      _theme.toMap(),
      containsPair('foregroundColor', 'rgba(32,32,32,1.000)'),
    );
    expect(_theme.toMap(), containsPair('tooltip', _tooltipTheme.toMap()));
    expect(
      _tooltipTheme.toMap(),
      containsPair('backgroundColor', 'rgba(0,0,0,0.800)'),
    );
    expect(_tooltipTheme.toMap(), containsPair('borderRadius', 8.0));
    expect(_tooltipTheme.toMap(), containsPair('fontSize', 14.0));
    expect(_tooltipTheme.toMap(), containsPair('horizontalPadding', 10.0));
    expect(_tooltipTheme.toMap(), containsPair('verticalPadding', 6.0));
    expect(_tooltipTheme.toMap(), containsPair('minimumHeight', 30.0));
  });

  test('native header labels expose the Syntax Reference command', () {
    expect(
      _labels.toMap(),
      containsPair('syntaxReference', 'Syntax Reference'),
    );
    expect(_labels.toMap(), containsPair('syntaxReferenceShortcut', 'F1'));
    expect(
      _labels.toMap(),
      containsPair('syntaxReferenceGtkAccelerator', 'F1'),
    );
    expect(_labels.toMap(), isNot(contains('markdownAndHtml')));
  });
}

HeaderBarConfiguration _configuration({
  required String title,
  bool documentControlsVisible = false,
  bool searchVisible = false,
  bool sidebarVisible = false,
  bool sidebarToggleVisible = false,
  bool backVisible = false,
  bool fullScreen = false,
}) {
  return HeaderBarConfiguration(
    title: title,
    viewMode: AppViewMode.editor,
    searchQuery: '',
    textDirection: TextDirection.ltr,
    canRefresh: false,
    documentControlsVisible: documentControlsVisible,
    searchActive: false,
    searchVisible: searchVisible,
    sidebarVisible: sidebarVisible,
    sidebarToggleVisible: sidebarToggleVisible,
    backVisible: backVisible,
    fullScreen: fullScreen,
    modalBarrierDepth: 0,
    sidebarWidth: 300,
    labels: _labels,
    theme: _theme,
  );
}

const _labels = HeaderBarLabels(
  editor: 'Editor',
  source: 'Source',
  preview: 'Preview',
  split: 'Split',
  viewMode: 'View mode',
  editorShortcut: 'Ctrl+1',
  editorGtkAccelerator: '<Primary>1',
  sourceShortcut: 'Ctrl+2',
  sourceGtkAccelerator: '<Primary>2',
  previewShortcut: 'Ctrl+3',
  previewGtkAccelerator: '<Primary>3',
  splitShortcut: 'Ctrl+4',
  splitGtkAccelerator: '<Primary>4',
  search: 'Search',
  searchShortcut: 'Ctrl+F',
  refresh: 'Refresh',
  menu: 'Menu',
  sidebar: 'Sidebar',
  sidebarShortcut: 'F9',
  back: 'Back',
  backShortcut: 'Alt+Left',
  save: 'Save',
  exportPdf: 'Export as PDF',
  exportPdfShortcut: 'Ctrl+Shift+E',
  exportPdfGtkAccelerator: '<Primary><Shift>e',
  fullScreen: 'Full Screen',
  fullScreenShortcut: 'F11',
  fullScreenGtkAccelerator: 'F11',
  settings: 'Settings',
  settingsShortcut: 'Ctrl+,',
  settingsGtkAccelerator: '<Primary>comma',
  keyboardShortcuts: 'Keyboard Shortcuts',
  keyboardShortcutsShortcut: 'Ctrl+?',
  keyboardShortcutsGtkAccelerator: '<Primary>question',
  syntaxReference: 'Syntax Reference',
  syntaxReferenceShortcut: 'F1',
  syntaxReferenceGtkAccelerator: 'F1',
  reportIssue: 'Report Issue',
  aboutBusyMark: 'About BusyMark',
);

const _theme = HeaderBarTheme(
  preferDark: false,
  backgroundColor: Color(0xFFFFFFFF),
  sidebarBackgroundColor: Color(0xFFF6F6F6),
  foregroundColor: Color(0xFF202020),
  sidebarBorderColor: Color(0x11010203),
  modalBarrierColor: Color(0x55000000),
  tooltip: _tooltipTheme,
);

const _tooltipTheme = HeaderBarTooltipTheme(
  backgroundColor: Color.fromRGBO(0, 0, 0, 0.8),
  foregroundColor: Color(0xFFFFFFFF),
  borderColor: Color.fromRGBO(255, 255, 255, 0.1),
  borderRadius: 8,
  fontSize: 14,
  horizontalPadding: 10,
  verticalPadding: 6,
  minimumHeight: 30,
);

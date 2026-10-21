// Compiled release entry point for the real application, not a widget test.
// Success is established by the parent observing natural process exit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

import 'package:busymark/main.dart' as application;
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/linux/linux_window_host.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/writerside_video_player_host.dart';
import 'package:busymark/src/visualization/visualization_card.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_providers.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/writerside/writerside_video.dart';

Iterable<Element> _elements() sync* {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;
  final pending = <Element>[root];
  while (pending.isNotEmpty) {
    final element = pending.removeLast();
    yield element;
    element.visitChildren(pending.add);
  }
}

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 40));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Application close smoke prerequisite');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

bool _editorPublished(String path, String source) => _elements().any((e) {
  final widget = e.widget;
  return switch (widget) {
    BusyMarkSourceEditor() => widget.filePath == path && widget.text == source,
    BusyMarkWysiwygEditor() =>
      widget.document.filePath == path && widget.document.source == source,
    _ => false,
  };
});

Future<void> main(List<String> args) async {
  if (args.length < 2 ||
      Platform.environment['BUSYMARK_RELEASE_SMOKE'] != '1') {
    throw ArgumentError(
      'Expected report path and scenario; smoke opt-in required.',
    );
  }
  final report = File(args[0]);
  final scenario = args[1];
  final checks = <String, Object?>{'scenario': scenario, 'pid': pid};
  Future<void> publish(String phase) => report.writeAsString(
    jsonEncode({...checks, 'phase': phase}),
    flush: true,
  );
  try {
    await application.main([]);
    final binding = WidgetsBinding.instance;
    var frames = 0;
    int? readyFrameNumber;
    final timedFramesAfterReady = <int>{};
    binding.addTimingsCallback((timings) {
      frames += timings.length;
      final ready = readyFrameNumber;
      if (ready != null) {
        timedFramesAfterReady.addAll(
          timings
              .where((timing) => timing.frameNumber > ready)
              .map((timing) => timing.frameNumber),
        );
      }
    });
    await _until(() => _elements().any((e) => e.widget is BusyMarkApp));
    final context = _elements().firstWhere((e) => e.widget is BusyMarkApp);
    final container = ProviderScope.containerOf(context, listen: false);
    final settings = container.read(appSettingsControllerProvider.notifier);
    await settings.waitUntilLoaded();
    await settings.setAutoSave(false);
    await settings.setAutomaticSpelling(false);
    await settings.setConfirmCloseWithUnsavedChanges(true);
    await settings.setReopenPreviousWorkspaceOnStartup(false);
    final window = container.read(windowControlServiceProvider);
    await window.initialize();
    checks['applicationSupport'] =
        (await getApplicationSupportDirectory()).path;

    if (scenario == 'window-controls') {
      final nativeWindow = YaruWindow.of(context);
      YaruWindowState? lastState;
      var notifications = 0;
      final subscription = nativeWindow.states().listen((state) {
        lastState = state;
        notifications++;
      });
      try {
        await _until(() => lastState != null);
        // Exercise the controls actually rendered by LinuxWindowHost.
        Future<void> press(YaruWindowControlType type) async {
          YaruWindowControl? control;
          await _until(() {
            for (final element in _elements()) {
              final widget = element.widget;
              if (widget is YaruWindowControl &&
                  widget.type == type &&
                  widget.onTap != null) {
                control = widget;
                return true;
              }
            }
            return false;
          });
          control!.onTap!();
        }

        await press(YaruWindowControlType.maximize);
        await _until(() => lastState?.isMaximized == true);
        if (!await windowManager.isMaximized()) {
          throw StateError('Maximize notification disagrees with GTK state.');
        }
        await press(YaruWindowControlType.restore);
        await _until(() => lastState?.isMaximized == false);
        await press(YaruWindowControlType.minimize);
        await _until(() => lastState?.isMinimized == true);
        if (!await windowManager.isMinimized()) {
          throw StateError('Minimize notification disagrees with GTK state.');
        }
        await nativeWindow.restore();
        await _until(() => lastState?.isMinimized == false);
        await windowManager.focus();
        await binding.endOfFrame;
        final dragRegion = _elements().firstWhere((element) {
          final box = element.renderObject;
          return element.widget is LinuxTitlebarGestureRegion &&
              box is RenderBox &&
              box.hasSize &&
              box.size.width > 100;
        });
        final box = dragRegion.renderObject! as RenderBox;
        final origin = box.localToGlobal(Offset.zero);
        final ratio = View.of(context).devicePixelRatio;
        checks['windowDragPoint'] = {
          'x': (origin.dx + box.size.width / 2) * ratio,
          'y': (origin.dy + box.size.height / 2) * ratio,
        };
        checks['viewPhysicalSize'] = [
          View.of(context).physicalSize.width,
          View.of(context).physicalSize.height,
        ];
        await publish('awaiting-window-drag');
        await _until(() => File('${report.path}.drag-confirmed').existsSync());
        checks['windowControlsVerified'] = true;
        checks['windowStateNotifications'] = notifications;
      } finally {
        await subscription.cancel();
      }
    }

    final fixture = File('${report.parent.path}/document.md');
    const original = '# Close fixture\n\nOriginal document.\n';
    const edited = '# Close fixture\n\nEdited before normal close.\n';
    String? reopenedText;
    if (scenario.startsWith('dirty-') ||
        scenario == 'visualization' ||
        scenario == 'reopen') {
      final openedFile = scenario == 'reopen' ? File(args[2]) : fixture;
      if (scenario != 'reopen') {
        await fixture.writeAsString(
          scenario == 'visualization'
              ? '# Live diagram\n\n```mermaid\ngraph TD; A-->B\n```\n'
              : original,
          flush: true,
        );
      }
      await container
          .read(workspaceControllerProvider.notifier)
          .openPath(openedFile.path);
      container.read(appRouterProvider).go('/workspace');
      await _until(
        () => _editorPublished(
          openedFile.path,
          container.read(workspaceControllerProvider).activeBuffer?.text ?? '',
        ),
      );
      checks['document'] = openedFile.path;
      if (scenario == 'reopen') {
        reopenedText = await openedFile.readAsString();
      }
    }
    if (scenario == 'visualization') {
      await _until(
        () => _elements().any((e) {
          final widget = e.widget;
          return widget is BusyMarkVisualizationCard &&
              container
                      .read(visualizationCoordinatorProvider)
                      .lastSuccessfulFor(widget.blockKey)
                      ?.isSuccessful ==
                  true;
        }),
      );
      checks['visualizationPublished'] = true;
    }
    if (scenario.startsWith('dirty-')) {
      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveText(edited);
      if (!container.read(workspaceControllerProvider).hasUnsavedChanges) {
        throw StateError('The fixture did not become dirty.');
      }
      checks['expectedText'] = scenario == 'dirty-save' ? edited : original;
      await _until(() => _editorPublished(fixture.path, edited));
    }
    // FrameTiming establishes live build/raster execution, not presentation time.
    final frameAtReady = binding.platformDispatcher.frameData.frameNumber;
    readyFrameNumber = frameAtReady;
    if (frameAtReady < 0) {
      throw StateError('Engine frame numbers are unavailable.');
    }
    final frameDeadline = DateTime.now().add(const Duration(seconds: 40));
    while (timedFramesAfterReady.length < 2) {
      if (DateTime.now().isAfter(frameDeadline)) {
        throw TimeoutException('Post-ready raster frame observations');
      }
      binding.scheduleFrame();
      await binding.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    checks['timedFrames'] = frames;
    checks['readyFrameNumber'] = readyFrameNumber;
    checks['timedFrameNumbersAfterReady'] = timedFramesAfterReady.toList();
    if (reopenedText != null) {
      if (container.read(workspaceControllerProvider).activeBuffer?.text !=
          reopenedText) {
        throw StateError('Reopened document differs from its saved content.');
      }
      checks['reopenedContentVerified'] = true;
    }
    if (scenario == 'pending-initialization') {
      final token = VisualizationCancellationToken();
      var completed = false;
      unawaited(
        const PlatformWebRenderHost()
            .renderMermaid(
              source: 'graph TD; A-->B',
              theme: VisualizationTheme.light,
              cancellationToken: token,
            )
            .then<void>(
              (_) {
                completed = true;
              },
              onError: (Object _) {
                completed = true;
              },
            ),
      );
      checks['renderPendingAtCloseDispatch'] = !completed;
    }
    if (scenario == 'video') {
      if (args.length != 3) {
        throw ArgumentError('Video fixture path required.');
      }
      if (!await const PlatformWritersideVideoPlayerHost().show(
        WritersideVideoPlayerRequest(
          playerId: 'live-close-video',
          source: WritersideVideoPlaybackSource(
            kind: WritersideVideoPlaybackKind.localFile,
            value: args[2],
          ),
          rect: const Rect.fromLTWH(200, 200, 640, 360),
          miniPlayer: false,
          playLabel: 'Play',
          pauseLabel: 'Pause',
          borderEffect: 'none',
        ),
      )) {
        throw StateError('Native video player was rejected.');
      }
      await publish('awaiting-video');
      await _until(() => File('${report.path}.video-confirmed').existsSync());
      checks['decodedChangingVideoObserved'] = true;
    }

    if (scenario.startsWith('dirty-')) {
      checks['editedTextActiveBeforeClose'] =
          container.read(workspaceControllerProvider).activeBuffer?.text ==
          edited;
      if (checks['editedTextActiveBeforeClose'] != true) {
        throw StateError('The edited fixture changed before close.');
      }
    }
    await publish('close-requested');
    // This enters the same prevent-close listener and save/discard/cancel flow
    // as a window-manager delete request. Never call exit() on the success path.
    if (scenario == 'window-controls') {
      final control = _elements()
          .map((element) => element.widget)
          .whereType<YaruWindowControl>()
          .firstWhere((widget) => widget.type == YaruWindowControlType.close);
      if (control.onTap == null) throw StateError('Close control is disabled.');
      control.onTap!();
    } else {
      await windowManager.close();
    }
    if (scenario.startsWith('dirty-')) {
      Future<void> choose(String action) async {
        BusyMarkDialogButton? button;
        await _until(() {
          for (final e in _elements()) {
            final w = e.widget;
            if (w is! BusyMarkDialogButton) continue;
            final labels = AppLocalizations.of(e);
            final label = switch (action) {
              'save' => labels.closeUnsavedChangesSave,
              'discard' => labels.closeUnsavedChangesDiscard,
              _ => labels.closeUnsavedChangesCancel,
            };
            if (w.label == label && w.onPressed != null) {
              button = w;
              return true;
            }
          }
          return false;
        });
        button!.onPressed!();
      }

      if (scenario == 'dirty-cancel') {
        await choose('cancel');
        await binding.endOfFrame;
        if (!await windowManager.isVisible() ||
            !container.read(workspaceControllerProvider).hasUnsavedChanges ||
            container.read(workspaceControllerProvider).activeBuffer?.text !=
                edited ||
            await fixture.readAsString() != original) {
          throw StateError('Cancel closed the window or lost unsaved content.');
        }
        checks['cancelPreservedWindowAndEdits'] = true;
        await publish('close-requested');
        await windowManager.close();
        await choose('discard');
      } else {
        await choose(scenario == 'dirty-save' ? 'save' : 'discard');
      }
    }
  } catch (error, stack) {
    checks['error'] = '$error';
    checks['stack'] = '$stack';
    await publish('failed');
    // The external parent records a failed probe and cleans up its own process.
    // A Dart report or disappearing window can never turn this into success.
    rethrow;
  }
}

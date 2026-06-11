import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux runner owns one native GTK headerbar', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, contains('gtk_header_bar_new()'));
    expect(source, contains('gtk_header_bar_set_show_close_button'));
    expect(source, contains('gtk_window_set_titlebar'));
    expect(source, contains('gtk_popover_menu_new()'));
    expect(source, contains('configure_transparent_window_backing'));
    expect(source, contains('CAIRO_OPERATOR_CLEAR'));
    expect(source, contains('window#busymark-window decoration'));
    expect(source, contains('fl_view_set_background_color'));
    expect(source, contains('"#00000000"'));
    expect(source, contains('kHeaderBarChannel'));
    expect(source, contains('setModalBarrierVisible'));
    expect(source, contains('setSidebarWidth'));
    expect(source, contains('setSidebarToggleVisible'));
    expect(source, contains('setCanSave'));
    expect(source, contains('setDocumentControlsVisible'));
    expect(source, contains('setLocalizedLabels'));
    expect(source, contains('setTheme'));
    expect(source, contains('busymark-sidebar-header'));
    expect(source, contains('self->sidebar_width'));
    expect(
      source,
      contains('connect_header_action(self, self->save_button, "save")'),
    );
    expect(source, isNot(contains('window-close-symbolic')));
    expect(source, isNot(contains('window-minimize-symbolic')));
    expect(source, isNot(contains('window-maximize-symbolic')));
  });

  test('native labels are supplied by Dart rather than hardcoded in C++', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, isNot(contains('"Today"')));
    expect(source, isNot(contains('"Day"')));
    expect(source, isNot(contains('"Week"')));
    expect(source, isNot(contains('"Month"')));
    expect(source, isNot(contains('"Agenda"')));
    expect(source, isNot(contains('"Source"')));
    expect(source, isNot(contains('"Preview"')));
    expect(source, isNot(contains('"Split"')));
    expect(source, isNot(contains('"Settings"')));
    expect(source, isNot(contains('"About BusyMark"')));
  });

  test(
    'Flutter top bars are fallback-only when native headerbar is available',
    () {
      final files = [
        File('lib/src/workspace/presentation/workspace_screen.dart'),
        File('lib/src/workspace/presentation/welcome_screen.dart'),
        File('lib/src/workspace/presentation/settings_screen.dart'),
      ];

      for (final file in files) {
        final source = file.readAsStringSync();
        expect(source, contains('useNativeHeaderBar'));
        expect(source, contains('usesNativeHeaderBar'));
        expect(source, contains('appBar: useNativeHeaderBar'));
        expect(source, contains('linuxHeaderBarServiceProvider'));
        expect(source, contains('headerBarActionsProvider'));
      }
    },
  );

  test('native modal barrier and semantic theme are centralized', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final dialogs = File(
      'lib/src/app/busymark_dialogs.dart',
    ).readAsStringSync();

    expect(service, contains('class HeaderBarTheme'));
    expect(service, contains('BusyMarkSurfaceColors.of(context)'));
    expect(service, contains('setModalBarrierVisible'));
    expect(dialogs, contains('showBusyMarkModalDialog'));
    expect(dialogs, contains('busyMarkModalBarrierColor'));
    expect(dialogs, contains('BusyMarkModalEditorSurface'));
  });

  test('native headerbar uses split sidebar and main content surfaces', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('backgroundColor: colors.headerbarFlat'));
    expect(service, contains('sidebarBackgroundColor: colors.sidebar'));
    expect(service, contains('sidebarBorderColor: colors.sidebarBorder'));
    expect(native, contains('kDefaultHeaderbarBackground[] = "#242424"'));
    expect(native, contains('kDefaultSidebarBackground[] = "#303030"'));
    expect(native, contains('.busymark-sidebar-header {'));
    expect(native, contains('background-color: %s;'));
    expect(native, contains('border-right: 1px solid %s;'));
  });

  test('native headerbar restores the top-left corner without sidebar', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('const gint headerbar_left_radius'));
    expect(native, contains('self->sidebar_visible ? 0 : kHeaderWindowRadius'));
    expect(native, contains('headerbar_left_radius, sidebar_background'));
    expect(native, contains('update_sidebar_header_geometry(self);'));
    expect(native, contains('refresh_header_bar_css(self);'));
    expect(native, isNot(contains('"border-top-left-radius: 0;"')));
  });

  test(
    'surface palette uses neutral grays instead of blue-tinted surfaces',
    () {
      final design = File(
        'lib/src/app/busymark_design.dart',
      ).readAsStringSync();
      final native = File('linux/runner/my_application.cc').readAsStringSync();

      expect(design, contains('sidebarWidth = 300'));
      expect(design, contains('view: Color(0xFF242424)'));
      expect(design, contains('sidebar: Color(0xFF303030)'));
      expect(design, contains('headerbarFlat: Color(0xFF242424)'));
      expect(design, isNot(contains('Color(0xFF1D1D20)')));
      expect(design, isNot(contains('Color(0xFF2E2E32)')));
      expect(design, isNot(contains('Color.fromRGBO(0, 0, 6')));
      expect(native, isNot(contains('"#1D1D20"')));
      expect(native, isNot(contains('"#2E2E32"')));
    },
  );

  test('native document commands are explicit workspace actions', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('save,'));
    expect(service, contains('problems,'));
    expect(service, contains("'save' => HeaderBarAction.save"));
    expect(service, contains("'problems' => HeaderBarAction.problems"));
    expect(service, contains('setCanSave'));
    expect(workspace, contains('case HeaderBarAction.save:'));
    expect(workspace, contains('case HeaderBarAction.problems:'));
    expect(workspace, contains('saveActiveWithOverwriteConfirmation'));
    expect(workspace, contains('_showProblemsDialog(context, ref)'));
    expect(native, contains('create_header_icon_button("emblem-ok-symbolic")'));
    expect(
      native,
      contains('create_header_icon_button("tools-check-spelling-symbolic")'),
    );
    expect(
      native,
      contains('create_header_icon_button("dialog-warning-symbolic")'),
    );
    expect(
      native,
      isNot(contains('create_header_icon_button("view-refresh-symbolic")')),
    );
    expect(
      native,
      contains(
        'connect_header_action(self, self->problems_button, "problems")',
      ),
    );
    expect(native, contains('fl_lookup_string_arg(args, "problems")'));
  });

  test('native document view mode dropdown uses checked rows', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final app = File('lib/src/app/busymark_app.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('enum AppViewMode { source, preview, split }'));
    expect(service, contains('viewModeSource'));
    expect(service, contains('viewModePreview'));
    expect(service, contains('viewModeSplit'));
    expect(app, contains("source: 'Source'"));
    expect(app, contains("preview: 'Preview'"));
    expect(app, contains("split: 'Split'"));
    expect(workspace, contains('case HeaderBarAction.viewModeSource:'));
    expect(workspace, contains('case HeaderBarAction.viewModePreview:'));
    expect(workspace, contains('case HeaderBarAction.viewModeSplit:'));
    expect(workspace, contains('setDocumentViewMode('));
    expect(workspace, contains('setViewMode('));
    expect(
      workspace,
      contains('_headerBarViewMode(settings.documentViewMode)'),
    );
    expect(native, contains('create_view_mode_item(self, "source")'));
    expect(native, contains('create_view_mode_item(self, "preview")'));
    expect(native, contains('create_view_mode_item(self, "split")'));
    expect(native, contains('object-select-symbolic'));
    expect(
      native,
      contains('set_widget_tooltip(self->view_mode_button, view_mode)'),
    );
    expect(
      native,
      contains('set_widget_visible(self->view_mode_box, visible)'),
    );
    expect(native, isNot(contains('viewModeDay')));
    expect(native, isNot(contains('viewModeWeek')));
    expect(native, isNot(contains('viewModeMonth')));
    expect(native, isNot(contains('viewModeAgenda')));
  });

  test('welcome page has no sidebar rail or document controls', () {
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(welcome, isNot(contains('_WelcomeRail')));
    expect(welcome, contains('setSidebarVisible(false)'));
    expect(welcome, contains('setSidebarToggleVisible(false)'));
    expect(welcome, contains('setDocumentControlsVisible(false)'));
    expect(workspace, contains('setSidebarVisible('));
    expect(workspace, contains('settings.sidebarVisible && hasSidebar'));
    expect(workspace, contains('setSidebarToggleVisible(hasSidebar)'));
    expect(workspace, contains('setDocumentControlsVisible(true)'));
    expect(service, contains('setDocumentControlsVisible'));
    expect(service, contains('setSidebarToggleVisible'));
    expect(native, contains('set_document_controls_visible'));
    expect(native, contains('set_sidebar_toggle_visible'));
    expect(
      native,
      contains('set_widget_visible(self->sidebar_toggle_button, visible)'),
    );
    expect(native, contains('set_widget_visible(self->save_button, visible)'));
    expect(
      native,
      contains('set_widget_visible(self->refresh_button, visible)'),
    );
    expect(
      native,
      contains('set_widget_visible(self->problems_button, visible)'),
    );
  });

  test(
    'native main header title is contextual, not duplicate app branding',
    () {
      final welcome = File(
        'lib/src/workspace/presentation/welcome_screen.dart',
      ).readAsStringSync();
      final settings = File(
        'lib/src/workspace/presentation/settings_screen.dart',
      ).readAsStringSync();
      final workspace = File(
        'lib/src/workspace/presentation/workspace_screen.dart',
      ).readAsStringSync();

      expect(welcome, contains("setTitleRange('BusyMark')"));
      expect(settings, contains("setTitleRange('Settings')"));
      expect(workspace, contains('setTitleRange(title)'));
      expect(settings, isNot(contains("setTitleRange('BusyMark Settings')")));
    },
  );
}

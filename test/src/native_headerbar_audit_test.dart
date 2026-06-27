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

  test('Linux desktop identity resolves to BusyMark display name', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();
    final desktop = File(
      'linux/io.busystack.busymark.desktop',
    ).readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(native, contains('g_set_prgname(APPLICATION_ID)'));
    expect(native, contains('g_set_application_name(kApplicationDisplayName)'));
    expect(
      native,
      contains('gtk_window_set_title(window, kApplicationDisplayName)'),
    );
    expect(cmake, contains('set(APPLICATION_ID "io.busystack.busymark")'));
    expect(
      cmake,
      contains(r'"${CMAKE_CURRENT_SOURCE_DIR}/io.busystack.busymark.desktop"'),
    );
    expect(
      cmake,
      contains(
        r'"${CMAKE_CURRENT_SOURCE_DIR}/io.busystack.busymark.metainfo.xml"',
      ),
    );
    expect(desktop, contains('Name=BusyMark'));
    expect(desktop, contains('Exec=busymark %f'));
    expect(desktop, contains('StartupWMClass=io.busystack.busymark'));
    expect(
      snapcraft,
      isNot(
        contains('desktop: share/applications/io.busystack.busymark.desktop'),
      ),
    );
    expect(
      snapcraft,
      contains(r'> "$CRAFT_PRIME/meta/gui/io.busystack.busymark.desktop"'),
    );
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
    expect(source, isNot(contains('"Print"')));
    expect(source, isNot(contains('"Settings"')));
    expect(source, isNot(contains('"Keyboard Shortcuts"')));
    expect(source, isNot(contains('"About BusyMark"')));
  });

  test('native main menu exposes keyboard shortcuts action', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final app = File('lib/src/app/busymark_app.dart').readAsStringSync();
    final dialogs = File(
      'lib/src/app/busymark_dialogs.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('keyboardShortcuts'));
    expect(app, contains('menu: l10n.mainMenu'));
    expect(app, contains('settings: l10n.settings'));
    expect(app, contains('keyboardShortcuts: l10n.keyboardShortcuts'));
    expect(app, contains('aboutBusyMark: l10n.aboutBusyMark'));
    expect(dialogs, contains('showBusyMarkKeyboardShortcutsDialog'));
    expect(dialogs, contains('Ctrl+N'));
    expect(dialogs, contains('Ctrl+S'));
    expect(dialogs, contains('Ctrl+Z'));
    expect(dialogs, contains('Ctrl+Shift+Z'));
    expect(workspace, contains('case HeaderBarAction.keyboardShortcuts:'));
    expect(settings, contains('case HeaderBarAction.keyboardShortcuts:'));
    expect(welcome, contains('case HeaderBarAction.keyboardShortcuts:'));
    expect(
      welcome,
      contains('BusyMarkHeaderPopupMenuButton<_WelcomeMenuAction>'),
    );
    expect(welcome, contains('tooltip: l10n.mainMenu'));
    expect(native, contains('GtkWidget* keyboard_shortcuts_item;'));
    expect(native, contains('GtkWidget* header_menu_button;'));
    expect(native, contains('GtkWidget* header_keyboard_shortcuts_item;'));
    expect(native, contains('fl_lookup_string_arg(args, "keyboardShortcuts")'));
    expect(native, contains('create_menu_item(self, "keyboardShortcuts")'));
    expect(native, contains('close_menu_button(self->header_menu_button)'));
    expect(
      native,
      contains('set_widget_visible(self->header_menu_button, !visible)'),
    );
    expect(
      native,
      contains(
        'gtk_box_pack_start(GTK_BOX(sidebar_menu_box),\n'
        '                     self->keyboard_shortcuts_item',
      ),
    );
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

  test('native GTK prefers dark theme for snap runtime widgets', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('preferDark: Theme.of(context).brightness'));
    expect(service, contains("'preferDark': preferDark"));
    expect(native, contains('static void set_gtk_theme_preference'));
    expect(native, contains('gtk_settings_get_default()'));
    expect(
      native,
      contains('"gtk-application-prefer-dark-theme", prefer_dark'),
    );
    expect(native, contains('set_gtk_theme_preference(TRUE);'));
    expect(native, contains('"gtk-theme-name"'));
    expect(native, contains('"gtk-icon-theme-name"'));
    expect(native, contains('gtk_theme_exists'));
    expect(native, contains('icon_theme_exists'));
    expect(native, contains('gtk_theme_name_for_preference'));
    expect(native, contains('icon_theme_name_for_preference'));
    expect(native, contains('"Yaru-dark"'));
    expect(native, contains('gtk_icon_theme_set_custom_theme'));
    expect(native, contains('fl_lookup_bool_arg(args, "preferDark", TRUE)'));
    expect(
      native,
      matches(
        RegExp(
          r'static void my_application_startup[\s\S]*'
          r'G_APPLICATION_CLASS\(my_application_parent_class\)->startup\(application\);[\s\S]*'
          r'prefer_dark_gtk_theme\(\);',
        ),
      ),
    );
    expect(
      native,
      matches(
        RegExp(
          r'static void my_application_activate\(GApplication\* application\) \{[\s\S]*'
          r'prefer_dark_gtk_theme\(\);[\s\S]*'
          r'gtk_application_window_new',
        ),
      ),
    );
  });

  test('native headerbar tooltips keep GTK theme opacity', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final tooltipBlock = RegExp(
      r'"tooltip, tooltip\.background \{"(.*?)"tooltip > box',
      dotAll: true,
    ).firstMatch(native)!.group(1)!;
    final tooltipLabelBlock = RegExp(
      r'"tooltip label \{"(.*?)"\}',
      dotAll: true,
    ).firstMatch(native)!.group(1)!;

    expect(tooltipBlock, contains('"border-radius: %dpx;"'));
    expect(tooltipBlock, isNot(contains('"background-color: %s;"')));
    expect(tooltipBlock, isNot(contains('"opacity: 1;"')));
    expect(tooltipBlock, isNot(contains('"transition: none;"')));
    expect(tooltipBlock, isNot(contains('"box-shadow: none;"')));
    expect(tooltipLabelBlock, contains('"padding: %dpx %dpx;"'));
    expect(tooltipLabelBlock, isNot(contains('"color: %s;"')));
    expect(tooltipLabelBlock, isNot(contains('"opacity: 1;"')));
  });

  test('native headerbar uses split sidebar and main content surfaces', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(service, contains('backgroundColor: colors.view'));
    expect(service, contains('sidebarBackgroundColor: colors.sidebar'));
    expect(service, isNot(contains('sidebarBorderColor')));
    expect(native, contains('kDefaultHeaderbarBackground[] = "#242424"'));
    expect(native, contains('kDefaultSidebarBackground[] = "#303030"'));
    expect(native, contains('.busymark-sidebar-header {'));
    expect(native, contains('background-color: %s;'));
    final headerbarBlock = RegExp(
      r'"headerbar\.busymark-headerbar,"(.*?)"\}',
      dotAll: true,
    ).firstMatch(native)!.group(1)!;
    expect(headerbarBlock, contains('"background-color: %s;"'));
    expect(headerbarBlock, contains('"background-image: none;"'));
    expect(headerbarBlock, contains('"border: none;"'));
    expect(headerbarBlock, contains('"box-shadow: none;"'));
    expect(headerbarBlock, contains('"border-top-left-radius: %dpx;"'));
    expect(headerbarBlock, contains('"padding-left: 0;"'));
    expect(
      native,
      isNot(
        contains(
          '".busymark-titlebar.busymark-modal-barrier headerbar.busymark-headerbar {"',
        ),
      ),
    );
    expect(native, isNot(contains('border-right: 1px solid')));
    expect(workspace, isNot(contains('Border(right:')));
  });

  test('native headerbar restores the top-left corner without sidebar', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('const gint headerbar_left_radius'));
    expect(native, contains('self->sidebar_visible ? 0 : kHeaderWindowRadius'));
    expect(native, contains('headerbar_left_radius'));
    expect(native, contains('sidebar_background'));
    expect(native, contains('update_sidebar_header_geometry(self);'));
    expect(native, contains('refresh_header_bar_css(self);'));
    expect(native, isNot(contains('"border-top-left-radius: 0;"')));
  });

  test('native GTK decoration owns window shadow and rounded shape', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('window#busymark-window decoration,'));
    expect(native, contains('window#busymark-window decoration:backdrop {'));
    expect(native, contains('kHeaderWindowRadius = 14'));
    expect(native, contains('"background-color: transparent;"'));
    expect(native, contains('"border: none;"'));
    expect(native, contains('"outline: none;"'));
    expect(native, contains('"box-shadow: 0 2px 10px 0 %s;"'));
    expect(native, contains('const gchar* shade = css_color_or'));
    expect(native, contains('fl_lookup_string_arg(args, "shadeColor")'));
    expect(native, contains('create_rounded_window_region'));
    expect(native, contains('gdk_window_shape_combine_region'));
    expect(native, contains('rounded_window_configure_event_cb'));
    expect(native, contains('configure_transparent_window_backing(window);'));
  });

  test('native headerbar buttons use GTK-style themed controls', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final headerButtonBlock = RegExp(
      r'"\.busymark-titlebar button\.busymark-header-button,"(.*?)"\}',
      dotAll: true,
    ).firstMatch(native)!.group(1)!;

    expect(native, contains('kHeaderButtonHeight = 32'));
    expect(native, contains('kHeaderControlHeight = 34'));
    expect(native, contains('kHeaderSearchEntryBorderWidth = 1'));
    expect(
      native,
      contains(
        'kHeaderSearchEntryContentHeight =\n    kHeaderButtonHeight - kHeaderSearchEntryBorderWidth * 2',
      ),
    );
    expect(native, contains('kHeaderButtonHorizontalPadding = 8'));
    expect(native, contains('kHeaderControlHorizontalPadding = 8'));
    expect(native, contains('kHeaderButtonSpacing = 8'));
    expect(headerButtonBlock, contains('"color: %s;"'));
    expect(headerButtonBlock, contains('"min-height: %dpx;"'));
    expect(headerButtonBlock, contains('"min-width: %dpx;"'));
    expect(headerButtonBlock, contains('"padding: 0 %dpx;"'));
    expect(headerButtonBlock, isNot(contains('"background-color: %s;"')));
    expect(headerButtonBlock, isNot(contains('"border: 1px solid %s;"')));
    expect(headerButtonBlock, isNot(contains('"box-shadow:')));
    expect(
      native,
      contains(
        'gtk_widget_set_size_request(self->search_entry, 360, kHeaderButtonHeight)',
      ),
    );
    expect(
      native,
      contains('control, border,\n      kHeaderSearchEntryContentHeight'),
    );
    expect(native, isNot(contains('"box-shadow: 0 0 0 1px %s;"')));
    expect(
      native,
      isNot(contains('"box-shadow: 0 -1px 1px %s, 0 1px 1px %s;"')),
    );
    expect(native, contains('fl_lookup_string_arg(args, "shadeColor")'));
  });

  test('native window controls are not styled by BusyMark CSS', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, isNot(contains('button.titlebutton')));
    expect(native, isNot(contains('const gchar* title_button =')));
    expect(
      native,
      isNot(contains('css_color_or(self->title_button_color, control)')),
    );
    expect(native, isNot(contains('-gtk-gradient')));
  });

  test('native sidebar header buttons do not fake borders or shadows', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('"busymark-sidebar-action-button"'));
    expect(
      native,
      isNot(
        contains(
          '".busymark-sidebar-header button.busymark-sidebar-action-button,"',
        ),
      ),
    );
    expect(
      native,
      isNot(
        contains(
          '".busymark-sidebar-header button.busymark-sidebar-action-button:hover {"',
        ),
      ),
    );
  });

  test(
    'native document controls stay hidden on welcome and settings screens',
    () {
      final native = File('linux/runner/my_application.cc').readAsStringSync();

      expect(native, contains('self->document_controls_visible = visible'));
      expect(native, contains('visible && !self->search_active'));
      expect(native, contains('self->document_controls_visible && !active'));
      expect(native, contains('set_document_controls_visible(self, FALSE)'));
    },
  );

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
      expect(native, contains('"#242424"'));
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
    expect(service, contains("'save' => HeaderBarAction.save"));
    expect(service, isNot(contains('problems,')));
    expect(service, isNot(contains("'problems' => HeaderBarAction.problems")));
    expect(service, contains('setCanSave'));
    expect(workspace, contains('case HeaderBarAction.save:'));
    expect(workspace, isNot(contains('case HeaderBarAction.problems:')));
    expect(workspace, contains('saveActiveWithOverwriteConfirmation'));
    expect(workspace, contains('_showProblemsDialog(context, ref)'));
    expect(workspace, contains('_validateActiveAndShowProblems'));
    expect(workspace, contains('setCanSave(state.isDirty)'));
    expect(workspace, contains('accented: state.isDirty'));
    expect(
      service,
      contains('accentColor: Theme.of(context).colorScheme.primary'),
    );
    expect(service, contains('accentForegroundColor'));
    expect(native, contains('create_header_icon_button("emblem-ok-symbolic")'));
    expect(native, contains('busymark-save-button'));
    expect(native, contains('busymark-save-dirty'));
    expect(native, contains('set_save_dirty(self, fl_method_bool_arg(args))'));
    expect(
      native,
      contains('create_header_icon_button("tools-check-spelling-symbolic")'),
    );
    expect(
      native,
      isNot(contains('create_header_icon_button("dialog-warning-symbolic")')),
    );
    expect(
      native,
      isNot(contains('create_header_icon_button("view-refresh-symbolic")')),
    );
    expect(
      native,
      isNot(
        contains(
          'connect_header_action(self, self->problems_button, "problems")',
        ),
      ),
    );
    expect(native, isNot(contains('fl_lookup_string_arg(args, "problems")')));
  });

  test('native headerbar starts with sidebar toggle before back', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(
      native,
      matches(
        RegExp(
          r'gtk_box_pack_start\(GTK_BOX\(self->header_start_box\), self->sidebar_toggle_button[\s\S]*'
          r'gtk_box_pack_start\(GTK_BOX\(self->header_start_box\), self->back_button',
        ),
      ),
    );
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

    expect(
      service,
      contains('enum AppViewMode { editor, source, preview, split }'),
    );
    expect(service, contains('viewModeEditor'));
    expect(service, contains('viewModeSource'));
    expect(service, contains('viewModePreview'));
    expect(service, contains('viewModeSplit'));
    expect(app, contains('editor: l10n.editor'));
    expect(app, contains('source: l10n.source'));
    expect(app, contains('preview: l10n.preview'));
    expect(app, contains('split: l10n.split'));
    expect(workspace, contains('case HeaderBarAction.viewModeEditor:'));
    expect(workspace, contains('case HeaderBarAction.viewModeSource:'));
    expect(workspace, contains('case HeaderBarAction.viewModePreview:'));
    expect(workspace, contains('case HeaderBarAction.viewModeSplit:'));
    expect(workspace, contains('setDocumentViewMode('));
    expect(workspace, contains('setViewMode('));
    expect(
      workspace,
      contains('_headerBarViewMode(settings.documentViewMode)'),
    );
    expect(native, contains('create_view_mode_item(self, "editor")'));
    expect(native, contains('create_view_mode_item(self, "source")'));
    expect(native, contains('create_view_mode_item(self, "preview")'));
    expect(native, contains('create_view_mode_item(self, "split")'));
    expect(native, contains('object-select-symbolic'));
    final viewModeLabelPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0)',
    );
    final viewModeCheckPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), check, FALSE, FALSE, 0)',
    );
    expect(viewModeLabelPack, isNonNegative);
    expect(viewModeCheckPack, isNonNegative);
    expect(viewModeLabelPack, lessThan(viewModeCheckPack));
    expect(native, contains('button.busymark-menu-row:focus'));
    expect(native, contains('button.busymark-menu-row:active'));
    expect(native, contains('outline-width: 0;'));
    expect(native, contains('self->view_mode_button = gtk_menu_button_new()'));
    expect(
      native,
      contains(
        'gtk_widget_set_size_request(self->view_mode_button, -1,\n'
        '                              kHeaderButtonHeight)',
      ),
    );
    expect(
      native,
      contains(
        'gtk_widget_set_valign(self->view_mode_button, GTK_ALIGN_CENTER)',
      ),
    );
    expect(
      native,
      contains('gtk_label_set_text(GTK_LABEL(self->view_mode_label)'),
    );
    expect(
      native,
      contains(
        'gtk_box_pack_start(GTK_BOX(view_button_box), self->view_mode_label',
      ),
    );
    expect(native, contains('kHeaderButtonContentSpacing = 4'));
    expect(
      native,
      contains(
        'gtk_box_new(GTK_ORIENTATION_HORIZONTAL, kHeaderButtonContentSpacing)',
      ),
    );
    expect(native, isNot(contains('create_menu_button(self->view_mode_menu')));
    expect(
      native,
      contains('set_widget_tooltip(self->view_mode_button, view_mode)'),
    );
    expect(
      native,
      contains('set_widget_visible(self->view_mode_box, effective_visible)'),
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
    expect(welcome, contains('backgroundColor: colors.view'));
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
    expect(
      native,
      contains('set_widget_visible(self->save_button, effective_visible)'),
    );
    expect(
      native,
      contains('set_widget_visible(self->refresh_button, effective_visible)'),
    );
    expect(
      native,
      isNot(contains('set_widget_visible(self->problems_button, visible)')),
    );
  });

  test('no-sidebar pages use themed page surfaces under the headerbar', () {
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();

    expect(welcome, contains('backgroundColor: colors.view'));
    expect(settings, contains('backgroundColor: colors.view'));
    expect(settings, isNot(contains('backgroundColor: colors.window')));
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
      final native = File('linux/runner/my_application.cc').readAsStringSync();

      expect(welcome, contains('setTitleRange(context.l10n.appTitle)'));
      expect(settings, contains('setTitleRange(context.l10n.settings)'));
      expect(workspace, contains('setTitleRange(title)'));
      expect(settings, isNot(contains("setTitleRange('BusyMark Settings')")));
      expect(
        native,
        contains('kHeaderWindowControlsBalanceWidth = kHeaderButtonHeight * 3'),
      );
      expect(native, contains('update_title_stack_alignment(self);'));
      expect(
        native,
        contains('self->search_active ? 0 : kHeaderWindowControlsBalanceWidth'),
      );
    },
  );
}

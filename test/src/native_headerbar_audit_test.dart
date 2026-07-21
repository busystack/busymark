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
    expect(source, contains('setTextDirection'));
    expect(source, contains('setCanSave'));
    expect(source, contains('setDocumentControlsVisible'));
    expect(source, contains('setLocalizedLabels'));
    expect(source, contains('setTheme'));
    expect(source, contains('busymark-sidebar-header'));
    expect(source, contains('self->sidebar_width'));
    expect(source, isNot(contains('self->save_button')));
    expect(
      source,
      isNot(contains('connect_header_action(self, self->save_button, "save")')),
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
    final localSnapBuilder = File(
      'tools/build_install_snap_local.sh',
    ).readAsStringSync();

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
    expect(
      snapcraft,
      contains(
        RegExp(
          r'^plugs:\n'
          r'  desktop:\n'
          r'    interface: desktop\n'
          r'    desktop-file-ids:\n'
          r'      - io\.busystack\.busymark$',
          multiLine: true,
        ),
      ),
    );
    expect(
      localSnapBuilder,
      contains('text = ensure_desktop_file_id(text, desktop_file_id)'),
    );
    expect(localSnapBuilder, contains('desktop_file_id = sys.argv[5]'));
    expect(localSnapBuilder, contains(r'"$APP_ID" <<'));
    expect(
      localSnapBuilder,
      contains(
        'unsquashfs -cat "\$OUT" meta/snap.yaml | grep -A4 '
        "'^  desktop:' | grep -F -- \"- \$APP_ID\"",
      ),
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
    expect(source, isNot(contains('"Markdown and HTML"')));
    expect(source, isNot(contains('"About BusyMark"')));
  });

  test('native main menu exposes shared application actions', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final app = File('lib/src/app/busymark_app.dart').readAsStringSync();
    final dialogs = File(
      'lib/src/app/busymark_dialogs.dart',
    ).readAsStringSync();
    final shortcuts = File(
      'lib/src/app/busymark_shortcuts.dart',
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
    final mainMenu = File(
      'lib/src/app/busymark_main_menu.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('keyboardShortcuts'));
    expect(service, contains('markdownAndHtml'));
    expect(service, contains('reportIssue'));
    expect(app, contains('menu: l10n.mainMenu'));
    expect(app, contains('settings: l10n.settings'));
    expect(app, contains('keyboardShortcuts: l10n.keyboardShortcuts'));
    expect(app, contains('markdownAndHtml: l10n.markdownAndHtml'));
    expect(app, contains('reportIssue: l10n.reportIssue'));
    expect(app, contains('aboutBusyMark: l10n.aboutBusyMark'));
    expect(dialogs, contains('showBusyMarkKeyboardShortcutsDialog'));
    expect(dialogs, contains('showBusyMarkMarkdownHtmlDialog'));
    expect(dialogs, contains('BusyMarkAppShortcutLabels.newDocument'));
    expect(dialogs, contains('BusyMarkAppShortcutLabels.save'));
    expect(dialogs, contains('BusyMarkTextEditingShortcutLabels.undo'));
    expect(dialogs, contains('BusyMarkTextEditingShortcutLabels.redo'));
    expect(shortcuts, contains("newDocumentLabel = 'Ctrl+N'"));
    expect(shortcuts, contains("saveLabel = 'Ctrl+S'"));
    expect(shortcuts, contains("undoLabel = 'Ctrl+Z'"));
    expect(shortcuts, contains("redoLabel = 'Ctrl+Shift+Z'"));
    expect(workspace, contains('case HeaderBarAction.keyboardShortcuts:'));
    expect(workspace, contains('case HeaderBarAction.markdownAndHtml:'));
    expect(workspace, contains('case HeaderBarAction.reportIssue:'));
    expect(settings, contains('case HeaderBarAction.keyboardShortcuts:'));
    expect(settings, contains('case HeaderBarAction.markdownAndHtml:'));
    expect(settings, contains('case HeaderBarAction.reportIssue:'));
    expect(welcome, contains('case HeaderBarAction.keyboardShortcuts:'));
    expect(welcome, contains('case HeaderBarAction.markdownAndHtml:'));
    expect(welcome, contains('case HeaderBarAction.reportIssue:'));
    expect(welcome, contains('BusyMarkMainMenuButton('));
    expect(mainMenu, contains('BusyMarkHeaderPopupMenuButton'));
    expect(mainMenu, contains('tooltip: l10n.mainMenu'));
    expect(mainMenu, contains('label: l10n.reportIssue'));
    expect(native, contains('GtkWidget* sidebar_menu_button;'));
    expect(native, contains('GtkWidget* keyboard_shortcuts_item;'));
    expect(native, contains('GtkWidget* markdown_html_item;'));
    expect(native, contains('GtkWidget* report_issue_item;'));
    expect(native, contains('fl_lookup_string_arg(args, "keyboardShortcuts")'));
    expect(native, contains('fl_lookup_string_arg(args, "markdownAndHtml")'));
    expect(native, contains('fl_lookup_string_arg(args, "reportIssue")'));
    expect(native, contains('create_menu_item(self, "keyboardShortcuts")'));
    expect(native, contains('create_menu_item(self, "markdownAndHtml")'));
    expect(native, contains('create_menu_item(self, "reportIssue")'));
    expect(native, contains('main_menu_icon_name(action)'));
    expect(native, contains('"preferences-system-symbolic"'));
    expect(native, contains('"input-keyboard-symbolic"'));
    expect(native, contains('"text-x-generic-symbolic"'));
    expect(native, contains('"dialog-warning-symbolic"'));
    expect(native, contains('"help-about-symbolic"'));
    final reportIssuePack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(sidebar_menu_box), self->report_issue_item',
    );
    final aboutPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(sidebar_menu_box), self->about_item',
    );
    expect(reportIssuePack, isNonNegative);
    expect(aboutPack, isNonNegative);
    expect(reportIssuePack, lessThan(aboutPack));
    final mainMenuItemOffset = native.indexOf(
      'static GtkWidget* create_menu_item',
    );
    final mainMenuIconPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), icon, FALSE, FALSE, 0)',
      mainMenuItemOffset,
    );
    final mainMenuLabelPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0)',
      mainMenuItemOffset,
    );
    final mainMenuShortcutPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), shortcut, FALSE, FALSE, 0)',
      mainMenuItemOffset,
    );
    expect(mainMenuItemOffset, isNonNegative);
    expect(mainMenuIconPack, isNonNegative);
    expect(mainMenuLabelPack, isNonNegative);
    expect(mainMenuShortcutPack, isNonNegative);
    expect(mainMenuIconPack, lessThan(mainMenuLabelPack));
    expect(mainMenuLabelPack, lessThan(mainMenuShortcutPack));
    expect(native, contains('"busymark-shortcut-widget", shortcut'));
    expect(native, contains('close_menu_button(self->sidebar_menu_button)'));
    expect(native, isNot(contains('GtkWidget* header_menu_button;')));
    expect(native, isNot(contains('GtkWidget* header_menu;')));
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

  test('native GTK theme follows Flutter brightness for snap runtime widgets', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(service, contains('preferDark: Theme.of(context).brightness'));
    expect(service, contains("'preferDark': preferDark"));
    expect(native, contains('static void set_gtk_theme_preference'));
    expect(native, contains('gtk_settings_get_default()'));
    expect(
      native,
      contains('"gtk-application-prefer-dark-theme", prefer_dark'),
    );
    expect(native, contains('"gtk-theme-name"'));
    expect(native, contains('gtk_theme_exists'));
    expect(native, contains('available_gtk_theme_fallback'));
    expect(
      native,
      contains(
        'const gchar* fallback = available_gtk_theme_fallback(prefer_dark);',
      ),
    );
    expect(native, contains('g_strcmp0(theme_name, fallback) != 0'));
    expect(
      native,
      contains('g_object_set(settings, "gtk-theme-name", fallback, nullptr);'),
    );
    expect(native, contains('"Yaru-dark"'));
    expect(native, contains('"Adwaita-dark"'));
    expect(native, contains('"gtk-icon-theme-name"'));
    expect(native, contains('icon_theme_exists'));
    expect(native, contains('available_icon_theme_fallback'));
    expect(
      native,
      contains(
        'const gchar* icon_fallback = available_icon_theme_fallback(prefer_dark);',
      ),
    );
    expect(native, contains('g_strcmp0(icon_theme_name, icon_fallback) != 0'));
    expect(
      native,
      contains(
        'g_object_set(settings, "gtk-icon-theme-name", icon_fallback, nullptr);',
      ),
    );
    expect(native, isNot(contains('gtk_icon_theme_set_custom_theme')));
    expect(native, contains('gtk_accent_css_provider'));
    expect(native, contains('@define-color theme_selected_bg_color %s;'));
    expect(native, contains('@define-color accent_bg_color %s;'));
    expect(native, contains('treeview.view:selected'));
    expect(native, contains('button.suggested-action'));
    expect(native, contains('GTK_STYLE_PROVIDER_PRIORITY_APPLICATION + 1'));
    expect(native, isNot(contains('gtk_theme_name_for_preference')));
    expect(native, isNot(contains('icon_theme_name_for_preference')));
    expect(native, contains('fl_lookup_optional_bool_arg'));
    expect(native, contains('fl_lookup_optional_bool_arg(args, "preferDark"'));
    expect(native, contains('set_gtk_theme_preference(prefer_dark);'));
    expect(native, isNot(contains('prefer_dark_gtk_theme')));
    expect(native, isNot(contains('set_gtk_theme_preference(TRUE)')));
    expect(
      native,
      isNot(contains('fl_lookup_bool_arg(args, "preferDark", TRUE)')),
    );
    expect(snapcraft, contains('yaru-theme-gtk'));
    expect(snapcraft, contains('yaru-theme-icon'));
    expect(snapcraft, contains('override-build:'));
    expect(snapcraft, contains(r'rm -rf "$CRAFT_PART_BUILD/build"'));
    expect(snapcraft, contains(r'rm -rf "$CRAFT_PART_BUILD/.dart_tool"'));
    expect(snapcraft, contains('craftctl default'));
    expect(
      snapcraft,
      contains(
        r'cp -a "$CRAFT_PRIME/usr/share/themes"/Yaru* "$CRAFT_PRIME/share/themes/"',
      ),
    );
    expect(
      snapcraft,
      contains(
        r'cp -a "$CRAFT_PRIME/usr/share/icons"/Yaru* "$CRAFT_PRIME/share/icons/"',
      ),
    );
    expect(
      native,
      isNot(
        matches(
          RegExp(
            r'static void my_application_startup[\s\S]*'
            r'G_APPLICATION_CLASS\(my_application_parent_class\)->startup\(application\);[\s\S]*'
            r'set_gtk_theme_preference',
          ),
        ),
      ),
    );
    expect(
      native,
      isNot(
        matches(
          RegExp(
            r'static void my_application_activate\(GApplication\* application\) \{[\s\S]*'
            r'set_gtk_theme_preference[\s\S]*'
            r'gtk_application_window_new',
          ),
        ),
      ),
    );
  });

  test('local snap builder stages bundled Git tools', () {
    final script = File('tools/build_install_snap_local.sh').readAsStringSync();

    expect(script, contains('stage_bundled_git_tools'));
    expect(script, contains('git --exec-path'));
    expect(script, contains(r'copy_tree_into_snap_root "$git_exec_path"'));
    expect(script, contains('copy_tree_into_snap_root /usr/share/git-core'));
    expect(script, contains('for tool in ssh scp sftp ssh-keyscan'));
    expect(script, contains(r'stage_ldd_dependencies "$git_bin"'));
    expect(script, contains('squashfs-root/usr/bin/git'));
    expect(script, contains('--skip-bundled-git'));
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
    expect(headerbarBlock, contains('"border-top-right-radius: %dpx;"'));
    expect(headerbarBlock, isNot(contains('"padding-left: 0;"')));
    expect(headerbarBlock, isNot(contains('"padding-right: 0;"')));
    expect(
      native,
      contains(
        '".busymark-titlebar.busymark-modal-barrier "'
        '\n      "headerbar.busymark-headerbar,"',
      ),
    );
    expect(native, isNot(contains('border-right: 1px solid')));
    expect(workspace, isNot(contains('Border(right:')));
  });

  test('native headerbar preserves the themed outer window inset', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final ltrPaddingBlock = RegExp(
      r'"headerbar\.busymark-headerbar:dir\(ltr\) \{"(.*?)"\}',
      dotAll: true,
    ).firstMatch(native)?.group(1);
    final rtlPaddingBlock = RegExp(
      r'"headerbar\.busymark-headerbar:dir\(rtl\) \{"(.*?)"\}',
      dotAll: true,
    ).firstMatch(native)?.group(1);

    expect(ltrPaddingBlock, isNotNull);
    expect(ltrPaddingBlock, contains('"padding-left: 0;"'));
    expect(ltrPaddingBlock, isNot(contains('"padding-right: 0;"')));
    expect(rtlPaddingBlock, isNotNull);
    expect(rtlPaddingBlock, contains('"padding-right: 0;"'));
    expect(rtlPaddingBlock, isNot(contains('"padding-left: 0;"')));
  });

  test('native headerbar mirrors sidebar surface for text direction', () {
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final app = File('lib/src/app/busymark_app.dart').readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(service, contains('Future<void> setTextDirection'));
    expect(service, contains("'setTextDirection'"));
    expect(app, contains('Directionality.maybeOf(context)'));
    expect(app, contains('service.setTextDirection(textDirection)'));
    expect(native, contains('gboolean text_direction_rtl;'));
    expect(native, contains('static void update_titlebar_direction'));
    expect(native, contains('update_header_menu_item_direction'));
    expect(native, contains('set_widget_direction(self->sidebar_menu'));
    expect(native, contains('set_widget_direction(self->view_mode_menu'));
    expect(native, contains('direction == GTK_TEXT_DIR_RTL ? 1.0 : 0.0'));
    expect(
      native,
      contains('set_widget_direction(shortcut, GTK_TEXT_DIR_LTR)'),
    );
    expect(native, contains('kLtrIsolateStart'));
    expect(native, contains('kBidiIsolateEnd'));
    expect(native, contains('gtk_box_reorder_child'));
    expect(native, contains('static void set_text_direction'));
    expect(native, contains('strcmp(method, "setTextDirection")'));
    expect(native, contains('g_strcmp0(value, "rtl") == 0'));
    expect(native, contains('headerbar_right_radius'));
    expect(native, contains('sidebar_right_radius'));
  });

  test('native headerbar reapplies logical insets after direction changes', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final marginHelper = RegExp(
      r'static void set_widget_horizontal_margins[\s\S]*?^}',
      multiLine: true,
    ).firstMatch(native)?.group(0);
    final titleAlignment = RegExp(
      r'static void update_title_stack_alignment[\s\S]*?(?=^static void set_toggle_button_active)',
      multiLine: true,
    ).firstMatch(native)?.group(0);
    final directionUpdate = RegExp(
      r'static void update_titlebar_direction[\s\S]*?(?=^static void refresh_header_bar_css)',
      multiLine: true,
    ).firstMatch(native)?.group(0);

    expect(marginHelper, isNotNull);
    expect(marginHelper, contains('gtk_widget_set_margin_start'));
    expect(marginHelper, contains('gtk_widget_set_margin_end'));
    expect(titleAlignment, isNotNull);
    expect(
      titleAlignment,
      matches(
        RegExp(
          r'set_widget_horizontal_margins\(\s*self->title_stack,\s*'
          r'self->search_active \? 0 : kHeaderWindowControlsBalanceWidth,\s*0\);',
        ),
      ),
    );
    expect(directionUpdate, isNotNull);
    expect(
      directionUpdate,
      matches(
        RegExp(
          r'set_widget_horizontal_margins\(\s*self->sidebar_search_button,\s*'
          r'kHeaderSidebarInset,\s*0\);',
        ),
      ),
    );
    expect(
      directionUpdate,
      matches(
        RegExp(
          r'set_widget_horizontal_margins\(\s*self->sidebar_menu_button,\s*'
          r'0,\s*kHeaderSidebarInset\);',
        ),
      ),
    );
    expect(
      directionUpdate,
      matches(
        RegExp(
          r'set_widget_horizontal_margins\(\s*self->header_start_box,\s*'
          r'kHeaderSidebarInset,\s*0\);',
        ),
      ),
    );

    final titleDirectionOffset = directionUpdate!.indexOf(
      'set_widget_direction(self->title_stack, direction)',
    );
    final titleAlignmentOffset = directionUpdate.indexOf(
      'update_title_stack_alignment(self);',
    );
    expect(titleDirectionOffset, isNonNegative);
    expect(titleAlignmentOffset, greaterThan(titleDirectionOffset));

    for (final widget in <String>[
      'sidebar_search_button',
      'sidebar_menu_button',
      'header_start_box',
    ]) {
      final directionOffset = directionUpdate.indexOf(
        'set_widget_direction(self->$widget, direction)',
      );
      final marginOffset = directionUpdate.indexOf(
        'set_widget_horizontal_margins(self->$widget,',
      );
      expect(directionOffset, isNonNegative, reason: widget);
      expect(marginOffset, greaterThan(directionOffset), reason: widget);
    }

    expect(
      native,
      isNot(
        contains('gtk_widget_set_margin_start(self->sidebar_search_button'),
      ),
    );
    expect(
      native,
      isNot(contains('gtk_widget_set_margin_end(self->sidebar_menu_button')),
    );
    expect(
      native,
      isNot(contains('gtk_widget_set_margin_start(self->header_start_box')),
    );
  });

  test('native headerbar restores outer corners without sidebar', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('const gint headerbar_left_radius'));
    expect(native, contains('const gint headerbar_right_radius'));
    expect(native, contains('const gint sidebar_left_radius'));
    expect(native, contains('const gint sidebar_right_radius'));
    expect(
      native,
      contains('self->sidebar_visible && !self->text_direction_rtl'),
    );
    expect(
      native,
      contains('self->sidebar_visible && self->text_direction_rtl'),
    );
    expect(native, contains('headerbar_left_radius'));
    expect(native, contains('headerbar_right_radius'));
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

    expect(native, contains('kHeaderButtonHeight = 32'));
    expect(native, contains('kHeaderControlHeight = 34'));
    expect(native, contains('kHeaderSearchEntryBorderWidth = 1'));
    expect(
      native,
      contains(
        'kHeaderSearchEntryContentHeight =\n    kHeaderButtonHeight - kHeaderSearchEntryBorderWidth * 2',
      ),
    );
    expect(native, contains('kHeaderControlHorizontalPadding = 8'));
    expect(native, contains('kHeaderButtonSpacing = 8'));
    expect(
      native,
      isNot(contains('".busymark-titlebar button.busymark-header-button,"')),
    );
    expect(
      native,
      isNot(
        contains('".busymark-titlebar button.busymark-view-mode-button {"'),
      ),
    );
    expect(
      native,
      isNot(
        contains('".busymark-titlebar button.busymark-header-button image,"'),
      ),
    );
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
    expect(workspace, isNot(contains('saveActiveWithOverwriteConfirmation')));
    expect(workspace, contains('_showProblemsDialog(context, ref)'));
    expect(workspace, contains('_validateActiveAndShowProblems'));
    expect(workspace, isNot(contains('setCanSave(state.isDirty)')));
    expect(workspace, isNot(contains('accented: state.isDirty')));
    expect(
      service,
      contains('accentColor: Theme.of(context).colorScheme.primary'),
    );
    expect(service, contains('accentForegroundColor'));
    expect(
      native,
      isNot(contains('create_header_icon_button("emblem-ok-symbolic")')),
    );
    expect(native, isNot(contains('busymark-save-button')));
    expect(native, isNot(contains('busymark-save-dirty')));
    expect(
      native,
      isNot(contains('set_save_dirty(self, fl_method_bool_arg(args))')),
    );
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
    expect(
      app,
      contains('editorShortcut: BusyMarkDocumentViewShortcutLabels.editor'),
    );
    expect(
      app,
      contains('sourceShortcut: BusyMarkDocumentViewShortcutLabels.source'),
    );
    expect(
      app,
      contains('previewShortcut: BusyMarkDocumentViewShortcutLabels.preview'),
    );
    expect(
      app,
      contains('splitShortcut: BusyMarkDocumentViewShortcutLabels.split'),
    );
    expect(
      app,
      contains('sidebarShortcut: BusyMarkSidebarShortcutLabels.toggleSidebar'),
    );
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
    final viewModeItemOffset = native.indexOf(
      'static GtkWidget* create_view_mode_item',
    );
    final viewModeLabelPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0)',
      viewModeItemOffset,
    );
    final viewModeIconPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), icon, FALSE, FALSE, 0)',
      viewModeItemOffset,
    );
    final viewModeShortcutPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), shortcut, FALSE, FALSE, 0)',
      viewModeItemOffset,
    );
    final viewModeCheckPack = native.indexOf(
      'gtk_box_pack_start(GTK_BOX(box), check, FALSE, FALSE, 0)',
      viewModeItemOffset,
    );
    expect(viewModeItemOffset, isNonNegative);
    expect(viewModeIconPack, isNonNegative);
    expect(viewModeLabelPack, isNonNegative);
    expect(viewModeShortcutPack, isNonNegative);
    expect(viewModeCheckPack, isNonNegative);
    expect(viewModeIconPack, lessThan(viewModeLabelPack));
    expect(viewModeLabelPack, lessThan(viewModeCheckPack));
    expect(viewModeShortcutPack, lessThan(viewModeCheckPack));
    expect(native, contains('view_mode_icon_name(mode)'));
    expect(native, contains('view_mode_icon_name("split")'));
    expect(native, contains('"busymark-shortcut-widget", shortcut'));
    expect(native, contains('set_menu_item_shortcut(item, shortcut)'));
    expect(native, contains('button.busymark-menu-row:focus'));
    expect(native, contains('button.busymark-menu-row:active'));
    expect(native, contains('outline-width: 0;'));
    expect(native, contains('self->view_mode_button = gtk_menu_button_new()'));
    expect(
      native,
      contains(
        'gtk_widget_set_valign(self->view_mode_button, GTK_ALIGN_CENTER)',
      ),
    );
    expect(
      native,
      contains('gtk_image_set_from_icon_name(GTK_IMAGE(self->view_mode_icon)'),
    );
    expect(
      native,
      contains('gtk_container_add(GTK_CONTAINER(self->view_mode_button)'),
    );
    expect(native, contains('make_icon_button_square(self->view_mode_button)'));
    expect(native, isNot(contains('create_menu_button(self->view_mode_menu')));
    expect(native, isNot(contains('self->view_mode_label')));
    expect(
      native,
      contains(
        'set_widget_tooltip_with_shortcut(self->sidebar_toggle_button, sidebar',
      ),
    );
    expect(
      native,
      contains('set_widget_tooltip(self->view_mode_button, view_mode)'),
    );
    expect(
      native,
      contains(
        'set_menu_item_label_with_shortcut(self->view_mode_editor_item, editor',
      ),
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

  test('native popover rows do not open redundant hover tooltips', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final helper = RegExp(
      r'static void set_menu_item_label_with_shortcut\([\s\S]*?\n\}',
    ).firstMatch(native)?.group(0);

    expect(helper, isNotNull);
    expect(helper, contains('set_menu_item_label(item, text);'));
    expect(helper, contains('set_menu_item_shortcut(item, shortcut);'));
    expect(helper, isNot(contains('gtk_widget_set_tooltip_text')));
    expect(native, contains('set_widget_tooltip(self->view_mode_button'));
  });

  test('welcome page has a sidebar but no document controls', () {
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

    expect(welcome, contains('_WelcomeSidebar'));
    expect(welcome, contains('_WelcomeRecentRow'));
    expect(welcome, contains('WorkspaceIdentityRow'));
    expect(welcome, contains('WorkspaceGlyphs.forRecent(recent)'));
    expect(welcome, contains('BusyMarkGlyphs.markdownFile'));
    expect(welcome, contains('BusyMarkGlyphs.folder'));
    expect(welcome, contains('BusyMarkGlyphs.writersideProject'));
    expect(welcome, contains('BorderRadius.circular(BusyMarkRadius.md)'));
    expect(welcome, contains('if (!sidebarOnRight && sidebarVisible)'));
    expect(welcome, contains('if (sidebarOnRight && sidebarVisible)'));
    expect(welcome, contains('setSidebarVisible(sidebarVisible)'));
    expect(welcome, contains('welcomeMainColor = colors.view'));
    expect(welcome, contains('backgroundColor: welcomeMainColor'));
    expect(welcome, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
    expect(welcome, contains('setSidebarToggleVisible(true)'));
    expect(welcome, contains('case HeaderBarAction.sidebarToggle:'));
    expect(welcome, contains('setSidebarVisible(!settings.sidebarVisible)'));
    expect(welcome, contains('setSearchVisible(false)'));
    expect(welcome, contains('setDocumentControlsVisible(false)'));
    expect(workspace, contains('setSidebarVisible('));
    expect(workspace, contains('settings.sidebarVisible && hasSidebar'));
    expect(workspace, contains('setSidebarToggleVisible(hasSidebar)'));
    expect(workspace, contains('setSearchVisible(true)'));
    expect(workspace, contains('setDocumentControlsVisible(true)'));
    expect(service, contains('setDocumentControlsVisible'));
    expect(service, contains('setSidebarToggleVisible'));
    expect(service, contains('setSearchVisible'));
    expect(native, contains('set_document_controls_visible'));
    expect(native, contains('set_sidebar_toggle_visible'));
    expect(native, contains('set_search_visible'));
    expect(
      native,
      contains('set_widget_visible(self->sidebar_toggle_button, visible)'),
    );
    expect(
      native,
      isNot(
        contains('set_widget_visible(self->save_button, effective_visible)'),
      ),
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

  test('settings page uses themed page surface under the headerbar', () {
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();

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
      expect(
        workspace,
        contains('setTitleRange(busyMarkBidiIsolateFor(context, title))'),
      );
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

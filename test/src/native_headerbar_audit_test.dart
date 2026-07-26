import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux runner owns one native GTK headerbar', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, contains('#include <handy.h>'));
    expect(source, contains('hdy_init()'));
    expect(source, contains('hdy_application_window_new()'));
    expect(source, contains('hdy_window_handle_new()'));
    expect(source, contains('gtk_header_bar_new()'));
    expect(source, contains('gtk_header_bar_set_show_close_button'));
    expect(source, isNot(contains('gtk_window_set_titlebar')));
    expect(source, contains('gtk_menu_button_set_menu_model'));
    expect(source, contains('kLegacyYaruWindowShadowCompatibilityCss'));
    expect(source, contains('fl_view_set_background_color'));
    expect(source, contains('"#00000000"'));
    expect(source, contains('kHeaderBarChannel'));
    expect(source, contains('setModalBarrierVisible'));
    expect(source, contains('setSidebarWidth'));
    expect(source, contains('setSidebarToggleVisible'));
    expect(source, contains('setTextDirection'));
    expect(source, contains('setDocumentControlsVisible'));
    expect(source, contains('setLocalizedLabels'));
    expect(source, contains('setTheme'));
    expect(source, contains('applyConfiguration'));
    expect(source, contains('header_configuration_session_id'));
    expect(source, contains('header_configuration_revision'));
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

  test('native header configuration is atomic and latest-wins', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, contains('struct HeaderBarConfiguration'));
    expect(source, contains('decode_header_bar_configuration'));
    expect(source, contains('apply_header_bar_configuration'));
    expect(source, contains('begin_header_configuration_session'));
    expect(source, contains('strcmp(method, "applyConfiguration")'));
    expect(source, contains('fl_lookup_string_arg(args, "sessionId")'));
    expect(source, contains('fl_lookup_int64_arg(args, "revision"'));
    expect(source, contains('active Dart session'));
    expect(source, contains('configuration.revision <='));
    expect(source, contains('self->header_configuration_revision'));
    expect(source, contains('g_object_freeze_notify'));
    expect(source, contains('g_object_thaw_notify'));
    expect(source, contains('self->suppress_header_actions = TRUE'));
    for (final key in <String>[
      'sessionId',
      'title',
      'viewMode',
      'canRefresh',
      'documentControlsVisible',
      'searchActive',
      'searchVisible',
      'searchQuery',
      'sidebarVisible',
      'sidebarToggleVisible',
      'sidebarWidth',
      'textDirection',
      'backVisible',
      'modalBarrierVisible',
      'labels',
      'theme',
    ]) {
      expect(source, contains('"$key"'), reason: key);
    }
  });

  test('Linux desktop identity uses the standard Snap launcher mapping', () {
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
      contains('desktop: share/applications/io.busystack.busymark.desktop'),
    );
    expect(snapcraft, isNot(contains('desktop-file-ids:')));
    expect(
      localSnapBuilder,
      contains(
        r'"$DESKTOP_SOURCE" > "$SNAP_ROOT/meta/gui/${SNAP_NAME}.desktop"',
      ),
    );
    expect(
      localSnapBuilder,
      contains('text = remove_top_level_plug(text, "desktop")'),
    );
    expect(
      localSnapBuilder,
      contains(r'[[ "$STAGED_DESKTOP_MANIFEST" == "${SNAP_NAME}.desktop" ]]'),
    );
    expect(
      localSnapBuilder,
      contains(r'[[ "$PACKED_DESKTOP_MANIFEST" == "${SNAP_NAME}.desktop" ]]'),
    );
    expect(localSnapBuilder, isNot(contains('ensure_desktop_file_id')));
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
    expect(native, contains('GMenu* main_menu_model;'));
    expect(native, contains('GSimpleActionGroup* header_action_group;'));
    expect(native, contains('rebuild_main_menu_model'));
    expect(native, contains('"header.keyboard-shortcuts"'));
    expect(native, contains('"header.markdown-and-html"'));
    expect(native, contains('"header.report-issue"'));
    expect(native, contains('static const gchar* main_menu_icon_name'));
    expect(native, contains('"preferences-system-symbolic"'));
    expect(native, contains('"input-keyboard-symbolic"'));
    expect(native, contains('"text-x-generic-symbolic"'));
    expect(native, contains('"dialog-warning-symbolic"'));
    expect(native, contains('"help-about-symbolic"'));
    final reportIssuePack = native.indexOf(
      'localized_label_or(labels, "reportIssue", "")',
    );
    final aboutPack = native.indexOf(
      'localized_label_or(labels, "aboutBusyMark", "")',
    );
    expect(reportIssuePack, isNonNegative);
    expect(aboutPack, isNonNegative);
    expect(reportIssuePack, lessThan(aboutPack));
    expect(native, contains('g_menu_item_set_icon(item, icon)'));
    expect(native, contains('g_menu_item_set_attribute(item, "accel"'));
    expect(native, contains('g_action_map_add_action'));
    expect(native, contains('gtk_widget_insert_action_group'));
    expect(native, isNot(contains('static GtkWidget* create_menu_item')));
    expect(native, isNot(contains('"busymark-menu-row"')));
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
    final configuration = File(
      'lib/src/platform/header_bar_configuration.dart',
    ).readAsStringSync();
    final service = File(
      'lib/src/platform/linux_header_bar_service.dart',
    ).readAsStringSync();
    final dialogs = File(
      'lib/src/app/busymark_dialogs.dart',
    ).readAsStringSync();

    expect(configuration, contains('class HeaderBarTheme'));
    expect(configuration, contains('HeaderBarTheme.fromContext'));
    expect(configuration, contains('BusyMarkSurfaceColors.of(context)'));
    expect(
      configuration,
      contains('modalBarrierVisible: _modalBarrierVisible'),
    );
    expect(configuration, contains('setModalBarrierVisible(bool visible)'));
    expect(service, contains('setModalBarrierVisible'));
    expect(
      service,
      contains('configurationSynchronizer.setModalBarrierVisible(value)'),
    );
    expect(dialogs, contains('showBusyMarkModalDialog'));
    expect(dialogs, contains('busyMarkModalBarrierColor'));
    expect(dialogs, contains('BusyMarkModalEditorSurface'));
  });

  test('native GTK theme follows brightness without replacing a valid user theme', () {
    final configuration = File(
      'lib/src/platform/header_bar_configuration.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(configuration, contains('preferDark: Theme.of(context).brightness'));
    expect(configuration, contains("'preferDark': preferDark"));
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
    expect(
      native,
      contains('fallback != nullptr && !gtk_theme_exists(theme_name)'),
    );
    expect(native, isNot(contains('g_strcmp0(theme_name, fallback) != 0')));
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
    expect(
      native,
      contains(
        'icon_fallback != nullptr && !icon_theme_exists(icon_theme_name)',
      ),
    );
    expect(
      native,
      isNot(contains('g_strcmp0(icon_theme_name, icon_fallback) != 0')),
    );
    expect(
      native,
      contains(
        'g_object_set(settings, "gtk-icon-theme-name", icon_fallback, nullptr);',
      ),
    );
    expect(native, isNot(contains('gtk_icon_theme_set_custom_theme')));
    expect(native, isNot(contains('gtk_accent_css_provider')));
    expect(native, isNot(contains('@define-color theme_selected_bg_color')));
    expect(native, isNot(contains('@define-color accent_bg_color')));
    expect(native, isNot(contains('treeview.view:selected')));
    expect(native, isNot(contains('button.suggested-action')));
    expect(
      native,
      isNot(contains('GTK_STYLE_PROVIDER_PRIORITY_APPLICATION + 1')),
    );
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
    expect(script, contains(r'setsid_bin="$(command -v setsid || true)"'));
    expect(
      script,
      contains(
        'setsid from util-linux is required to run bundled Git commands',
      ),
    );
    expect(
      script,
      contains(r'install -Dm755 "$setsid_bin" "$SNAP_ROOT/usr/bin/setsid"'),
    );
    expect(script, contains(r'stage_ldd_dependencies "$setsid_bin"'));
    expect(script, contains(r'test -x "$SNAP_ROOT/usr/bin/setsid"'));
    expect(script, contains('squashfs-root/usr/bin/git'));
    expect(script, contains('squashfs-root/usr/bin/setsid'));
    expect(script, contains('--skip-bundled-git'));
  });

  test('native headerbar delegates tooltip appearance to GTK', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('gtk_widget_set_tooltip_text'));
    expect(native, isNot(contains('"tooltip, tooltip.background {"')));
    expect(native, isNot(contains('"tooltip > box')));
    expect(native, isNot(contains('"tooltip label {"')));
  });

  test('native header CSS is balanced and narrowly semantic', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final refreshFunction = RegExp(
      r'static void refresh_header_bar_css[\s\S]*?'
      r'(?=static void set_header_bar_theme)',
    ).firstMatch(native)?.group(0);
    expect(refreshFunction, isNotNull);

    final formatArguments = RegExp(
      r'g_strdup_printf\(([\s\S]*?)\);\s*'
      r'g_autoptr\(GError\)',
    ).firstMatch(refreshFunction!)?.group(1);
    expect(formatArguments, isNotNull);

    final css = RegExp(
      r'"((?:\\.|[^"\\])*)"',
    ).allMatches(formatArguments!).map((match) => match.group(1)!).join();
    var braceDepth = 0;
    for (final codeUnit in css.codeUnits) {
      if (codeUnit == 0x7B) {
        braceDepth++;
      } else if (codeUnit == 0x7D) {
        braceDepth--;
        expect(
          braceDepth,
          isNonNegative,
          reason: 'premature CSS closing brace',
        );
      }
    }
    expect(braceDepth, 0, reason: 'unbalanced structural CSS blocks');
    expect(css, contains('.busymark-titlebar.busymark-modal-barrier'));
    expect(css, contains('.busymark-header-control'));
    expect(css, contains('background-color: alpha(currentColor, 0.07)'));
    expect(css, contains('background-color: alpha(currentColor, 0.16)'));
    expect(css, contains('background-color: alpha(currentColor, 0.10)'));
    expect(css, isNot(contains('popover.background')));
    for (final interactionSelector in <String>[
      'button.',
      'modelbutton',
      'tooltip',
      ':focus',
      '@define-color',
    ]) {
      expect(css, isNot(contains(interactionSelector)));
    }
  });

  test('native headerbar uses split sidebar and main content surfaces', () {
    final configuration = File(
      'lib/src/platform/header_bar_configuration.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(configuration, contains('backgroundColor: colors.view'));
    expect(configuration, contains('sidebarBackgroundColor: colors.sidebar'));
    expect(configuration, contains('foregroundColor: colors.foreground'));
    expect(configuration, isNot(contains('borderColor')));
    expect(configuration, isNot(contains('popoverBackgroundColor')));
    expect(configuration, isNot(contains('floatingBorderColor')));
    expect(native, contains('kDefaultHeaderbarBackground[] = "#272727"'));
    expect(native, contains('kDefaultSidebarBackground[] = "#393939"'));
    expect(native, contains('kDefaultSidebarBorder[] = "rgba(16,16,16,0.35)"'));
    expect(
      native,
      contains('fl_lookup_string_arg(args, "sidebarBorderColor")'),
    );
    expect(native, isNot(contains('"floatingBorderColor"')));
    expect(native, isNot(contains('"popoverBackgroundColor"')));
    expect(
      native,
      contains(
        'css_color_or(self->sidebar_border_color, kDefaultSidebarBorder)',
      ),
    );
    expect(native, isNot(contains('busymark-header-popover')));
    expect(
      native,
      contains('gtk_popover_set_position(popover, GTK_POS_BOTTOM)'),
    );
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
    expect(headerbarBlock, isNot(contains('border-radius')));
    expect(headerbarBlock, isNot(contains('"padding-left: 0;"')));
    expect(headerbarBlock, isNot(contains('"padding-right: 0;"')));
    expect(
      native,
      contains(
        '".busymark-titlebar.busymark-modal-barrier "'
        '\n      "headerbar.busymark-headerbar,"',
      ),
    );
    expect(native, contains('".busymark-sidebar-header:dir(ltr) {"'));
    expect(native, contains('"border-right: 1px solid %s;"'));
    expect(native, contains('".busymark-sidebar-header:dir(rtl) {"'));
    expect(native, contains('"border-left: 1px solid %s;"'));
    expect(native, contains('modal_sidebar_border_css_color'));
    expect(
      native,
      contains(
        '".busymark-titlebar.busymark-modal-barrier "'
        '\n      ".busymark-sidebar-header:dir(ltr) {"',
      ),
    );
    expect(native, contains('"border-right-color: %s;"'));
    expect(native, contains('"border-left-color: %s;"'));
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
    final configuration = File(
      'lib/src/platform/header_bar_configuration.dart',
    ).readAsStringSync();
    final app = File('lib/src/app/busymark_app.dart').readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(configuration, contains('final TextDirection textDirection;'));
    expect(
      configuration,
      contains(
        "'textDirection': textDirection == TextDirection.rtl ? 'rtl' : 'ltr'",
      ),
    );
    expect(app, contains('Directionality.maybeOf(context)'));
    expect(app, contains('textDirection: textDirection'));
    for (final screen in [settings, welcome, workspace]) {
      expect(screen, contains('HeaderBarConfigurationDefaults.of(context)'));
      expect(screen, contains('HeaderBarConfigurationPublisher('));
    }
    expect(native, contains('gboolean text_direction_rtl;'));
    expect(native, contains('static void update_titlebar_direction'));
    expect(native, contains('set_widget_direction(self->sidebar_menu'));
    expect(native, contains('set_widget_direction(self->view_mode_menu'));
    expect(native, contains('set_widget_direction(self->adaptive_menu'));
    expect(
      native,
      contains('set_widget_direction(self->adaptive_search_button'),
    );
    expect(native, contains('kLtrIsolateStart'));
    expect(native, contains('kBidiIsolateEnd'));
    expect(native, contains('gtk_box_reorder_child'));
    expect(native, contains('static void set_text_direction'));
    expect(
      native,
      contains('set_text_direction(self, configuration.text_direction)'),
    );
    expect(native, contains('g_strcmp0(value, "rtl") == 0'));
  });

  test('native headerbar reapplies owned insets after direction changes', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final marginHelper = RegExp(
      r'static void set_widget_horizontal_margins[\s\S]*?^}',
      multiLine: true,
    ).firstMatch(native)?.group(0);
    final directionUpdate = RegExp(
      r'static void update_titlebar_direction[\s\S]*?(?=^static void refresh_header_bar_css)',
      multiLine: true,
    ).firstMatch(native)?.group(0);

    expect(marginHelper, isNotNull);
    expect(marginHelper, contains('gtk_widget_set_margin_start'));
    expect(marginHelper, contains('gtk_widget_set_margin_end'));
    expect(native, isNot(contains('kHeaderWindowControlsBalanceWidth')));
    expect(native, isNot(contains('update_title_stack_alignment')));
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

    for (final widget in <String>[
      'sidebar_search_button',
      'sidebar_menu_button',
      'header_start_box',
    ]) {
      final directionOffset = directionUpdate!.indexOf(
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

  test(
    'sidebar visibility updates split geometry without corner emulation',
    () {
      final native = File('linux/runner/my_application.cc').readAsStringSync();

      expect(native, contains('sidebar_background'));
      expect(native, contains('update_sidebar_header_geometry(self);'));
      expect(native, contains('refresh_header_bar_css(self);'));
      expect(native, isNot(contains('headerbar_left_radius')));
      expect(native, isNot(contains('headerbar_right_radius')));
      expect(native, isNot(contains('sidebar_left_radius')));
      expect(native, isNot(contains('sidebar_right_radius')));
      expect(native, isNot(contains('"border-top-left-radius:')));
      expect(native, isNot(contains('"border-top-right-radius:')));
    },
  );

  test(
    'Handy owns window shape while Yaru receives a scoped frame adapter',
    () {
      final native = File('linux/runner/my_application.cc').readAsStringSync();
      final linuxCmake = File('linux/CMakeLists.txt').readAsStringSync();
      final runnerCmake = File(
        'linux/runner/CMakeLists.txt',
      ).readAsStringSync();
      final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
      final readme = File('README.md').readAsStringSync();
      final compatibilityCss = RegExp(
        r'constexpr char kLegacyYaruWindowShadowCompatibilityCss\[\][\s\S]*?'
        r'constexpr char kLtrIsolateStart',
      ).firstMatch(native)!.group(0)!;

      expect(native, contains('#include <handy.h>'));
      expect(native, contains('hdy_application_window_new()'));
      expect(native, contains('hdy_window_handle_new()'));
      expect(native, contains('GtkWidget* titlebar_handle;'));
      expect(
        native,
        contains('gtk_widget_set_sensitive(self->titlebar_handle, !visible)'),
      );
      expect(native, contains('uses_legacy_yaru_window_shadow()'));
      expect(native, contains('g_strcmp0(normalized_theme, "yaru")'));
      expect(native, contains('g_str_has_prefix(normalized_theme, "yaru-")'));
      expect(native, contains('strstr(normalized_theme, "highcontrast")'));
      expect(native, contains('"notify::gtk-theme-name"'));
      expect(native, contains('G_CALLBACK(gtk_theme_name_changed_cb)'));
      expect(native, contains('g_signal_connect_object('));
      expect(native, isNot(contains('gtk_window_set_titlebar(')));
      expect(native, isNot(contains('gtk_application_window_new(')));
      expect(
        compatibilityCss,
        contains('box-shadow: 0 3px 9px 1px rgba(0,0,0,0.5)'),
      );
      expect(
        compatibilityCss,
        contains(
          '0 3px 9px 1px transparent,'
          '"\n    "0 2px 6px 2px rgba(0,0,0,0.2)',
        ),
      );
      expect(compatibilityCss, contains(':not(.solid-csd)'));
      expect(compatibilityCss, contains(':not(.maximized)'));
      expect(compatibilityCss, contains('not(.fullscreen)'));
      expect(
        RegExp(r'not\(\.maximized\)').allMatches(compatibilityCss),
        hasLength(7),
      );
      expect(
        RegExp(r'not\(\.fullscreen\)').allMatches(compatibilityCss),
        hasLength(7),
      );
      expect(compatibilityCss, contains('0 0 0 20px transparent'));
      expect(compatibilityCss, isNot(contains('0 0 0 1px')));
      expect(compatibilityCss, isNot(contains('border-radius')));
      expect(compatibilityCss, isNot(contains('border-color')));
      expect(native, isNot(contains('"window#busymark-window decoration,"')));
      expect(
        linuxCmake,
        contains(
          'pkg_check_modules(HANDY REQUIRED IMPORTED_TARGET libhandy-1)',
        ),
      );
      expect(
        runnerCmake,
        contains(
          r'target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::HANDY)',
        ),
      );
      expect(snapcraft, contains('- libhandy-1-dev'));
      expect(snapcraft, contains('- libhandy-1-0'));
      expect(readme, contains('sudo apt-get install libhandy-1-dev'));
      expect(native, isNot(contains('kHeaderWindowRadius')));
      expect(native, isNot(contains('create_rounded_window_region')));
      expect(native, isNot(contains('gdk_window_shape_combine_region')));
      expect(native, isNot(contains('rounded_window_configure_event_cb')));
      expect(native, isNot(contains('configure_transparent_window_backing')));
      expect(native, isNot(contains('gtk_widget_set_app_paintable')));
      expect(native, isNot(contains('CAIRO_OPERATOR_CLEAR')));
      expect(native, isNot(contains('#include <cairo.h>')));
      expect(native, isNot(contains('"border-radius:')));
    },
  );

  test('native header controls preserve GTK geometry with neutral states', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('kHeaderButtonHeight = 32'));
    expect(native, contains('kHeaderButtonSpacing = 8'));
    expect(native, contains('self->search_entry = gtk_search_entry_new()'));
    expect(
      native,
      contains('gtk_widget_set_hexpand(self->search_entry, TRUE)'),
    );
    expect(
      native,
      isNot(contains('gtk_widget_set_size_request(self->search_entry')),
    );
    expect(
      native,
      isNot(
        contains('".busymark-titlebar entry.busymark-search-entry:focus {"'),
      ),
    );
    expect(native, isNot(contains('button.busymark-header-button:hover')));
    expect(native, isNot(contains('button.busymark-header-button:checked')));
    expect(native, isNot(contains('button.busymark-header-button:focus')));
    expect(native, isNot(contains('GTK_RELIEF_NONE')));
    expect(native, isNot(contains('GTK_STYLE_CLASS_FLAT')));
    expect(native, contains('"busymark-header-control"'));
    expect(native, isNot(contains('"busymark-header-icon-button"')));
    expect(native, contains('alpha(currentColor, 0.07)'));
    expect(native, contains('alpha(currentColor, 0.16)'));
    expect(native, contains('alpha(currentColor, 0.10)'));
    expect(native, contains('alpha(currentColor, 0.13)'));
    expect(native, contains('alpha(currentColor, 0.19)'));
    expect(native, isNot(contains('"outline-width: 2px;"')));
    expect(native, isNot(contains('"outline-width: 0;"')));
    expect(native, contains('"searchSubmitted"'));
    expect(
      native,
      contains('invoke_header_bar_string_action(self, "searchSubmitted"'),
    );
    expect(native, contains('gtk_widget_set_focus_on_click(button, FALSE)'));
    expect(native, contains('"stop-search"'));
    expect(native, contains('"searchFocusChanged"'));
    expect(native, contains('"searchCleared"'));
    expect(native, contains('"searchEscapePressed"'));
    expect(native, contains('strcmp(method, "focusSearch") == 0'));
    expect(native, contains('enum class SearchQueryUpdateDisposition'));
    expect(native, contains('resolve_search_query_update(false, true)'));
    expect(
      native,
      contains('SearchQueryUpdateDisposition::kPreserveNativeText'),
    );
    expect(
      native,
      contains(
        'A newer focused native edit must survive a delayed Dart snapshot',
      ),
    );
    expect(native, contains('native_entry_has_authority'));
    expect(native, isNot(contains('echoes_last_native_query')));
    expect(native, isNot(contains('"key-press-event"')));
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

  test('search and main menu adapt when the sidebar header is hidden', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('GtkWidget* adaptive_search_button;'));
    expect(native, contains('GtkWidget* adaptive_menu_button;'));
    expect(native, contains('static void update_adaptive_header_actions'));
    expect(
      native,
      contains('const gboolean use_main_header = !self->sidebar_visible'),
    );
    expect(native, contains('use_main_header && self->search_visible'));
    expect(native, contains('set_widget_visible(self->adaptive_menu_button'));
    expect(
      native,
      contains(
        'set_toggle_button_active(self, self->adaptive_search_button, active)',
      ),
    );
    expect(
      native,
      contains('G_MENU_MODEL(self->main_menu_model), "open-menu-symbolic"'),
    );
  });

  test(
    'native fallback surfaces are neutral grays, not blue-tinted colors',
    () {
      final native = File('linux/runner/my_application.cc').readAsStringSync();

      int fallbackValue(String constantName) {
        final match = RegExp(
          'constexpr char $constantName\\[\\] = "#([0-9A-Fa-f]{6})";',
        ).firstMatch(native);
        expect(match, isNotNull, reason: constantName);
        return int.parse(match!.group(1)!, radix: 16);
      }

      void expectNeutral(String constantName, int value) {
        final red = (value >> 16) & 0xFF;
        final green = (value >> 8) & 0xFF;
        final blue = value & 0xFF;
        expect(red, green, reason: constantName);
        expect(green, blue, reason: constantName);
      }

      final header = fallbackValue('kDefaultHeaderbarBackground');
      final sidebar = fallbackValue('kDefaultSidebarBackground');
      expectNeutral('kDefaultHeaderbarBackground', header);
      expectNeutral('kDefaultSidebarBackground', sidebar);
      expect(sidebar, greaterThan(header));
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
    expect(workspace, contains('case HeaderBarAction.save:'));
    expect(workspace, isNot(contains('case HeaderBarAction.problems:')));
    expect(workspace, isNot(contains('saveActiveWithOverwriteConfirmation')));
    expect(workspace, contains('_showProblemsDialog(context, ref)'));
    expect(workspace, contains('_validateActiveAndShowProblems'));
    expect(workspace, contains('HeaderBarConfigurationPublisher('));
    expect(workspace, isNot(contains('headerBar.setCanSave')));
    expect(workspace, isNot(contains('accented: state.isDirty')));
    expect(native, isNot(contains('gboolean can_save;')));
    expect(native, isNot(contains('gboolean can_undo;')));
    expect(native, isNot(contains('gboolean can_redo;')));
    expect(native, isNot(contains('strcmp(method, "setCanSave")')));
    expect(native, isNot(contains('strcmp(method, "setCanUndo")')));
    expect(native, isNot(contains('strcmp(method, "setCanRedo")')));
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
    final configuration = File(
      'lib/src/platform/header_bar_configuration.dart',
    ).readAsStringSync();
    final app = File('lib/src/app/busymark_app.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(
      configuration,
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
    expect(workspace, contains('HeaderBarConfigurationPublisher('));
    expect(
      workspace,
      contains('viewMode: _headerBarViewMode(settings.documentViewMode)'),
    );
    expect(workspace, isNot(contains('headerBar.setViewMode')));
    expect(service, contains("('setViewMode', configuration.viewMode.name)"));
    expect(native, contains('GMenu* view_mode_menu_model;'));
    expect(native, contains('GSimpleAction* view_mode_action;'));
    expect(native, contains('g_simple_action_new_stateful('));
    expect(native, contains('"view-mode", G_VARIANT_TYPE_STRING'));
    expect(native, contains('g_menu_item_set_action_and_target('));
    expect(native, contains('"header.view-mode"'));
    expect(native, contains('g_simple_action_set_state('));
    expect(native, contains('append_view_mode_menu_item('));
    for (final mode in <String>['editor', 'source', 'preview', 'split']) {
      expect(
        native,
        contains('localized_label_or(labels, "$mode", "")'),
        reason: mode,
      );
    }
    expect(native, contains('view_mode_icon_name(mode)'));
    expect(native, contains('view_mode_icon_name("split")'));
    expect(native, isNot(contains('modelbutton:hover')));
    expect(native, isNot(contains('modelbutton:focus')));
    expect(native, isNot(contains('modelbutton:active')));
    expect(native, isNot(contains('outline-width: 0;')));
    expect(native, contains('static GtkWidget* create_model_menu_button'));
    expect(native, contains('gtk_menu_button_set_menu_model'));
    expect(
      native,
      contains('gtk_image_set_from_icon_name(GTK_IMAGE(self->view_mode_icon)'),
    );
    expect(
      native,
      contains('gtk_button_get_image(GTK_BUTTON(self->view_mode_button))'),
    );
    expect(native, isNot(contains('create_view_mode_item')));
    expect(native, isNot(contains('set_menu_item_checked')));
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
    expect(native, contains('rebuild_view_mode_menu_model(self, args)'));
    expect(
      native,
      contains('set_widget_visible(self->view_mode_box, effective_visible)'),
    );
    expect(native, isNot(contains('viewModeDay')));
    expect(native, isNot(contains('viewModeWeek')));
    expect(native, isNot(contains('viewModeMonth')));
    expect(native, isNot(contains('viewModeAgenda')));
  });

  test('native popovers use menu-model accelerators without fake rows', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    expect(native, contains('g_menu_item_set_attribute(item, "accel"'));
    expect(native, contains('g_menu_item_set_icon(item, icon)'));
    expect(native, contains('gtk_menu_button_set_menu_model'));
    expect(native, isNot(contains('busymark-shortcut-widget')));
    expect(native, isNot(contains('busymark-menu-row')));
    expect(native, contains('set_widget_tooltip(self->view_mode_button'));
  });

  test('welcome page has a sidebar but no document controls', () {
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final configuration = File(
      'lib/src/platform/header_bar_configuration.dart',
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
    expect(welcome, contains('welcomeMainColor = colors.view'));
    expect(welcome, contains('backgroundColor: welcomeMainColor'));
    expect(welcome, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
    expect(welcome, contains('HeaderBarConfigurationPublisher('));
    expect(welcome, contains('documentControlsVisible: false'));
    expect(welcome, contains('searchVisible: false'));
    expect(welcome, contains('sidebarVisible: sidebarVisible'));
    expect(welcome, contains('sidebarToggleVisible: true'));
    expect(welcome, contains('case HeaderBarAction.sidebarToggle:'));
    expect(welcome, contains('setSidebarVisible(!settings.sidebarVisible)'));
    expect(workspace, contains('HeaderBarConfigurationPublisher('));
    expect(workspace, contains('sidebarVisible: sidebarVisible'));
    expect(workspace, contains('sidebarToggleVisible: hasSidebar'));
    expect(workspace, contains('searchVisible: true'));
    expect(workspace, contains('documentControlsVisible: true'));
    expect(configuration, contains('final bool documentControlsVisible;'));
    expect(configuration, contains('final bool sidebarToggleVisible;'));
    expect(configuration, contains('final bool searchVisible;'));
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

      expect(welcome, contains('HeaderBarConfigurationPublisher('));
      expect(welcome, contains('title: context.l10n.appTitle'));
      expect(settings, contains('HeaderBarConfigurationPublisher('));
      expect(settings, contains('title: l10n.settings'));
      expect(
        workspace,
        contains('title: busyMarkBidiIsolateFor(context, title)'),
      );
      expect(settings, isNot(contains("setTitleRange('BusyMark Settings')")));
      expect(
        native,
        contains('gtk_header_bar_set_custom_title(self->header_bar'),
      );
      expect(native, isNot(contains('kHeaderWindowControlsBalanceWidth')));
      expect(native, isNot(contains('update_title_stack_alignment')));
    },
  );
}

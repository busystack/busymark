import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Flutter owns application chrome; native bridge carries no split geometry',
    () {
      final native = File('linux/runner/my_application.cc').readAsStringSync();
      final chrome = File(
        'linux/runner/linux_chrome_host.cc',
      ).readAsStringSync();
      expect(native, isNot(contains('hdy_header_bar_new')));
      expect(native, isNot(contains('gtk_header_bar_new')));
      expect(native, isNot(contains('create_header_bar')));
      expect(native, isNot(contains('busymark/headerbar')));
      expect(chrome, isNot(contains('sidebarWidth')));
      expect(chrome, isNot(contains('sidebarVisible')));
      expect(native, contains('busymark_linux_chrome_host_new'));
      expect(chrome, contains('getGtkWindowPreferences'));
      expect(chrome, contains('getGtkAnimationsEnabled'));
      expect(chrome, contains('loadIcons'));
    },
  );

  test('Workspace, Welcome and Settings use the shared full-height frame', () {
    for (final page in [
      'workspace_screen',
      'welcome_screen',
      'settings_screen',
    ]) {
      final source = File(
        'lib/src/workspace/presentation/$page.dart',
      ).readAsStringSync();
      expect(source, contains('LinuxPageFrame('), reason: page);
      expect(source, contains('sidebarBody:'), reason: page);
      expect(source, isNot(contains('useNativeHeaderBar')), reason: page);
      expect(source, isNot(contains('showEndBorder: true')), reason: page);
    }
  });

  test(
    'native clipboard, menus, Writerside media and rendering hosts remain registered',
    () {
      final native = File('linux/runner/my_application.cc').readAsStringSync();
      for (final registration in [
        'busymark_rich_clipboard_channel_new',
        'busymark_writerside_dialog_channel_new',
        'busymark_video_player_host_register_channel',
        'busymark_web_render_host_register_channel',
      ]) {
        expect(native, contains(registration));
      }
      expect(native, contains('gtk_menu_popup_at_rect('));
    },
  );
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

  test('strict Snap keeps the GTK SVG loader ABI-aligned with GNOME', () {
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
    final localSnapBuilder = File(
      'tools/build_install_snap_local.sh',
    ).readAsStringSync();
    final workflow = File(
      '.github/workflows/flutter-linux.yml',
    ).readAsStringSync();

    expect(
      snapcraft,
      contains(
        r'rm -f "$CRAFT_PRIME/usr/lib/x86_64-linux-gnu/librsvg-2.so.2"*',
      ),
    );
    expect(
      localSnapBuilder,
      contains(r'rm -f "$SNAP_ROOT/usr/lib/x86_64-linux-gnu/librsvg-2.so.2"*'),
    );
    expect(
      localSnapBuilder,
      contains('squashfs-root/usr/lib/x86_64-linux-gnu/librsvg-2.so.2'),
    );
    expect(workflow, contains('Verify GTK SVG icon loader'));
    expect(workflow, contains('libpixbufloader_svg.so'));
    expect(
      workflow,
      contains(r'$SNAP/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/librsvg-2.so.2'),
    );
    expect(workflow, contains(r'\"svg\" 6 \"gdk-pixbuf\"'));
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
    expect(script, contains(r'unsquashfs -ll "$OUT" usr/bin/git'));
    expect(script, contains(r'unsquashfs -ll "$OUT" usr/bin/setsid'));
    expect(script, contains('--skip-bundled-git'));
    expect(script, contains('scaffold_has_bundled_git_tools'));
    expect(
      script,
      contains(
        'Retaining core24-compatible Git and OpenSSH tools from the snap scaffold',
      ),
    );
    expect(script, contains('--no-install'));
    expect(script, contains('item_indent = match.group(1)'));
    expect(script, contains('f"{item_indent}- {item}\\n"'));
    expect(script, contains('the currently installed snap was not changed'));
    expect(script, contains('development repack'));
    expect(script, contains('does not perform a dependency/security refresh'));
    expect(script, contains('For release/security refreshes'));
    expect(
      script.indexOf('NOTICE: this helper creates a development repack'),
      lessThan(
        script.indexOf(r'select_project_flutter "$REQUIRED_FLUTTER_VERSION"'),
      ),
    );

    final help = Process.runSync('bash', [
      'tools/build_install_snap_local.sh',
      '--help',
    ]);
    expect(help.exitCode, 0);
    expect(help.stdout, contains('This is a development repack'));
    expect(help.stdout, contains('does not refresh dependencies'));
    expect(help.stdout, contains('clean Snapcraft procedure'));
  });

  test('local repack replaces clean-snap font links with new bundle fonts', () {
    for (final linkedScaffold in [true, false]) {
      _verifyLocalFontRepack(linkedScaffold: linkedScaffold);
    }
  });

  test('confined dependency checks reject missing and wrong resolutions', () {
    for (final shell in ['/bin/bash', '/bin/sh']) {
      final success = _runSharedRuntimeValidation('ok', shell);
      expect(
        success.exitCode,
        0,
        reason: '${success.stdout}\n${success.stderr}',
      );

      for (final mode in [
        'missing-zero',
        'inspection-error',
        'wrong-gnome',
        'wrong-mesa',
        'wrong-curl',
      ]) {
        final failure = _runSharedRuntimeValidation(mode, shell);
        expect(failure.exitCode, isNot(0), reason: '$shell / $mode');
        expect(failure.stderr, contains('busymark'), reason: '$shell / $mode');
        expect(
          failure.stderr,
          anyOf(
            contains('Unresolved dependencies'),
            contains('Dependency inspection failed'),
            contains('Unexpected resolution'),
          ),
          reason: '$shell / $mode: ${failure.stderr}',
        );
      }
    }
  });

  test('Snap reuses verified platform libraries and retains private tools', () {
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
    final stagePackages = _snapStagePackages(snapcraft);

    expect(snapcraft, contains('extensions: [gnome]'));
    expect(snapcraft, contains('      - password-manager-service'));
    expect(
      File('docs/snap-confinement.md').readAsStringSync(),
      contains('snap connect busymark:password-manager-service'),
    );
    for (final sharedPackage in {
      'libhandy-1-0',
      'libsecret-1-0',
      'libwebkit2gtk-4.1-0',
      'libgtk-3-0t64',
      'libglib2.0-0t64',
      'libpango-1.0-0',
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'libx11-6',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxcb-shm0',
      'libxcb1',
      'libwayland-client0',
      'libwayland-cursor0',
      'libwayland-egl1',
    }) {
      expect(stagePackages, isNot(contains(sharedPackage)));
    }
    for (final privatePackage in {
      'gstreamer1.0-libav',
      'gstreamer1.0-plugins-bad',
      'gstreamer1.0-plugins-ugly',
      'git',
      'fonts-noto-core',
      'fonts-noto-mono',
      'openssh-client',
      'util-linux',
      'yaru-theme-gtk',
      'yaru-theme-icon',
    }) {
      expect(stagePackages, contains(privatePackage));
    }

    for (final buildPackage in {
      'libhandy-1-dev',
      'libsecret-1-dev',
      'libwebkit2gtk-4.1-dev',
      'libglib2.0-dev',
      'libpango1.0-dev',
    }) {
      expect(snapcraft, contains('- $buildPackage'));
    }
  });

  test('local snap builder uses the project Flutter toolchain', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final script = File('tools/build_install_snap_local.sh').readAsStringSync();

    expect(
      RegExp(r'^  flutter: \d+\.\d+\.\d+$', multiLine: true).hasMatch(pubspec),
      isTrue,
    );
    expect(script, contains('project_flutter_version'));
    expect(script, contains('select_project_flutter'));
    expect(script, contains('BUSYMARK_FLUTTER_BIN'));
    expect(script, contains(r'--branch "$required_version"'));
    expect(script, contains(r'"$FLUTTER_BIN" pub get --enforce-lockfile'));
    expect(script, contains(r'"$FLUTTER_BIN" analyze --no-pub'));
    expect(script, contains(r'"$FLUTTER_BIN" test --no-pub'));
    expect(script, contains(r'"$FLUTTER_BIN" build linux --release --no-pub'));
  });

  test('Snapcraft pins the same Flutter release as the project', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
    final projectVersion = RegExp(
      r'^  flutter: (\d+\.\d+\.\d+)$',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;

    expect(snapcraft, contains('BUSYMARK_FLUTTER_VERSION: "$projectVersion"'));
    expect(
      snapcraft,
      contains(r'git clone --depth 1 --branch "$BUSYMARK_FLUTTER_VERSION"'),
    );
    expect(
      snapcraft,
      contains(r'git -C "$flutter_sdk" describe --tags --exact-match HEAD'),
    );
    expect(
      snapcraft,
      contains(r'"$flutter_sdk/bin/flutter" --no-version-check build linux'),
    );
    expect(snapcraft, isNot(contains('git clone --depth 1 -b stable')));
  });

  test('local snap builder keeps compiler output off the system tmpfs', () {
    final script = File('tools/build_install_snap_local.sh').readAsStringSync();

    expect(script, contains('BUSYMARK_BUILD_TMP_ROOT'));
    expect(script, contains(r'${XDG_CACHE_HOME:-$HOME/.cache}/busymark/tmp'));
    expect(script, contains(r'mktemp -d "$build_tmp_root/snap-build.XXXXXX"'));
    expect(script, contains(r'export TMPDIR="$BUSYMARK_BUILD_TMP_DIR"'));
    expect(script, contains('trap cleanup_build_tmp EXIT'));
  });

  test('Flutter content menus use native GTK popup menu semantics', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final service = File(
      'lib/src/platform/native_menu_service.dart',
    ).readAsStringSync();
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final probe = File('tools/linux_native_menu_probe.py').readAsStringSync();
    final toolbar = File(
      'lib/src/editor/wysiwyg/wysiwyg_toolbar.dart',
    ).readAsStringSync();
    final nativeMenuStart = native.indexOf(
      'constexpr char kNativeMenuActionNamespace',
    );
    final nativeMenuEnd = native.indexOf(
      'static void my_application_activate',
      native.indexOf('struct NativeMenuSession', nativeMenuStart),
    );
    expect(nativeMenuStart, isNonNegative);
    expect(nativeMenuEnd, greaterThan(nativeMenuStart));
    final nativeMenu = native.substring(nativeMenuStart, nativeMenuEnd);

    expect(native, contains('kNativeMenuChannel'));
    expect(native, contains('"busymark/native_menus"'));
    expect(nativeMenu, isNot(contains('struct NativeMenuHostWidgets')));
    expect(nativeMenu, isNot(contains('gtk_event_box_set_above_child(')));
    expect(nativeMenu, isNot(contains('input_layer')));
    expect(nativeMenu, isNot(contains('menu_layer')));
    expect(nativeMenu, isNot(contains('gtk_fixed_move(')));
    expect(nativeMenu, contains('GtkWidget* menu;'));
    expect(nativeMenu, contains('GMenu* model;'));
    expect(nativeMenu, contains('GSimpleActionGroup* action_group;'));
    expect(nativeMenu, contains('g_simple_action_new_stateful('));
    expect(nativeMenu, contains('g_variant_new_boolean(selected)'));
    expect(nativeMenu, isNot(contains('G_VARIANT_TYPE_STRING')));
    expect(nativeMenu, isNot(contains('g_variant_new_string(')));
    expect(
      nativeMenu,
      isNot(contains('g_menu_item_set_action_and_target_value(')),
    );
    expect(nativeMenu, isNot(contains('select-group-')));
    expect(nativeMenu, isNot(contains('GTK_IS_MODEL_BUTTON')));
    expect(nativeMenu, isNot(contains('style_native_menu_item')));
    expect(nativeMenu, isNot(contains('gtk_menu_button_')));
    expect(
      nativeMenu,
      contains(
        'gtk_widget_insert_action_group(\n'
        '      data->view, kNativeMenuActionNamespace',
      ),
    );
    expect(nativeMenu, isNot(contains('gtk_button_new()')));
    expect(nativeMenu, isNot(contains('gtk_radio_button_new(')));
    expect(nativeMenu, isNot(contains('gtk_toggle_button_new()')));
    expect(nativeMenu, isNot(contains('"radio-checked-symbolic"')));
    expect(nativeMenu, isNot(contains('"radio-symbolic"')));
    expect(native, isNot(contains('kNativeMenuSelectedIndicatorStyleClass')));
    expect(nativeMenu, isNot(contains('create_native_content_menu_item(')));
    expect(nativeMenu, isNot(contains('gtk_render_option(')));
    expect(native, isNot(contains('kNativeContentMenuPopoverStyleClass')));
    expect(nativeMenu, contains('g_menu_append_section('));
    expect(nativeMenu, contains('set_menu_item_accelerator('));
    expect(nativeMenu, contains('g_menu_item_set_icon(item, icon)'));
    expect(nativeMenu, contains('native_menu_action_activated_cb'));
    expect(nativeMenu, contains('native_menu_check_activated_cb'));
    expect(nativeMenu, isNot(contains('native_menu_selection_activated_cb')));
    expect(nativeMenu, contains('gtk_menu_new_from_model('));
    expect(nativeMenu, contains('GTK_IS_MENU(session->menu)'));
    expect(nativeMenu, contains('gtk_menu_attach_to_widget('));
    expect(nativeMenu, contains('gtk_widget_translate_coordinates('));
    expect(nativeMenu, contains('native_menu_capture_trigger_event'));
    expect(nativeMenu, contains('gdk_event_copy(event)'));
    expect(nativeMenu, contains('gtk_menu_popup_at_rect('));
    expect(nativeMenu, contains('rect_window, &window_anchor'));
    expect(nativeMenu, contains('data->trigger_event)'));
    expect(nativeMenu, contains('GDK_GRAVITY_SOUTH_WEST'));
    expect(nativeMenu, contains('GDK_GRAVITY_NORTH_WEST'));
    expect(nativeMenu, contains('GDK_ANCHOR_FLIP_Y'));
    expect(nativeMenu, contains('GDK_ANCHOR_SLIDE'));
    expect(nativeMenu, contains('GDK_ANCHOR_RESIZE'));
    expect(nativeMenu, contains('native_menu_deactivate_cb'));
    expect(nativeMenu, contains('"deactivate"'));
    expect(nativeMenu, contains('gtk_menu_shell_select_first('));
    expect(nativeMenu, contains('gtk_menu_shell_deselect('));
    expect(nativeMenu, contains('gtk_menu_shell_deactivate('));
    expect(nativeMenu, isNot(contains('gtk_popover_')));
    expect(nativeMenu, isNot(contains('GTK_STATE_FLAG_PRELIGHT')));
    expect(nativeMenu, isNot(contains('gtk_widget_set_state_flags')));
    expect(nativeMenu, isNot(contains('native_menu_release_input_grab')));
    expect(nativeMenu, isNot(contains('native_menu_popup_idle_cb')));
    expect(nativeMenu, isNot(contains('gdk_display_flush')));
    expect(nativeMenu, isNot(contains('wl_display_')));
    expect(service, contains('final String? shortcut'));
    expect(service, contains('final String? iconName'));
    expect(service, contains('final int? iconColorArgb'));
    expect(service, contains("'icon': iconName!"));
    expect(service, contains("'iconColor': iconColorArgb!"));
    expect(service, contains("'shortcut': shortcut!"));
    expect(service, contains('this.checkable = false'));
    expect(service, contains('this.mutuallyExclusive = false'));
    expect(service, contains("'mutuallyExclusive': mutuallyExclusive"));
    expect(service, contains('separator = false'));
    expect(design, contains('NativeMenuEntry.separator()'));
    expect(design, contains('NativeMenuEntry.command('));
    expect(
      design,
      contains('iconName: BusyMarkGlyphs.nativeMenuIconName(item.icon)'),
    );
    expect(design, contains('iconColorArgb: item.iconColor?.toARGB32()'));
    expect(nativeMenu, contains('create_native_menu_icon('));
    expect(nativeMenu, contains('kGitBranchMenuIcon'));
    expect(nativeMenu, contains('cairo_curve_to('));
    expect(nativeMenu, contains('gtk_icon_info_load_symbolic('));
    expect(design, contains('shortcut: item.shortcut'));
    expect(design, contains('checkable: item.trailingCheck'));
    expect(design, contains('mutuallyExclusive: item.mutuallyExclusive'));
    expect(probe, contains('command == "assert-check"'));
    expect(probe, contains('Atspi.Role.CHECK_MENU_ITEM'));
    expect(probe, contains('Atspi.Role.RADIO_MENU_ITEM'));
    expect(probe, contains('Atspi.StateType.CHECKED'));
    expect(design, contains('class BusyMarkMenuButton<T>'));
    expect(design, isNot(contains('YaruPopupMenuButton<T>(')));
    for (final shortcut in <String>[
      'paragraph',
      'heading1',
      'heading2',
      'heading3',
      'heading4',
      'heading5',
      'heading6',
    ]) {
      expect(
        toolbar,
        contains('shortcut: BusyMarkEditorShortcutLabels.$shortcut'),
      );
    }
  });

  test('native content menus clean up direct GTK popup sessions', () {
    final native = File('linux/runner/my_application.cc').readAsStringSync();

    final dispose = RegExp(
      r'static void native_menu_session_dispose[\s\S]*?'
      r'(?=static gboolean native_menu_cleanup_idle_cb)',
    ).firstMatch(native)?.group(0);
    final deactivate = RegExp(
      r'static void native_menu_deactivate_cb[\s\S]*?'
      r'(?=static void native_menu_action_activated_cb)',
    ).firstMatch(native)?.group(0);
    final show = RegExp(
      r'static void show_native_menu[\s\S]*?'
      r'(?=static void native_menu_handler_data_free)',
    ).firstMatch(native)?.group(0);

    expect(dispose, contains('gtk_menu_shell_deactivate('));
    expect(dispose, contains('kNativeMenuActionNamespace, nullptr'));
    expect(dispose, contains('gtk_menu_detach(GTK_MENU(session->menu))'));
    expect(dispose, isNot(contains('gtk_widget_destroy(session->menu)')));
    expect(dispose, contains('g_clear_object(&session->menu)'));
    expect(deactivate, contains('g_idle_add_full('));
    expect(show, contains('gtk_widget_translate_coordinates('));
    expect(show, contains('gtk_menu_new_from_model('));
    expect(show, contains('gtk_menu_attach_to_widget('));
    expect(show, contains('gtk_menu_popup_at_rect('));
    expect(show, contains('G_ACTION_GROUP(session->action_group)'));
    expect(show, isNot(contains('gtk_button_new()')));
    expect(show, isNot(contains('gtk_radio_button_new(')));
    expect(show, contains('gtk_menu_shell_select_first('));
    expect(show, contains('gtk_menu_shell_deselect('));
    expect(show, isNot(contains('gtk_fixed_move(')));
    expect(show, isNot(contains('gtk_menu_button_')));
    expect(native, isNot(contains('gtk_popover_')));
    expect(native, isNot(contains('gtk_grab_remove(')));

    final deactivateIndex = dispose!.indexOf('gtk_menu_shell_deactivate(');
    final detachIndex = dispose.indexOf('gtk_menu_detach(');
    final respondIndex = dispose.indexOf('native_menu_session_respond(');
    final freeIndex = dispose.indexOf('g_free(session)');
    expect(deactivateIndex, isNonNegative);
    expect(detachIndex, greaterThan(deactivateIndex));
    expect(respondIndex, greaterThan(detachIndex));
    expect(freeIndex, greaterThan(respondIndex));
  });
  test(
    'Snap packaging hooks consolidate resources and keep required fixes',
    () {
      final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
      final exclusions = File(
        'snap/gnome-46-2404-prime-exclusions.amd64',
      ).readAsLinesSync();

      expect(snapcraft, contains('missing audited GNOME runtime duplicate'));
      expect(snapcraft, contains('gnome-46-2404-prime-exclusions.amd64'));
      expect(exclusions, contains(contains('revision 153')));
      expect(
        exclusions,
        contains('usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstisomp4.so'),
      );
      for (final runtimeLibrary in {
        'libgdk-3.so.0',
        'libgtk-3.so.0',
        'libpango-1.0.so.0',
        'libpangocairo-1.0.so.0',
        'libpangoft2-1.0.so.0',
        'libX11.so.6',
        'libXdamage.so.1',
        'libXext.so.6',
        'libXfixes.so.3',
        'libxcb-shm.so.0',
        'libxcb.so.1',
        'libwayland-client.so.0',
        'libwayland-cursor.so.0',
        'libwayland-egl.so.1',
      }) {
        expect(
          exclusions,
          contains('usr/lib/x86_64-linux-gnu/$runtimeLibrary'),
        );
      }
      expect(exclusions, isNot(contains(contains('libgstlibav.so'))));
      expect(exclusions, isNot(contains(contains('libgstvideoparsersbad.so'))));
      expect(exclusions.where((line) => line.contains('*')), isEmpty);
      expect(snapcraft, contains(r'cmp -s "$bundled_font" "$staged_font"'));
      expect(snapcraft, contains('ln -s ../../usr/share/fonts/truetype/noto'));
      expect(
        snapcraft,
        contains(r'ln -s "../../usr/share/$resource_kind/$resource_name"'),
      );
      expect(
        snapcraft,
        contains(
          r'"$CRAFT_PRIME/usr/lib/x86_64-linux-gnu/libsphinxbase.so.3.0.0"',
        ),
      );
      expect(snapcraft, contains('caca/libgl_plugin.so.0.0.0'));
      expect(
        snapcraft,
        contains(
          r'rm -f "$CRAFT_PRIME/usr/lib/x86_64-linux-gnu/librsvg-2.so.2"*',
        ),
      );
      expect(
        snapcraft,
        isNot(contains('libflutter_secure_storage_linux_plugin.so')),
      );
      final workflow = File(
        '.github/workflows/flutter-linux.yml',
      ).readAsStringSync();
      expect(workflow, contains(r'graphics_lib="$SNAP/gpu-2404/usr/lib/'));
      expect(workflow, contains('libwayland-egl.so.1'));
      expect(workflow, contains('usr/share/doc/fonts-noto-core/copyright'));
    },
  );
  test('native GTK theme follows brightness without replacing a valid user theme', () {
    final configuration = File(
      'lib/src/app/linux/linux_window_host.dart',
    ).readAsStringSync();
    final native = File('linux/runner/my_application.cc').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(configuration, contains('setPreferDark('));
    expect(configuration, contains('brightness == Brightness.dark'));
    final chrome = File('linux/runner/linux_chrome_host.cc').readAsStringSync();
    expect(chrome, contains('setPreferDark'));
    expect(chrome, contains('host->set_theme('));
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
    expect(snapcraft, contains('export CI=true'));
    expect(
      snapcraft,
      contains(
        r'"$flutter_sdk/bin/flutter" --no-version-check precache --linux',
      ),
    );
    expect(
      snapcraft,
      contains(r'"$flutter_sdk/bin/flutter" --no-version-check pub get'),
    );
    expect(
      snapcraft,
      contains(r'ln -s "../../usr/share/$resource_kind/$resource_name"'),
    );
    expect(
      snapcraft,
      isNot(contains(r'cp -a "$CRAFT_PRIME/usr/share/themes"/Yaru*')),
    );
    expect(
      snapcraft,
      isNot(contains(r'cp -a "$CRAFT_PRIME/usr/share/icons"/Yaru*')),
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
}

Set<String> _snapStagePackages(String snapcraft) {
  final match = RegExp(
    r'^    stage-packages:\n((?:^      - [^\n]+\n)+)',
    multiLine: true,
  ).firstMatch(snapcraft);
  expect(match, isNotNull);
  return RegExp(
    r'^      - ([^\s]+)$',
    multiLine: true,
  ).allMatches(match!.group(1)!).map((entry) => entry.group(1)!).toSet();
}

void _writeFixtureFile(String path, String contents) {
  final file = File(path)..createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void _writeFixtureExecutable(String path, String contents) {
  _writeFixtureFile(path, contents);
  final chmod = Process.runSync('chmod', ['+x', path]);
  expect(chmod.exitCode, 0, reason: '$path: ${chmod.stderr}');
}

void _verifyLocalFontRepack({required bool linkedScaffold}) {
  final fixture = Directory.systemTemp.createTempSync('busymark-repack-font-');
  try {
    final project = '${fixture.path}/project';
    final scaffold = '${fixture.path}/scaffold';
    final root = '${fixture.path}/root';
    final tools = '$project/tools';
    final stubBin = '${fixture.path}/stub-bin';
    final flutterSdk = '${fixture.path}/flutter-sdk';
    final fontDir = '$scaffold/share/busymark/fonts';
    final stagedFont =
        '$scaffold/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf';
    Directory(tools).createSync(recursive: true);
    File(
      'tools/build_install_snap_local.sh',
    ).copySync('$tools/build_install_snap_local.sh');
    _writeFixtureFile(
      '$project/pubspec.yaml',
      'name: busymark\nversion: 0.5.1\nenvironment:\n  flutter: 3.47.5\n',
    );
    _writeFixtureFile(
      '$project/snap/snapcraft.yaml',
      'name: busymark\nicon: icon.svg\napps:\n  busymark:\n    plugs:\n      - home\n',
    );
    _writeFixtureFile('$project/icon.svg', '<svg/>\n');
    _writeFixtureFile(
      '$project/linux/CMakeLists.txt',
      'set(BINARY_NAME "busymark")\nset(APPLICATION_ID "io.busystack.busymark")\n',
    );
    _writeFixtureFile(
      '$project/linux/io.busystack.busymark.desktop',
      '[Desktop Entry]\nType=Application\nName=BusyMark\nIcon=busymark\n',
    );
    _writeFixtureFile(
      '$scaffold/meta/snap.yaml',
      'name: busymark\nversion: 0.5.0\napps:\n  busymark:\n    command: busymark\n',
    );
    _writeFixtureFile(stagedFont, 'scaffold font bytes');
    if (linkedScaffold) {
      Directory('$scaffold/share/busymark').createSync(recursive: true);
      Link(fontDir).createSync('../../usr/share/fonts/truetype/noto');
    } else {
      _writeFixtureFile('$fontDir/NotoSans-Regular.ttf', 'old bundle font');
    }
    _writeFixtureFile(
      '$flutterSdk/bin/cache/flutter.version.json',
      '{"frameworkVersion":"3.47.5"}\n',
    );
    _writeFixtureExecutable('$flutterSdk/bin/flutter', r'''#!/bin/sh
set -eu
case "$1" in
  pub) exit 0 ;;
  build)
    bundle="$STUB_PROJECT/build/linux/x64/release/bundle"
    mkdir -p "$bundle/share/busymark/fonts"
    printf 'new bundle font bytes' > "$bundle/share/busymark/fonts/NotoSans-Regular.ttf"
    printf '#!/bin/sh\nexit 0\n' > "$bundle/busymark"
    exit 0 ;;
esac
exit 1
''');
    _writeFixtureExecutable('$stubBin/snap', r'''#!/bin/sh
set -eu
test "$1" = pack
touch "${3#--filename=}"
''');
    _writeFixtureExecutable('$stubBin/unsquashfs', r'''#!/bin/sh
set -eu
case "$1" in
  -cat) cat "$STUB_SNAP_ROOT/meta/snap.yaml" ;;
  -ll) printf 'squashfs-root/busymark\nsquashfs-root/meta/gui/busymark.desktop\n' ;;
esac
''');
    _writeFixtureExecutable('$stubBin/sudo', r'''#!/bin/sh
printf 'unexpected installation\n' > "$STUB_INSTALL_MARKER"
exit 1
''');

    final installMarker = '${fixture.path}/install-called';
    final result = Process.runSync(
      'bash',
      [
        '$tools/build_install_snap_local.sh',
        '--no-install',
        '--skip-tests',
        '--skip-bundled-git',
        '--scaffold',
        scaffold,
        '--root',
        root,
        '--output',
        '${fixture.path}/local.snap',
      ],
      environment: {
        ...Platform.environment,
        'PATH': '$stubBin:${Platform.environment['PATH']}',
        'BUSYMARK_FLUTTER_BIN': '$flutterSdk/bin/flutter',
        'BUSYMARK_BUILD_TMP_ROOT': '${fixture.path}/build-tmp',
        'STUB_PROJECT': project,
        'STUB_SNAP_ROOT': root,
        'STUB_INSTALL_MARKER': installMarker,
      },
    );
    expect(
      result.exitCode,
      0,
      reason: 'linked=$linkedScaffold\n${result.stdout}\n${result.stderr}',
    );
    expect(File('${fixture.path}/local.snap').existsSync(), isTrue);
    expect(Link('$root/share/busymark/fonts').existsSync(), isFalse);
    expect(
      File(
        '$root/share/busymark/fonts/NotoSans-Regular.ttf',
      ).readAsStringSync(),
      'new bundle font bytes',
    );
    expect(
      File(
        '$root/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
      ).readAsStringSync(),
      'scaffold font bytes',
    );
    expect(File(stagedFont).readAsStringSync(), 'scaffold font bytes');
    expect(File(installMarker).existsSync(), isFalse);
  } finally {
    fixture.deleteSync(recursive: true);
  }
}

String _sharedRuntimeValidationBody() {
  final workflow = File(
    '.github/workflows/flutter-linux.yml',
  ).readAsStringSync();
  const step =
      '      - name: Verify shared runtimes, packaged tools, media, and resources';
  final stepAt = workflow.indexOf(step);
  expect(stepAt, greaterThanOrEqualTo(0));
  final bodyAt =
      workflow.indexOf('        run: |\n', stepAt) + '        run: |\n'.length;
  final nextStepAt = workflow.indexOf('\n      - name:', bodyAt);
  expect(nextStepAt, greaterThan(bodyAt));
  return workflow
      .substring(bodyAt, nextStepAt)
      .split('\n')
      .map((line) {
        return line.startsWith('          ') ? line.substring(10) : line;
      })
      .join('\n');
}

ProcessResult _runSharedRuntimeValidation(String mode, String shell) {
  final fixture = Directory.systemTemp.createTempSync(
    'busymark-runtime-check-',
  );
  try {
    final snap = '${fixture.path}/snap';
    final gnome = '${fixture.path}/gnome';
    final triplet = 'x86_64-linux-gnu';
    final graphics = '$snap/gpu-2404/usr/lib/$triplet';
    final providerPlugins = '$gnome/usr/lib/$triplet/gstreamer-1.0';
    final privatePlugins = '$snap/usr/lib/$triplet/gstreamer-1.0';
    final stubBin = '${fixture.path}/bin';
    for (final path in [
      '$snap/busymark',
      '$snap/usr/lib/git-core/git-remote-http',
      '$snap/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
      '$snap/usr/share/doc/fonts-noto-core/copyright',
      '$snap/usr/share/doc/fonts-noto-mono/copyright',
    ]) {
      _writeFixtureFile(path, 'fixture');
    }
    for (final library in [
      'libX11.so.6',
      'libXdamage.so.1',
      'libXext.so.6',
      'libXfixes.so.3',
      'libxcb-shm.so.0',
      'libxcb.so.1',
      'libwayland-client.so.0',
      'libwayland-cursor.so.0',
      'libwayland-egl.so.1',
    ]) {
      _writeFixtureFile('$graphics/$library', 'fixture');
    }
    for (final library in [
      'libhandy-1.so.0',
      'libsecret-1.so.0',
      'libwebkit2gtk-4.1.so.0',
      'libgtk-3.so.0',
      'libglib-2.0.so.0',
      'libpango-1.0.so.0',
    ]) {
      _writeFixtureFile('$gnome/usr/lib/$triplet/$library', 'fixture');
    }
    _writeFixtureFile('$snap/usr/lib/$triplet/libcurl-gnutls.so.4', 'fixture');
    for (final helper in [
      'WebKitWebProcess',
      'WebKitNetworkProcess',
      'WebKitGPUProcess',
    ]) {
      _writeFixtureExecutable(
        '$gnome/usr/lib/$triplet/webkit2gtk-4.1/$helper',
        '#!/bin/sh\n',
      );
    }
    for (final plugin in [
      'libgstavi.so',
      'libgstisomp4.so',
      'libgstmatroska.so',
      'libgstogg.so',
      'libgsttheora.so',
      'libgstvpx.so',
    ]) {
      _writeFixtureFile('$providerPlugins/$plugin', 'fixture');
    }
    for (final plugin in [
      'libgstlibav.so',
      'libgstvideoparsersbad.so',
      'libgstmpeg2dec.so',
    ]) {
      _writeFixtureFile('$privatePlugins/$plugin', 'fixture');
    }
    Directory('$snap/share/busymark').createSync(recursive: true);
    Link(
      '$snap/share/busymark/fonts',
    ).createSync('../../usr/share/fonts/truetype/noto');
    for (final kind in ['themes', 'icons']) {
      for (final name in ['Yaru', 'Yaru-dark']) {
        Directory('$snap/usr/share/$kind/$name').createSync(recursive: true);
        Directory('$snap/share/$kind').createSync(recursive: true);
        Link(
          '$snap/share/$kind/$name',
        ).createSync('../../usr/share/$kind/$name');
      }
    }
    _writeFixtureExecutable('$stubBin/snap', r'''#!/bin/sh
set -eu
test "$1" = run
test "$2" = --shell
test "$4" = -c
exec "$STUB_INSPECTION_SHELL" -c "$5"
''');
    _writeFixtureExecutable('$stubBin/ldd', r'''#!/bin/sh
set -eu
object="$1"
if [ "$STUB_LDD_MODE" = inspection-error ] && [ "$object" = "$SNAP/busymark" ]; then
  printf 'inspection crashed\n'
  exit 7
fi
if [ "$object" = "$SNAP/busymark" ]; then
  for library in libhandy-1.so.0 libsecret-1.so.0 libwebkit2gtk-4.1.so.0 libgtk-3.so.0 libglib-2.0.so.0 libpango-1.0.so.0; do
    path="$SNAP_DESKTOP_RUNTIME/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/$library"
    if [ "$STUB_LDD_MODE" = wrong-gnome ] && [ "$library" = libgtk-3.so.0 ]; then path="/unexpected/$library"; fi
    printf '%s => %s (0x1234)\n' "$library" "$path"
  done
  for library in libX11.so.6 libXdamage.so.1 libXext.so.6 libXfixes.so.3 libxcb-shm.so.0 libxcb.so.1 libwayland-client.so.0 libwayland-cursor.so.0 libwayland-egl.so.1; do
    path="$SNAP/gpu-2404/usr/lib/$SNAP_LAUNCHER_ARCH_TRIPLET/$library"
    if [ "$STUB_LDD_MODE" = wrong-mesa ] && [ "$library" = libX11.so.6 ]; then path="/unexpected/$library"; fi
    printf '%s => %s (0x1234)\n' "$library" "$path"
  done
  if [ "$STUB_LDD_MODE" = missing-zero ]; then printf 'libmissing.so.1 => not found\n'; fi
elif [ "$object" = "$SNAP/usr/lib/git-core/git-remote-http" ]; then
  path="$SNAP/usr/lib/git-core/../$SNAP_LAUNCHER_ARCH_TRIPLET/libcurl-gnutls.so.4"
  if [ "$STUB_LDD_MODE" = wrong-curl ]; then path=/unexpected/libcurl-gnutls.so.4; fi
  printf 'libcurl-gnutls.so.4 => %s (0x1234)\n' "$path"
else
  printf 'libgstreamer-1.0.so.0 => %s/usr/lib/%s/libgstreamer-1.0.so.0 (0x1234)\n' "$SNAP_DESKTOP_RUNTIME" "$SNAP_LAUNCHER_ARCH_TRIPLET"
fi
''');
    _writeFixtureExecutable(
      '$snap/usr/bin/git',
      '#!/bin/sh\nprintf "%s\\n" "\$GIT_EXEC_PATH"\n',
    );
    _writeFixtureExecutable(
      '$snap/usr/bin/ssh',
      '#!/bin/sh\nprintf "OpenSSH fixture\\n" >&2\n',
    );
    _writeFixtureExecutable('$snap/usr/bin/setsid', '#!/bin/sh\n');
    final result = Process.runSync(
      'bash',
      ['-c', _sharedRuntimeValidationBody()],
      environment: {
        ...Platform.environment,
        'PATH': '$stubBin:${Platform.environment['PATH']}',
        'SNAP': snap,
        'SNAP_DESKTOP_RUNTIME': gnome,
        'SNAP_LAUNCHER_ARCH_TRIPLET': triplet,
        'STUB_LDD_MODE': mode,
        'STUB_INSPECTION_SHELL': shell,
      },
    );
    return result;
  } finally {
    fixture.deleteSync(recursive: true);
  }
}

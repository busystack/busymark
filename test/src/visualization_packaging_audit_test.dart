import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README screenshot references resolve to checked-in images', () {
    final readme = File('README.md').readAsStringSync();
    final screenshotPaths = RegExp(
      r'<img src="(docs/screenshots/[^"]+)"',
    ).allMatches(readme).map((match) => match.group(1)!).toSet();

    expect(screenshotPaths, hasLength(5));
    for (final path in screenshotPaths) {
      final screenshot = File(path);
      expect(screenshot.existsSync(), isTrue, reason: '$path is missing');
      expect(
        screenshot.lengthSync(),
        greaterThan(1024),
        reason: '$path is not a usable screenshot',
      );
    }
  });

  test('release metadata is consistent and production-grade', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
    final metainfo = File(
      'linux/io.busystack.busymark.metainfo.xml',
    ).readAsStringSync();

    expect(pubspec, contains(RegExp(r'^version: 0\.3\.5$', multiLine: true)));
    expect(
      snapcraft,
      contains(RegExp(r'^version: "0\.3\.5"$', multiLine: true)),
    );
    expect(snapcraft, contains(RegExp(r'^grade: stable$', multiLine: true)));
    expect(
      snapcraft,
      contains(RegExp(r'^confinement: strict$', multiLine: true)),
    );
    expect(snapcraft, contains('extensions: [gnome]'));
    expect(snapcraft, contains('XDG_CONFIG_HOME:'));
    expect(snapcraft, contains('XDG_CACHE_HOME:'));
    expect(snapcraft, contains('XDG_DATA_HOME:'));
    expect(snapcraft, contains('- home'));
    expect(snapcraft, contains('- network'));
    expect(snapcraft, contains('- removable-media'));
    expect(snapcraft, contains('- ssh-keys'));
    expect(snapcraft, contains('- enable-patchelf'));
    expect(
      snapcraft,
      contains(
        RegExp(
          r'^contact: https://github\.com/busystack/busymark/issues$',
          multiLine: true,
        ),
      ),
    );
    expect(metainfo, contains('<release version="0.3.5"'));
    expect(pubspec, isNot(contains('0.3.55')));
    expect(snapcraft, isNot(contains('0.3.55')));
  });

  test(
    'web engines are exact, checksummed, licensed, and installed offline',
    () {
      final fetch = File('tools/fetch_visualization_web.sh').readAsStringSync();
      final package =
          jsonDecode(
                File('tools/visualization/package.json').readAsStringSync(),
              )
              as Map<String, Object?>;
      final dependencies = package['dependencies'] as Map<String, Object?>;
      final lock = File(
        'tools/visualization/package-lock.json',
      ).readAsStringSync();
      final webBuild = File(
        'tools/visualization/build_render_engines.js',
      ).readAsStringSync();
      final webEngines = File(
        'tools/visualization/render_engines.js',
      ).readAsStringSync();
      final cmake = File('linux/CMakeLists.txt').readAsStringSync();

      expect(dependencies, isNot(contains('mermaid')));
      expect(dependencies['@mermaid-js/parser'], '1.2.0');
      expect(dependencies['@plantuml/core'], '1.2026.6');
      expect(dependencies['@scalar/openapi-parser'], '0.28.14');
      expect(dependencies['@scalar/api-reference'], '1.65.1');
      expect(dependencies['@scalar/json-magic'], '0.13.0');
      expect(dependencies['yaml'], '2.9.0');
      expect(dependencies['@mathjax/src'], '4.1.3');
      expect(dependencies['@mathjax/mathjax-newcm-font'], '4.1.3');
      expect(dependencies, isNot(contains('katex')));
      expect(lock, isNot(contains('node_modules/katex')));
      expect((package['engines'] as Map<String, Object?>)['node'], '>=22');
      for (final checksum in [
        '0ee99b3bb82766e5d6c34b8cc768b8530ce8f1aaa13790ae368aebeef3de9d11',
        '798f99592eb03a6446519d2becf78e6f1008d0d25c75d60b37a0f46e39e3c413',
        '993bb7ebb3480cc574665b0eac52d9cd4a817fdf5b4444894bb70e174880513d',
        '68b6f22ca530ac50e3cd034c5189d89cc5457c3c2d325b44e90db05c9f08c573',
        'f1adefc461f3594afd4ad16974820a5a88b271f7e8051045c2ac7a34eb974d33',
        '008fa204cb1ba700e0272ba045abbf09a6ffe63456e8146ba97cac6c2ad1ef91',
        '4611bed26b338dfc4b5757b8ed2d7ba82a85bcbd05d2729fb3465fba17b8896c',
        '87d7b869c6a2a6169d9a53acc4eab6c846a9cbe11752738226461bb5070c8b88',
      ]) {
        expect(fetch, contains(checksum));
      }
      expect(fetch, contains('sha256sum --check --status'));
      expect(fetch, contains('npm ci'));
      expect(fetch, contains('--ignore-scripts'));
      expect(fetch, contains('NODE_MAJOR < 22'));
      expect(fetch, contains('THIRD_PARTY_NOTICES.md'));
      expect(fetch, contains(r'mermaid@${MERMAID_VERSION}.tar.gz'));
      expect(fetch, contains('packages/mermaid'));
      expect(fetch, contains('build_render_engines.js'));
      expect(webBuild, contains('katex: disabledMathModule'));
      expect(
        webBuild,
        contains("path.join(mermaidSource, 'src', 'mermaid.ts')"),
      );
      expect(
        webEngines,
        contains("svg.style.setProperty('max-width', 'none', 'important')"),
      );
      expect(cmake, contains('share/busymark/visualization'));
      expect(cmake, contains('bootstrap.js'));
    },
  );

  test('D2 is checksum pinned for amd64 and installed with notices', () {
    final fetch = File('tools/fetch_d2.sh').readAsStringSync();
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(fetch, contains('D2_VERSION="0.7.1"'));
    expect(
      fetch,
      contains(
        'eb172adf59f38d1e5a70ab177591356754ffaf9bebb84e0ca8b767dfb421dad7',
      ),
    );
    expect(
      fetch,
      contains(
        '48db68dfb42b76970a6769f038ec60da932adbb058257e07c50f5baaa3046016',
      ),
    );
    expect(fetch, contains('x86_64|amd64'));
    expect(fetch, isNot(contains('arm64|aarch64')));
    expect(cmake, contains('share/licenses/d2'));
    expect(cmake, contains('libexec/busymark'));
    expect(snapcraft, contains('build-on: [amd64]'));
  });

  test('Linux CI builds and exercises the bundled visualization stack', () {
    final workflow = File(
      '.github/workflows/flutter-linux.yml',
    ).readAsStringSync();

    expect(workflow, contains('libwebkit2gtk-4.1-dev'));
    expect(workflow, contains('apparmor-profiles'));
    expect(workflow, contains('bwrap-userns-restrict'));
    expect(workflow, contains('--unshare-net /usr/bin/true'));
    expect(
      workflow,
      isNot(contains('WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS')),
    );
    expect(workflow, contains('poppler-utils'));
    expect(workflow, contains('actions/checkout@v7'));
    expect(workflow, contains('actions/setup-node@v7'));
    expect(workflow, contains('actions/upload-artifact@v7'));
    expect(workflow, contains("node-version: '22'"));
    expect(workflow, contains('BUSYMARK_D2_PATH:'));
    expect(workflow, contains('BUSYMARK_TYPST_PATH:'));
    expect(workflow, contains('tools/visualization_smoke.py'));
    expect(workflow, contains('GDK_BACKEND=wayland'));
    expect(workflow, contains('snapcore/action-build@v1'));
    expect(workflow, contains("if: steps.snapcraft.outcome == 'failure'"));
    expect(workflow, contains(r'${PRIMARY_SNAP:-$RETRY_SNAP}'));
    expect(workflow, contains('steps.snap-artifact.outputs.snap'));
    expect(workflow, contains('sudo snap install --dangerous'));
    expect(workflow, isNot(contains('--dangerous --classic')));
    expect(workflow, contains('snap run busymark'));
    expect(workflow, contains('--visualization-release-smoke='));
    expect(workflow, contains('BUSYMARK_RELEASE_SMOKE=1'));
    expect(workflow, contains('visualization-smoke.pdf'));
    final smoke = File('tools/visualization_smoke.py').readAsStringSync();
    expect(smoke, contains('terminate_web_process'));
    expect(smoke, contains('WebKit process termination and recovery'));
    expect(smoke, contains('smoke-responsive-gradient'));
    expect(smoke, contains('Raster snapshot lacked visual variation'));
  });

  test(
    'WebKit host and harness disable persistence and external resources',
    () {
      final native = File('linux/runner/web_render_host.cc').readAsStringSync();
      final harness = File(
        'tools/visualization/harness.html',
      ).readAsStringSync();
      final reference = File(
        'tools/visualization/reference.html',
      ).readAsStringSync();
      final scalar = File(
        'tools/visualization/reference.js',
      ).readAsStringSync();
      final bootstrap = File(
        'tools/visualization/bootstrap.js',
      ).readAsStringSync();
      final math = File(
        'tools/visualization/mathjax_renderer.js',
      ).readAsStringSync();
      final renderEngines = File(
        'tools/visualization/render_engines.js',
      ).readAsStringSync();
      final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

      expect(native, contains('webkit_web_context_new_ephemeral'));
      expect(native, contains('webkit_web_context_set_sandbox_enabled'));
      expect(
        native,
        contains('webkit_web_context_set_sandbox_enabled(self->context, TRUE)'),
      );
      expect(native, contains('WEBKIT_COOKIE_POLICY_ACCEPT_NEVER'));
      expect(
        native,
        contains('set_enable_html5_local_storage(settings, FALSE)'),
      );
      expect(native, contains('set_enable_html5_database(settings, FALSE)'));
      expect(native, contains('set_enable_webrtc(settings, FALSE)'));
      expect(native, contains('set_enable_developer_extras(settings, FALSE)'));
      expect(native, contains('webkit_permission_request_deny'));
      expect(native, contains('g_str_has_prefix(uri, "busymark-render:")'));
      expect(native, contains('web-process-terminated'));
      expect(native, contains('render_process_terminated_cb'));
      expect(native, contains('recreate_render_view'));
      expect(native, contains('terminateWebProcessForReleaseSmoke'));
      expect(native, contains('"renderMathBatch"'));
      expect(native, contains('BUSYMARK_RELEASE_SMOKE'));
      expect(native, contains('gtk_widget_get_allocated_width'));
      expect(native, contains('snapshot_allocation_attempts'));
      expect(native, contains('schedule_render_view_recreation'));
      expect(native, isNot(contains('g_str_has_prefix(uri, "http:')));
      for (final html in [harness, reference]) {
        expect(html, contains("default-src 'none'"));
        expect(html, contains("connect-src 'none'"));
        expect(html, contains("object-src 'none'"));
        expect(html, isNot(contains('cdn.')));
      }
      expect(bootstrap, contains('createMemoryStorage'));
      expect(renderEngines, contains("case 'renderMathBatch':"));
      expect(math, contains("export const mathJaxVersion = '4.1.3'"));
      expect(math, contains("export const mathJaxFontVersion = '4.1.3'"));
      expect(math, contains('mathjax.asyncLoad = () => Promise.resolve()'));
      expect(math, contains("URLs: 'none'"));
      expect(math, contains("classes: 'none'"));
      expect(math, contains("cssIDs: 'none'"));
      expect(math, contains("styles: 'none'"));
      expect(math, contains('maxBuffer: 20 * 1024'));
      expect(math, contains('maxMacros: 500'));
      expect(math, contains('maxTemplateSubtitutions: 2000'));
      expect(math, contains("fontCache: 'local'"));
      expect(math, contains('useXlink: false'));
      expect(math, contains('clearExpressionDefinitions'));
      expect(math, contains('tex.reset(0)'));
      for (final disabledPackage in [
        'AutoloadConfiguration',
        'RequireConfiguration',
        'SetOptionsConfiguration',
        'TexHtmlConfiguration',
        'PhysicsConfiguration',
      ]) {
        expect(math, isNot(contains(disabledPackage)));
      }
      expect(scalar, contains('telemetry: false'));
      expect(scalar, contains('persistAuth: false'));
      expect(scalar, contains('hideTestRequestButton: true'));
      expect(scalar, contains('hideClientButton: true'));
      expect(scalar, contains('withDefaultFonts: false'));
      expect(scalar, contains('Network access is disabled'));
      expect(snapcraft, contains('libwebkit2gtk-4.1-dev'));
      expect(snapcraft, contains('libwebkit2gtk-4.1-0'));
      expect(snapcraft, contains('interface: browser-support'));
      expect(snapcraft, contains('allow-sandbox: false'));
      expect(snapcraft, contains('node/24/stable'));
    },
  );
}

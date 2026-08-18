import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
      final cmake = File('linux/CMakeLists.txt').readAsStringSync();

      expect(dependencies['mermaid'], '11.16.1');
      expect(dependencies['@plantuml/core'], '1.2026.6');
      expect(dependencies['@scalar/openapi-parser'], '0.28.14');
      expect(dependencies['@scalar/api-reference'], '1.65.1');
      expect(dependencies['@scalar/json-magic'], '0.13.0');
      expect(dependencies['yaml'], '2.9.0');
      expect((package['engines'] as Map<String, Object?>)['node'], '>=22');
      for (final checksum in [
        'ebd9885111092c78cefc79a76f6c1dc34ed5b834b02ae8f338227ce79c003de4',
        '798f99592eb03a6446519d2becf78e6f1008d0d25c75d60b37a0f46e39e3c413',
        '993bb7ebb3480cc574665b0eac52d9cd4a817fdf5b4444894bb70e174880513d',
        '68b6f22ca530ac50e3cd034c5189d89cc5457c3c2d325b44e90db05c9f08c573',
        'f1adefc461f3594afd4ad16974820a5a88b271f7e8051045c2ac7a34eb974d33',
        '008fa204cb1ba700e0272ba045abbf09a6ffe63456e8146ba97cac6c2ad1ef91',
      ]) {
        expect(fetch, contains(checksum));
      }
      expect(fetch, contains('sha256sum --check --status'));
      expect(fetch, contains('npm ci'));
      expect(fetch, contains('--ignore-scripts'));
      expect(fetch, contains('NODE_MAJOR < 22'));
      expect(fetch, contains('THIRD_PARTY_NOTICES.md'));
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
      final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

      expect(native, contains('webkit_web_context_new_ephemeral'));
      expect(native, contains('webkit_web_context_set_sandbox_enabled'));
      expect(native, contains('strictly_confined_snap'));
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
      expect(native, isNot(contains('g_str_has_prefix(uri, "http:')));
      for (final html in [harness, reference]) {
        expect(html, contains("default-src 'none'"));
        expect(html, contains("connect-src 'none'"));
        expect(html, contains("object-src 'none'"));
        expect(html, isNot(contains('cdn.')));
      }
      expect(bootstrap, contains('createMemoryStorage'));
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

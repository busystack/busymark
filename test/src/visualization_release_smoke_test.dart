import 'package:busymark/src/visualization/visualization_release_smoke.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release smoke report path requires an explicit nonempty argument', () {
    expect(
      visualizationReleaseSmokeReportPath(const [
        '--visualization-release-smoke=/tmp/report.json',
      ]),
      isNull,
      reason: 'the product entry point must remain disabled by default',
    );
    expect(
      visualizationReleaseSmokeReportPath(
        const [],
        environment: const {'BUSYMARK_RELEASE_SMOKE': '1'},
      ),
      isNull,
    );
    expect(
      visualizationReleaseSmokeReportPath(
        const ['--visualization-release-smoke='],
        environment: const {'BUSYMARK_RELEASE_SMOKE': '1'},
      ),
      isNull,
    );
    expect(
      visualizationReleaseSmokeReportPath(
        const [
          '/workspace/document.md',
          '--visualization-release-smoke=/tmp/report.json',
        ],
        environment: const {'BUSYMARK_RELEASE_SMOKE': '1'},
      ),
      '/tmp/report.json',
    );
  });
}

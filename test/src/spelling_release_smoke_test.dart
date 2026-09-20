import 'package:busymark/src/spellcheck/spelling_release_smoke.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spelling release smoke requires an explicit guarded report path', () {
    expect(
      spellingReleaseSmokeReportPath(const [
        '--spelling-release-smoke=/tmp/report.json',
      ]),
      isNull,
    );
    expect(
      spellingReleaseSmokeReportPath(
        const ['--spelling-release-smoke='],
        environment: const {'BUSYMARK_RELEASE_SMOKE': '1'},
      ),
      isNull,
    );
    expect(
      spellingReleaseSmokeReportPath(
        const [
          '/workspace/document.md',
          '--spelling-release-smoke=/tmp/report.json',
        ],
        environment: const {'BUSYMARK_RELEASE_SMOKE': '1'},
      ),
      '/tmp/report.json',
    );
  });
}

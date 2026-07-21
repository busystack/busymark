import 'package:busymark/src/feedback/feedback_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('loads version and build number from package metadata', () async {
    final loader = PackageInfoFeedbackAppMetadataLoader(
      packageInfoLoader: () async => PackageInfo(
        appName: 'BusyMark',
        packageName: 'busymark',
        version: '1.2.3',
        buildNumber: '456',
      ),
    );

    final metadata = await loader.load();

    expect(metadata.version, '1.2.3');
    expect(metadata.buildNumber, '456');
  });

  test('uses zero when package build metadata is absent', () async {
    final loader = PackageInfoFeedbackAppMetadataLoader(
      packageInfoLoader: () async => PackageInfo(
        appName: 'BusyMark',
        packageName: 'busymark',
        version: '1.2.3',
        buildNumber: '',
      ),
    );

    final metadata = await loader.load();

    expect(metadata.version, '1.2.3');
    expect(metadata.buildNumber, '0');
  });

  test('rejects missing package version metadata', () async {
    final loader = PackageInfoFeedbackAppMetadataLoader(
      packageInfoLoader: () async => PackageInfo(
        appName: 'BusyMark',
        packageName: 'busymark',
        version: '',
        buildNumber: '456',
      ),
    );

    await expectLater(loader.load(), throwsStateError);
  });
}

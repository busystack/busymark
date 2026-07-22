import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();

class FeedbackAppMetadata {
  const FeedbackAppMetadata({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;
}

abstract interface class FeedbackAppMetadataLoader {
  Future<FeedbackAppMetadata> load();
}

class PackageInfoFeedbackAppMetadataLoader
    implements FeedbackAppMetadataLoader {
  PackageInfoFeedbackAppMetadataLoader({PackageInfoLoader? packageInfoLoader})
    : _packageInfoLoader = packageInfoLoader ?? _loadPackageInfo;

  final PackageInfoLoader _packageInfoLoader;

  @override
  Future<FeedbackAppMetadata> load() async {
    final packageInfo = await _packageInfoLoader();
    final version = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();
    if (version.isEmpty) {
      throw StateError('Application version metadata is unavailable.');
    }
    return FeedbackAppMetadata(
      version: version,
      buildNumber: buildNumber.isEmpty ? '0' : buildNumber,
    );
  }

  static Future<PackageInfo> _loadPackageInfo() {
    return PackageInfo.fromPlatform();
  }
}

final feedbackAppMetadataLoaderProvider = Provider<FeedbackAppMetadataLoader>(
  (ref) => PackageInfoFeedbackAppMetadataLoader(),
);

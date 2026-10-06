import 'dart:typed_data';

import 'asset_ingestion_service.dart';

class ManagedAssetPublication {
  const ManagedAssetPublication({
    required this.id,
    required this.reference,
    required this.cachedPath,
  });
  final String id;
  final String reference;
  final String cachedPath;
}

/// Remote asset publication uses the provider's durable operation sequence.
/// No document or workspace path participates in the storage decision.
class ProviderAssetIngestionService extends AssetIngestionService {
  static final unavailable = ProviderAssetIngestionService(
    publish: (_, _) => throw const AssetIngestionException(
      'asset.provider-unavailable',
      'The note attachment provider is unavailable.',
    ),
    cancelPublication: (_) async {},
  );
  const ProviderAssetIngestionService({
    required this.publish,
    required this.cancelPublication,
  });

  final Future<ManagedAssetPublication> Function(
    Uint8List bytes,
    String filename,
  )
  publish;
  final Future<void> Function(String reference) cancelPublication;

  @override
  Future<IngestedAsset> ingestBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) async {
    if (!canIngestMediaBytes(
      bytes: bytes,
      suggestedFileName: suggestedFileName,
    )) {
      throw const AssetIngestionException(
        'asset.invalid-media-type',
        'The retained file is not supported or exceeds the size limit.',
      );
    }
    final publication = await publish(bytes, suggestedFileName);
    return IngestedAsset(
      absolutePath: publication.cachedPath,
      markdownPath: publication.reference,
      mimeType: 'application/octet-stream',
      reusedExisting: false,
      origin: origin,
      publicationId: publication.id,
    );
  }

  @override
  Future<IngestedAsset> ingestMediaBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) => ingestBytes(
    bytes: bytes,
    suggestedFileName: suggestedFileName,
    request: request,
    origin: origin,
  );

  @override
  Future<void> commit(IngestedAsset asset) async {}

  @override
  Future<void> rollback(IngestedAsset asset) =>
      cancelPublication(asset.markdownPath);
}

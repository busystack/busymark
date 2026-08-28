import 'dart:async';
import 'package:flutter/services.dart';

class AssetInputService {
  AssetInputService({
    MethodChannel channel = const MethodChannel('com.busymark.app/asset_input'),
  }) : _channel = channel {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final _droppedFiles = StreamController<List<String>>.broadcast();

  Stream<List<String>> get droppedFiles => _droppedFiles.stream;

  Future<List<String>> readClipboardImageFiles() async {
    try {
      final paths = await _channel.invokeListMethod<String>(
        'readClipboardImageFiles',
      );
      return paths ?? const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<Uint8List?> readClipboardImagePng() async {
    try {
      return await _channel.invokeMethod<Uint8List>('readClipboardImagePng');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'assetFilesDropped') {
      throw MissingPluginException('Unknown asset input method ${call.method}');
    }
    final paths = (call.arguments as List?)?.whereType<String>().toList(
      growable: false,
    );
    if (paths != null && paths.isNotEmpty && !_droppedFiles.isClosed) {
      _droppedFiles.add(paths);
    }
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _droppedFiles.close();
  }
}

final busyMarkAssetInputService = AssetInputService();

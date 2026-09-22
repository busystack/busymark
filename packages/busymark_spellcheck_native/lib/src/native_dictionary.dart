import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../busymark_spellcheck_native_bindings_generated.dart' as bindings;

enum NativeSpellResult { accepted, rejected }

final class NativeSpellException implements Exception {
  const NativeSpellException(this.message);

  final String message;

  @override
  String toString() => 'NativeSpellException: $message';
}

final class NativeWordRange {
  const NativeWordRange({
    required this.utf8Start,
    required this.utf8End,
    required this.characterStart,
    required this.characterEnd,
  });

  final int utf8Start;
  final int utf8End;
  final int characterStart;
  final int characterEnd;
}

/// Owns one native Hunspell handle. Instances stay in the spelling worker
/// isolate; no pointer is exposed through the application API.
final class NativeSpellDictionary {
  NativeSpellDictionary._(this._handle);

  factory NativeSpellDictionary.open({
    required String affPath,
    required String dicPath,
  }) {
    final aff = affPath.toNativeUtf8();
    final dic = dicPath.toNativeUtf8();
    final outHandle = calloc<ffi.Pointer<bindings.BusySpellHandle>>();
    final outError = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final status = bindings.busy_spell_open(
        aff.cast(),
        dic.cast(),
        outHandle,
        outError,
      );
      if (status == bindings.BusySpellStatus.BUSY_SPELL_ERROR.value ||
          outHandle.value == ffi.nullptr) {
        throw NativeSpellException(_takeError(outError));
      }
      return NativeSpellDictionary._(outHandle.value);
    } finally {
      malloc.free(aff);
      malloc.free(dic);
      _freePendingError(outError);
      calloc.free(outError);
      calloc.free(outHandle);
    }
  }

  ffi.Pointer<bindings.BusySpellHandle> _handle;

  bool get isClosed => _handle == ffi.nullptr;

  String get encoding {
    _requireOpen();
    final outValue = calloc<ffi.Pointer<ffi.Char>>();
    final outError = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final status = bindings.busy_spell_dictionary_encoding(
        _handle,
        outValue,
        outError,
      );
      if (status == bindings.BusySpellStatus.BUSY_SPELL_ERROR.value ||
          outValue.value == ffi.nullptr) {
        throw NativeSpellException(_takeError(outError));
      }
      return outValue.value.cast<Utf8>().toDartString();
    } finally {
      if (outValue.value != ffi.nullptr) {
        bindings.busy_spell_free_string(outValue.value);
      }
      _freePendingError(outError);
      calloc.free(outValue);
      calloc.free(outError);
    }
  }

  NativeSpellResult check(String word) {
    _requireOpen();
    final nativeWord = word.toNativeUtf8();
    final outError = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final result = bindings.busy_spell_check(
        _handle,
        nativeWord.cast(),
        outError,
      );
      if (result == bindings.BusySpellStatus.BUSY_SPELL_ACCEPTED.value) {
        return NativeSpellResult.accepted;
      }
      if (result == bindings.BusySpellStatus.BUSY_SPELL_REJECTED.value) {
        return NativeSpellResult.rejected;
      }
      throw NativeSpellException(_takeError(outError));
    } finally {
      malloc.free(nativeWord);
      _freePendingError(outError);
      calloc.free(outError);
    }
  }

  List<String> suggest(String word) {
    _requireOpen();
    final nativeWord = word.toNativeUtf8();
    final outItems = calloc<ffi.Pointer<ffi.Pointer<ffi.Char>>>();
    final outCount = calloc<ffi.Size>();
    final outError = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final status = bindings.busy_spell_suggest(
        _handle,
        nativeWord.cast(),
        outItems,
        outCount,
        outError,
      );
      if (status == bindings.BusySpellStatus.BUSY_SPELL_ERROR.value) {
        throw NativeSpellException(_takeError(outError));
      }
      return List<String>.generate(
        outCount.value,
        (index) => outItems.value[index].cast<Utf8>().toDartString(),
        growable: false,
      );
    } finally {
      if (outItems.value != ffi.nullptr) {
        bindings.busy_spell_free_suggestions(outItems.value, outCount.value);
      }
      _freePendingError(outError);
      malloc.free(nativeWord);
      calloc.free(outItems);
      calloc.free(outCount);
      calloc.free(outError);
    }
  }

  void add(String word) {
    _requireOpen();
    final nativeWord = word.toNativeUtf8();
    final outError = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final status = bindings.busy_spell_add(
        _handle,
        nativeWord.cast(),
        outError,
      );
      if (status == bindings.BusySpellStatus.BUSY_SPELL_ERROR.value) {
        throw NativeSpellException(_takeError(outError));
      }
    } finally {
      malloc.free(nativeWord);
      _freePendingError(outError);
      calloc.free(outError);
    }
  }

  List<NativeWordRange> tokenize(String prose, {required String language}) {
    _requireOpen();
    final nativeProse = prose.toNativeUtf8();
    final nativeLanguage = language.toNativeUtf8();
    final outRanges = calloc<ffi.Pointer<bindings.BusySpellTokenRange>>();
    final outCount = calloc<ffi.Size>();
    final outError = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final status = bindings.busy_spell_tokenize(
        _handle,
        nativeProse.cast(),
        nativeLanguage.cast(),
        outRanges,
        outCount,
        outError,
      );
      if (status == bindings.BusySpellStatus.BUSY_SPELL_ERROR.value) {
        throw NativeSpellException(_takeError(outError));
      }
      return List<NativeWordRange>.generate(outCount.value, (index) {
        final range = outRanges.value[index];
        return NativeWordRange(
          utf8Start: range.utf8_start,
          utf8End: range.utf8_end,
          characterStart: range.character_start,
          characterEnd: range.character_end,
        );
      }, growable: false);
    } finally {
      if (outRanges.value != ffi.nullptr) {
        bindings.busy_spell_free_token_ranges(outRanges.value);
      }
      _freePendingError(outError);
      malloc.free(nativeProse);
      malloc.free(nativeLanguage);
      calloc.free(outRanges);
      calloc.free(outCount);
      calloc.free(outError);
    }
  }

  void close() {
    if (_handle == ffi.nullptr) return;
    bindings.busy_spell_close(_handle);
    _handle = ffi.nullptr;
  }

  void _requireOpen() {
    if (isClosed) {
      throw const NativeSpellException('Dictionary handle is closed');
    }
  }

  static String _takeError(ffi.Pointer<ffi.Pointer<ffi.Char>> outError) {
    if (outError.value == ffi.nullptr) return 'Unknown native spelling error';
    final message = outError.value.cast<Utf8>().toDartString();
    bindings.busy_spell_free_string(outError.value);
    outError.value = ffi.nullptr;
    return message;
  }

  static void _freePendingError(ffi.Pointer<ffi.Pointer<ffi.Char>> outError) {
    if (outError.value == ffi.nullptr) return;
    bindings.busy_spell_free_string(outError.value);
    outError.value = ffi.nullptr;
  }
}

/// Explicit UTF-8 byte-to-Dart UTF-16 mapping for offsets returned by Pango.
List<int> nativeUtf8BoundaryToUtf16(String text) {
  final mapping = List<int>.filled(utf8.encode(text).length + 1, -1);
  var byteOffset = 0;
  var utf16Offset = 0;
  mapping[0] = 0;
  for (final rune in text.runes) {
    byteOffset += rune <= 0x7f
        ? 1
        : rune <= 0x7ff
        ? 2
        : rune <= 0xffff
        ? 3
        : 4;
    utf16Offset += rune > 0xffff ? 2 : 1;
    mapping[byteOffset] = utf16Offset;
  }
  return mapping;
}

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.code.targetOS != OS.linux) {
      throw UnsupportedError(
        'BusyMark spelling currently targets the GTK Linux application.',
      );
    }
    final pkgConfig = await Process.run('pkg-config', [
      '--cflags',
      'pango',
      'glib-2.0',
    ]);
    if (pkgConfig.exitCode != 0) {
      throw StateError(
        'Pango/GLib development files are required: ${pkgConfig.stderr}',
      );
    }
    final cflags = (pkgConfig.stdout as String)
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();
    final packageName = input.packageName;
    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: '${packageName}_bindings_generated.dart',
      sources: [
        'src/$packageName.cpp',
        'third_party/hunspell/src/hunspell/affentry.cxx',
        'third_party/hunspell/src/hunspell/affixmgr.cxx',
        'third_party/hunspell/src/hunspell/csutil.cxx',
        'third_party/hunspell/src/hunspell/filemgr.cxx',
        'third_party/hunspell/src/hunspell/hashmgr.cxx',
        'third_party/hunspell/src/hunspell/hunspell.cxx',
        'third_party/hunspell/src/hunspell/hunzip.cxx',
        'third_party/hunspell/src/hunspell/phonet.cxx',
        'third_party/hunspell/src/hunspell/replist.cxx',
        'third_party/hunspell/src/hunspell/suggestmgr.cxx',
      ],
      includes: ['src', 'third_party/hunspell/src/hunspell'],
      flags: cflags,
      libraries: ['pango-1.0', 'gobject-2.0', 'glib-2.0'],
      language: .cpp,
      std: 'c++20',
      defines: const {'BUILDING_LIBHUNSPELL': null},
    );
    await cbuilder.run(input: input, output: output);
  });
}

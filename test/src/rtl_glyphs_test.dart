import 'dart:io';

import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  test('navigation glyphs resolve for both reading directions', () {
    expect(BusyMarkGlyphs.backFor(TextDirection.ltr), YaruIcons.arrow_left);
    expect(BusyMarkGlyphs.backFor(TextDirection.rtl), YaruIcons.arrow_right);
    expect(BusyMarkGlyphs.forwardFor(TextDirection.ltr), YaruIcons.go_next);
    expect(BusyMarkGlyphs.forwardFor(TextDirection.rtl), YaruIcons.go_previous);
    expect(
      BusyMarkGlyphs.collapsedTreeArrowFor(TextDirection.ltr),
      YaruIcons.pan_end,
    );
    expect(
      BusyMarkGlyphs.collapsedTreeArrowFor(TextDirection.rtl),
      YaruIcons.pan_start,
    );
  });

  test('editing glyphs resolve for both reading directions', () {
    expect(BusyMarkGlyphs.indentFor(TextDirection.ltr), YaruIcons.indent_more);
    expect(BusyMarkGlyphs.indentFor(TextDirection.rtl), YaruIcons.indent_less);
    expect(BusyMarkGlyphs.outdentFor(TextDirection.ltr), YaruIcons.indent_less);
    expect(BusyMarkGlyphs.outdentFor(TextDirection.rtl), YaruIcons.indent_more);
    expect(BusyMarkGlyphs.undoFor(TextDirection.ltr), YaruIcons.undo);
    expect(BusyMarkGlyphs.undoFor(TextDirection.rtl), YaruIcons.redo);
    expect(BusyMarkGlyphs.redoFor(TextDirection.ltr), YaruIcons.redo);
    expect(BusyMarkGlyphs.redoFor(TextDirection.rtl), YaruIcons.undo);
    expect(
      BusyMarkGlyphs.wordWrapFor(TextDirection.ltr),
      YaruIcons.text_direction_ltr,
    );
    expect(
      BusyMarkGlyphs.wordWrapFor(TextDirection.rtl),
      YaruIcons.text_direction_rtl,
    );
  });

  test('Git branch glyph does not mirror with reading direction', () {
    expect(BusyMarkGlyphs.branch.matchTextDirection, isFalse);
  });

  test('Git action glyphs have native menu equivalents', () {
    expect(
      BusyMarkGlyphs.nativeMenuIconName(BusyMarkGlyphs.refresh),
      'view-refresh-symbolic',
    );
    expect(
      BusyMarkGlyphs.nativeMenuIconName(BusyMarkGlyphs.add),
      'list-add-symbolic',
    );
  });

  test('Arabic and Persian font fallbacks are available in the snap', () {
    expect(BusyMarkTypography.fontFamilyFallback, contains('Noto Sans Arabic'));
    expect(
      BusyMarkTypography.monoFontFamilyFallback,
      contains('Noto Sans Arabic'),
    );
    expect(
      File('snap/snapcraft.yaml').readAsStringSync(),
      contains('fonts-noto-core'),
    );
  });
}

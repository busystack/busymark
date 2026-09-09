import 'dart:convert';
import 'dart:io';
import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css;
import 'export_options.dart';

/// Generated style data and bounded, inert user CSS. No resource is loaded by
/// this reader; custom styles cannot extend the export's resource authority.
abstract final class HtmlExportStyles {
  static Future<String> readCustomCss(HtmlExportOptions options) async {
    options.validateOrThrow();
    final path = options.customCssPath;
    if (path == null) return '';
    try {
      final file = File(path);
      if (await file.length() > HtmlExportOptions.maximumCssBytes) {
        throw const ExportOptionsException([
          ExportOptionIssue('customCssSize'),
        ]);
      }
      // Bound the read as well as the initial stat (the file may be edited).
      final bytes = <int>[];
      await for (final chunk in file.openRead()) {
        if (bytes.length + chunk.length > HtmlExportOptions.maximumCssBytes) {
          throw const ExportOptionsException([
            ExportOptionIssue('customCssSize'),
          ]);
        }
        bytes.addAll(chunk);
      }
      final source = utf8.decode(bytes);
      validateCss(source);
      return source;
    } on ExportOptionsException {
      rethrow;
    } on Object {
      throw const ExportOptionsException([ExportOptionIssue('customCssPath')]);
    }
  }

  static void validateCss(String source) {
    // Disallow escaped identifiers and HTML terminators before CSS tokenization.
    // This intentionally accepts a conservative stylesheet subset, not executable
    // preprocessors, imports, browser extensions, or external dependencies.
    if (source.contains('\\') ||
        source.contains('\u0000') ||
        RegExp(
          r'</style|@import|@charset|expression\s*\(|-moz-binding|behavior\s*:|(?:image|image-set|src|cross-fade|paint)\s*\(',
          caseSensitive: false,
        ).hasMatch(source)) {
      throw const ExportOptionsException([
        ExportOptionIssue('customCssUnsafe'),
      ]);
    }
    final errors = <css_parser.Message>[];
    final sheet = css_parser.parse(source, errors: errors);
    final validator = _CssValidator();
    sheet.visit(validator);
    if (errors.any((e) => e.level == css_parser.MessageLevel.severe) ||
        !validator.safe) {
      throw const ExportOptionsException([
        ExportOptionIssue('customCssUnsafe'),
      ]);
    }
  }

  static String generate(HtmlExportOptions options) {
    options.validateOrThrow();
    const light =
        '--fg:#20242b;--bg:#fff;--heading:#111827;--muted:#4b5563;--border:#d8dee6;--code:#f6f8fa;--inline-code:#f1f3f5;--surface:#f5f7fa;--table:#eef2f6;--warning:#fff6e9;--tip:#f0faf4;--note:#f1f7fd;--status:#713b12;--focus:#a34200;--math-filter:none;--link:var(--accent);';
    const dark =
        '--fg:#e2e7ef;--bg:#15191f;--heading:#f4f6fa;--muted:#b5becc;--border:#46515f;--code:#202731;--inline-code:#28313c;--surface:#202630;--table:#2b3543;--warning:#372b1d;--tip:#1a3025;--note:#1c2b40;--status:#f4c396;--focus:#f2b86b;--math-filter:invert(1) hue-rotate(180deg);--link:color-mix(in srgb,var(--accent) 65%,white);';
    final family = options.bodyTypography == ExportBodyTypography.serif
        ? '"Noto Serif",Georgia,serif'
        : '"Noto Sans",system-ui,sans-serif';
    final palette = options.theme == HtmlExportTheme.dark ? dark : light;
    return ':root{--accent:${options.accentColor};--body-font:$family;--body-size:${options.baseFontSize}px;--content-width:${options.contentMaxWidth}px;color-scheme:${options.theme == HtmlExportTheme.dark ? 'dark' : 'light'};$palette}\n'
        '${options.theme == HtmlExportTheme.automatic ? '@media(prefers-color-scheme:dark){:root{color-scheme:dark;$dark}}' : ''}\n'
        '@media print{:root{color-scheme:light;$light}}';
  }
}

class _CssValidator extends css.Visitor {
  bool safe = true;
  @override
  void visitUriTerm(css.UriTerm node) {
    safe = false;
  }

  @override
  void visitImportDirective(css.ImportDirective node) {
    safe = false;
  }
}

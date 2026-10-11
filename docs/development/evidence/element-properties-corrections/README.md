# Element Properties correction evidence

This directory contains fresh evidence for the four targeted corrections.
See [the acceptance record](../../element-properties-corrections-acceptance.md)
for property mappings, pinned-builder observations and executed commands.

- `reproduction.log`: five focused failures before correction.
- `focused.log`: complete property/session/widget regressions after correction.
- `native-full-result.json`: 161 checks against the final production binary.
- `native-framed-result.json`: 93 inspector checks against that same binary;
  screenshots keep the disposable X11 window fully within its display.
- `native-published.log` and `native-defaults-published.log`: pinned-builder and
  HTML assertions on native-saved projects, including layout reset.
- `saved-source/`: files actually saved by the production workspace; the three
  inspector topics match across full and framed runs byte for byte.
- `published/`: generated HTML from the final fixtures and native-saved sources.
- `*-builder-report.json`: official checks, errors and warnings.
- `analysis.log`, `format.log`, `localization.log`, `security.log`,
  `linux-release.log`, `linux-native-build.log`, `native-package.log` and
  `gtk-dialogs.log`: repository gates. Security produces no text on success.
- `full-suite.log`: 4,374 passed; the one native-display skip is covered above.
- `gates.json`: final gate counts and exit statuses.
- `SHA256SUMS`: artifact hashes; screenshots are original X11 captures.

Inspector screenshots cover nested inspection with the caret elsewhere,
fenced code, Source/Split/Reading, narrow overlay, reopened inline code and
item/admonition IDs, navigation, and module layout default/override/reset.
Additional full-run screenshots cover native authoring in dark mode and RTL
with text scaling. Tooltip-origin and selected-value assertions are recorded
in widget/native results; truncated combo labels retain their full values.

Logs normalize line endings and trailing display whitespace. Saved-source bytes
and screenshot pixels are retained unchanged.

GTK/AT-SPI and frame-transition warnings in native logs did not fail the
functional assertions. The WebKit sandbox override is confined to the
disposable runtime, as described in the acceptance record.

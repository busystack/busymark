# Inline ownership and numbering evidence

These artifacts were produced for the current linked-code/image token and
ordered-list conversion corrections. Prior milestone captures are not reused.

* `inline-reproduction.log` and `numbering-reproduction.log`: four failing
  regressions against the implementation before these corrections.
* `focused.log`: affected authoring, inspector, paragraph/list, collapse and
  admonition suites; `workspace-history.log`: the seven new preservation and
  history cases, including actual buffer Save / close / reopen and one undo.
* `converted-numbering-source.md`: production controller serialization used
  verbatim in both pinned-builder property fixtures and asserted by the tests.
* `builder-*-report.json` and `builder-*-properties*.html`: official fixture
  reports and generated output. Their HTML assertions cover both native and
  converted starts at each nesting level, link code formatting and saved
  image-label escaping, as well as the previous properties/reference cases.
* `unescaped-alt-builder-observation.html`: the initial unescaped image-label
  probe. It shows the pinned builder's filename fallback; the final saved-form
  fixture instead uses BusyMark's actual escaped source and retains literal alt.
* `native-result.json`, `native-workspace.log`, saved inspector documents and
  PNG captures: the production Linux workspace's native controls, save/reopen
  assertions, views, defaults, narrow layout, dark/RTL/scaling and focus checks.
* `native-window-probe.sh`: the isolated X11 launcher; it moves only its own
  window to `(0, 0)` for unclipped screenshots.
* Remaining logs record analysis, formatting, localization, native spelling,
  GTK dialogs, security and Linux builds. The security script exits 0 with no
  output. Logs trim display-only trailing whitespace; screenshots, saved source
  and generated HTML keep their original bytes.

The acceptance record at
[../../element-properties-ownership-numbering-acceptance.md](../../element-properties-ownership-numbering-acceptance.md)
records exact commands, final gate results and fixture resource corrections.
`SHA256SUMS` authenticates the artifacts retained here.

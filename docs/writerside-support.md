# Writerside support

BusyMark's semantic baseline is Writerside **2026.08.0328**, documented by
JetBrains on September 1, 2026. Reading view and native PDF export resolve the
same supported Writerside content.

## Resolved content

- Includes accept XML IDs and Markdown block IDs. A Markdown heading identifies
  its chapter through the next heading of the same or higher level. Snippets
  render at their declaration site in ordinary topics as well as at include sites.
- Blank-line-delimited Markdown inside semantic containers retains formatting
  and original source positions. Fenced code and CDATA remain literal.
- Instance-conditioned globals, local scopes, snippet defaults and include
  arguments resolve before rendering. Include arguments override defaults;
  dependent variable values use the final scope. Escaped percentages and
  `ignore-vars` remain supported.
- Links resolve topic/element titles, separate anchors, summaries and selected
  instance availability. Missing nullable targets render as text.
- Code, diagrams and API samples share guarded source loading. Configured
  directories and paths relative to the originating topic work through includes.
  Referenced code supports line lists/ranges and language-aware symbol selection.
  Symbol selection uses indentation or lexical declaration/delimiter matching;
  unsupported languages, ambiguous declarations and invalid selections produce
  source diagnostics rather than selecting arbitrary text.
- Configured glossary terms, keymap actions and resources produce visible,
  meaningful references. Resource links are checked again before opening.
- Unsaved open dependency buffers participate in preview and reference indexing.

## Presentation and export

| Content | Preview | PDF |
| --- | --- | --- |
| Tabs | Selectable panels, synchronized `group`/`group-key`, arrow/Home/End/Tab navigation | Every panel, with its label |
| Topic switchers | Separate topic-wide `switcher-key` selection | Every variant, with its label |
| Tables | Default first-row headers; header styles, spans, widths, nested content, sticky headers and natural numeric sorting | Structural tables with spans, widths and nested content |
| Shortcuts | Configured action combinations; selectable layouts | Labeled combinations for configured layouts |
| Glossary | Term description tooltip | Term and description footnote |
| Starting pages | Section/card/link groups, titles and descriptions; outside topic content suppressed | Same resolved sections and cards in reading order |
| Summaries | Link/card/web metadata stays out of body text | Metadata stays out of body text |
| API elements | Existing OpenAPI pipeline selects tags, operations, schemas and webhooks; inherited specification references, nested schemas and sample overrides | Same resolved reference and all sample panels |
| Unsupported content | Visible source fallback and source-linked diagnostic | Visible fallback with a warning, or an explicit resolution failure |

Native export resolves local topic links to unique PDF destinations, including
non-heading IDs. Export requires project changes to be saved first.

OpenAPI schema depth controls inline expansion; this editor does not generate
website pages for schema objects. File resources in a PDF remain local links,
so a shared PDF does not bundle those downloadable files automatically.

## Source assistance

Source-editor menus and shortcuts provide **Go to Declaration** (`Ctrl+B`),
**Find Usages** (`Alt+F7`) and **Rename** (`Shift+F6`). Identities include the
module, topic file and symbol, with lexical scope for local variables. Find
Usages searches all indexed topics, including those outside the selected
instance. Rename verifies every source range and stages normal undoable edits in
document tabs. Existing topic-file and instance operations remain available.

Completion uses the current syntax, prefix, reference kind, and referenced topic
to narrow its suggestions. It incorporates JetBrains' official topic XSD and
documented release additions such as sortable tables. A recognized completion
does not necessarily have a semantic renderer; unsupported content remains
visible and produces a diagnostic. Build-profile validation accepts
`<llms-txt>true</llms-txt>` and rejects the old `single-file` form.

Maintainers can find the conformance fixture, schema, and test workflow in
[Writerside verification](development/writerside-verification.md).

## Official references

- [2026.08.0328 release notes](https://www.jetbrains.com/help/writerside/0328.html)
- [Content reuse](https://www.jetbrains.com/help/writerside/reuse-pieces-of-content.html), [variables](https://www.jetbrains.com/help/writerside/variables.html), [links](https://www.jetbrains.com/help/writerside/links-and-references.html), [code](https://www.jetbrains.com/help/writerside/code.html)
- [Tabs](https://www.jetbrains.com/help/writerside/tabs.html), [tables](https://www.jetbrains.com/help/writerside/tables.html), [shortcuts](https://www.jetbrains.com/help/writerside/shortcuts.html), [tooltips](https://www.jetbrains.com/help/writerside/tooltips.html), [resources](https://www.jetbrains.com/help/writerside/downloadable-resources.html)
- [Summaries](https://www.jetbrains.com/help/writerside/summary-elements.html), [starting pages](https://www.jetbrains.com/help/writerside/section-starting-page.html), [API reference](https://www.jetbrains.com/help/writerside/generate-api-reference.html), [API sample overrides](https://www.jetbrains.com/help/writerside/generate-a-single-api-endpoint-reference.html)

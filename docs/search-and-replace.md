# Search and replace

Press **Ctrl+F**, choose **Search**, or use the command palette to search the
open workspace. The search controls use the same query and options for the
active document and workspace results.

## Search options

- **Case sensitive** distinguishes uppercase and lowercase letters.
- **Whole word** excludes matches that are part of a longer word.
- **Regex** treats the query as a Dart regular expression. Invalid expressions
  are reported instead of being searched.

Zero-length regular-expression matches, such as `^`, `$`, or a lookahead that
matches only a position, are not supported for search or replacement.

## Active document

In Source or Split view, the search panel shows the match count and provides
previous and next navigation. Its replacement field supports:

- replacing the current match;
- replacing the current match and moving to the next one; and
- replacing every match in the active document.

These commands edit the current in-memory document. They do not save it
immediately unless autosave is enabled, and they participate in normal undo and
save behavior.

Editor and Reading views show workspace search results and navigate to matching
content, but the active-document replacement controls are available in Source
or Split view.

## Workspace search

The sidebar groups matches by file. Selecting a result opens that document and
navigates to the matching source. Workspace search covers supported text files
already known to the open workspace, including Markdown, Writerside Markdown
and XML topics, trees, configuration, variables, categories, `.gitignore`, and
text resources. Images and unknown file types are excluded.

For open documents, search uses the current editor buffer, including unsaved
changes. For unopened documents, it reads the saved file. Unopened files larger
than 1 MiB or files that cannot be read are listed as skipped. BusyMark
initially limits the displayed results; choose **Show more results** or narrow
the query when the result list is incomplete.

## Replace in the workspace

Workspace replacement is always reviewed:

1. Run a workspace search and choose **Replace in Workspace**.
2. Enter the replacement text and choose **Review replacements**.
3. Review matches grouped by file. Clear individual matches or a whole file to
   exclude them.
4. Choose **Apply replacements**.

With Regex enabled, replacement text supports `$1` through `$99` for numbered
capture groups, `${name}` for named groups, `$&` for the complete match, and
`$$` for a literal dollar sign.

BusyMark rechecks every selected file and open buffer against the reviewed
preview before changing it. Replacements in open documents update their editor
buffers and follow normal save or autosave behavior. Replacements in unopened
documents are written to disk while preserving their encoding and line-ending
format; mixed line endings require you to choose LF or CRLF first.

## Skipped and stale results

A skipped result means BusyMark could not safely apply the reviewed change. A
file may have changed on disk, an open buffer may have changed or closed, the
file may be unreadable or invalid UTF-8, or the preview may have reached its
match limit. Resolve the reported cause and run the search again.

BusyMark does not apply an incomplete preview. If a concurrent change prevents
a safe file transaction, the result identifies the affected path and, when
necessary, the preserved displaced content. Always read the final replacement
summary before continuing.

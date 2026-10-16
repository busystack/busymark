# Search and replace

Search uses one query field in the header and one results sidebar. The compact
native-styled **Search category** menu above the results selects a category.
Normal Files, Topics,
Notes and other browsing remain available when search closes. At narrow window
sizes the same sidebar temporarily overlays the leading side of the document.

| Category | Scope | Shortcut |
| --- | --- | --- |
| Search in Document | Active document’s current buffer | Ctrl+F |
| Search in Workspace | Current local workspace or Notes account | Ctrl+Shift+F |
| Outline | Headings in the current document | Explicit category selection |
| Documents | Names, paths or Notes titles/categories in the active workspace | Ctrl+P |
| Topics | Topics across the current Writerside project, including outside the selected TOC | Ctrl+Shift+T |
| Recent | Chronological document and workspace history | Ctrl+Alt+O |
| Local History | Retained document names, historical paths and revision contents | Find in Local History… |
| Actions | Application commands, including commands without shortcuts | Ctrl+Shift+P |

Categories appear in that order; unavailable categories are omitted. Welcome
provides Recent and Actions. Retained documents behind Welcome are not search
or action targets. There is no combined category or search-results dialog.
**Ctrl+Alt+K** continues to open the existing Keyboard Shortcuts dialog.

The Search icon toggles search and restores the last applicable category.
A category shortcut always opens its designated category and focuses the query;
Ctrl+F always chooses the current document, even after using Actions or opening
a Nextcloud note. Queries remain separate for each category within the window
session. They are not saved to settings or recovery metadata.
The clear button clears the query. Escape closes an open popup first, then
closes search and restores valid editing/navigation focus. Closing search also
restores the previous sidebar destination and visibility for the current workspace.

Up and Down select a result without opening it. Enter activates the highlighted
result; Tab and Shift+Tab traverse controls. Disabled or stale Actions do not
execute a different result. Document formatting actions use the editor selection
captured before the query received focus and reject a changed target.
Save, Export and workspace actions also validate their original resource.
Existing Notes synchronization, folder/file import and export workflows are
available through Actions when their Notes workspace is active.

## Document and workspace search

**Search in Document** searches the live buffer, including unsaved text,
untitled Markdown and individual Nextcloud notes. **Search in Workspace** explicitly
widens the scope to the known local file inventory or active Notes account. An
unrelated external tab does not enlarge the local workspace scope. Text results
are occurrences; filename discovery belongs to Documents.

For Nextcloud workspace text, the existing local Notes index includes cached,
unopened notes and dirty-buffer overlays. Terms use AND; quotes match phrases,
`title:` restricts a term to the title, and `category:` restricts the category.
For example, `"alpha beta" café category:"Work/子"` combines these restrictions.
The Notes workspace provider keeps its phrase and field query language.
Search in Document for Notes uses the normal buffer matching rules.
Documents searches note titles and categories, never note bodies.

Loading/indexing, empty results, errors, skipped files and incomplete results are
shown in the sidebar. **Show more results** extends a bounded search. Activating
a text result validates its resource and source digest before applying exact
coordinates. A changed source requires a fresh result. A Notes result also has
an explicit source-location action for content without a rendered counterpart.
Recovery Search uses this same sidebar with an explicit **Recovery** context and
opens the existing recovery preview. Recovery records stay outside ordinary searches.

## Outline, Topics and Recent

Ctrl+3 and the Outline sidebar button open ordinary Outline without a query or
remembered filter. Choosing Outline in the search category menu filters the same
outline model. Explicit browsing closes search and focuses the Outline tree.

Outline search waits for a query, then displays matching headings in document
order with their levels and ancestor context. It uses the same live model and
validated heading navigation, including unsaved headings. Ordinary Outline owns
its independent tree expansion, selection and section actions; search does not
filter or change that browsing state.
Topics searches source titles, topic IDs, filenames and project-relative paths
across modules. Rows distinguish module ownership and open the actual topic.

Recent is one chronological collection of documents and workspaces, ordered by
last successful opening, with twelve entries in total. Explicit successful
openings move resources to the top. Local topics retain their project owner; individual Notes use the
originating account and stable local note identity, including offline-created
notes that later receive a server ID. Removing or clearing Recent only removes
navigation metadata. Missing resources produce feedback rather than opening a
similarly named document. Removing an account removes its Recent metadata.

On Welcome, **New note** creates one Nextcloud note through the existing offline
creation workflow; **Browse Notes** opens normal Notes navigation. Both identify
the Nextcloud destination. Without an account they enter connection settings;
a successful connection resumes the requested operation, while cancellation or
changing context cancels it. Merely opening settings does not create a note.

## Local History search and browsing

**Find in Local History…** opens the shared header query and sidebar. It searches
retained documents across the application, including closed, renamed, deleted and
previously untitled owners. Names and current or historical paths lead to the
retained timeline. Content results identify an exact revision and timestamp and
open its existing comparison view while keeping search results available.

The History panel’s Find action searches the selected historical document; its
name appears as removable context. Clear that context to search all retained
history. Matching is literal and case-insensitive. An empty History query waits for input.
Search reads retained revisions without recording, restoring, rebinding a live
buffer or substituting a same-named file. Missing revisions report failure.

The Local History sidebar button and its navigation shortcut show the ordinary,
unfiltered timeline. The panel has no private search field or hidden filter.
Returning through Search restores the shared query and selection. Clearing or
pruning retained history invalidates affected results and comparisons.

## Literal matching and initial lists

Document and local-workspace text search use case-insensitive literal substring
matching. `cat` finds `Cat` and `catalog`; `.*` finds those literal characters.
Whitespace is searchable. Source coordinates remain offsets into the original
buffer. Replacement text is literal too: `$1` inserts `$1`, without capture-group
substitution. There are no case, whole-word or regex toggles in the sidebar or
Source/Split controls.

Search in Document, Search in Workspace, Outline, Documents, Topics and Local
History initially show **Enter text to search**. Empty queries do not start
matching, scan the workspace, enumerate topic/document inventories or read History
revision contents. Clearing cancels outstanding work and removes its results and
selection. **No results** appears only after a nonempty query completes without
matches; loading, errors and unavailable resources have distinct feedback.

Recent initially displays its chronological list. Actions initially displays the
command catalog, ordered by availability, localized action name, category and
stable ID. Typing filters either list; unavailable Actions stay discoverable and
cannot execute or redirect Enter to another action.

## Active document

In Source or Split view, the search panel shows the full document match count.
Previous and next navigate every occurrence, including folded and off-screen
content, and wrap only at the document boundaries. Previous without a selected
match selects the final occurrence. The sidebar automatically loads and reveals
the selected result; **Show more results** is not required for this navigation.
Its replacement field supports:

- replacing the current match;
- replacing the current match and moving to the next one; and
- replacing every match in the active document.

These commands edit the current in-memory document. They do not save it
immediately unless autosave is enabled, and they participate in normal undo and
save behavior.

Replace and find next waits for matches in the modified document before moving
the caret. Changing the category, query, document or selection cancels
that pending navigation.

Editor and Reading views show sidebar search results and navigate to matching
content, but the active-document replacement controls are available in Source
or Split view.

## Workspace search

The sidebar shows occurrences with their file and line. Selecting a result opens
that document and navigates to the matching source. Workspace search covers supported text files
already known to the open workspace, including Markdown, Writerside Markdown
and XML topics, trees, configuration, variables, categories, `.gitignore`, and
text resources. Images and unknown file types are excluded.

For open documents, search uses the current editor buffer, including unsaved
changes. For unopened documents, it reads the saved file. Unopened files larger
than 1 MiB or files that cannot be read are listed as skipped. BusyMark
initially limits the displayed results; choose **Show more results** or narrow
the query when the result list is incomplete.

## Replace in the workspace

Workspace replacement applies to supported local workspaces and is always reviewed.
It is unavailable for Notes workspaces and recovery content.

1. Run a workspace search and choose **Replace in Workspace**.
2. Enter the replacement text and choose **Review replacements**.
3. Review matches grouped by file. Clear individual matches or a whole file to
   exclude them.
4. Choose **Apply replacements**.

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

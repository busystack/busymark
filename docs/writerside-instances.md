# Writerside instances

BusyMark treats every registered Writerside instance as a separate output with
its own tree, identity, status, publication path, version, and build settings.
The implementation follows JetBrains' published Writerside formats; it does not
introduce a BusyMark-specific project file.

## Instance actions

Open **Topics**, select an instance from the visible **Instances**
list, and use **TOC actions** to:

- create an instance, either empty or from selected local Markdown files;
- create a non-publishing TOC library;
- edit the selected instance and assign its local icon color; or
- open the authoritative `.tree` file.

The instance editor writes the documented locations:

- `id`, `name`, and `status` in `<instance-profile>`;
- `src`, `version`, and `web-path` in `writerside.cfg` (or `project.ihp`);
- `noindex-content` and `offline-docs` in the configured
  `buildprofiles.xml`.

An empty regular instance is valid. Its first created, linked, or imported topic
becomes its `start-page` when no home page is already set. Empty groups do not
count as topics. A TOC library is written with `is-library="true"` and does not
have output settings of its own.

Changing an instance ID renames its `.tree` file and updates documented project
references, including instance filters, cross-instance `in` references,
instance groups, tree includes, topic title overrides, and build profiles.
BusyMark confirms this refactoring and explicitly warns that publication
scripts are not changed, matching JetBrains' documented behavior.

## Tree representation

The TOC model recognizes the documented `<toc-element>`, `<include>`, and
`<snippet>` hierarchy, including:

- local reusable tree sections;
- `instance` conditions, negation, and registered `@group` conditions;
- `filter` and `use-filter`, including the special `empty` filter;
- cross-instance `ref` and `in` topic references;
- `hidden`, `wip`, `href`, `toc-title`, `origin`, and redirect metadata; and
- library instances whose snippets are visible as reusable sections.

Resolved reusable entries are derived navigation state. Their source remains
the library `.tree` file, so BusyMark does not offer structural move/remove
actions that would mistakenly edit the consuming instance. Invalid, missing,
circular, unsafe, and cross-module includes remain visible and produce a
source-linked diagnostic. Cross-module `origin` references are preserved and
identified, but are not expanded when only one help module is open.

The selected instance and icon colors are local BusyMark preferences. They do
not modify or add undocumented Writerside project metadata.

## TOC authoring and limitations

The native Linux context menus provide topic creation, linking, duplication,
title editing, grouping, sorting, removal, and source navigation. BusyMark's
AI, Git, clipboard and file actions follow the Writerside actions. Reading and
Split remain the document preview modes; there is no separate Writerside
Preview tool window or claim of complete original IDE presentation parity.

- **Add Local Markdown Files** imports selected files as siblings from the
  context menu or as roots from the header. It is absent from **New Child
  Topic**. Imports preserve Markdown bytes and source-relative directories and
  copy referenced local media. Topic IDs must be unique across all configured
  topic roots, including discovered files that cannot be parsed.
- **Duplicate** copies the topic body into a new sibling reference, with a new
  XML root ID where applicable; it does not copy TOC descendants. Newly created
  topics open for editing without changing the global document-view preference.
- **Edit Title** manages the base title, instance override and TOC-only override
  independently. Blank overrides restore inheritance. Markdown base-title edits
  change the top-level H1 and preserve front matter.
- **Group** requires siblings and preserves their source order and subtrees.
  **Sort Child Topics Alphabetically** sorts only immediate children by their
  resolved, case-sensitive titles. Mixed XML children, such as includes alongside
  TOC elements, are rejected rather than discarded.
- **Remove TOC Element** promotes its direct children. File deletion always
  requires **Safe Delete**, including from the Files menu. **Review Usages**
  opens the **Find** sidebar; **Do Refactor** rechecks references before applying
  changes. Unresolved references can require manual edits before deletion.
- **Synchronize TOC and Editor** opens the selected topic or its element source
  when invoked from the tree. From a topic editor it selects the first matching
  resolved file in breadth-first order. From a `.tree` editor, the element's
  explicit ID is matched as a topic reference; missing IDs or unmatched
  references leave the selection unchanged.

Structural edits preserve XML semantics but may reformat the tree. Included
nodes retain the source ownership restrictions described above. BusyMark does
not reproduce the original IDE's unidentified toolbar chevrons or claim its
multi-line tree movement behaves identically to that IDE.

## Topic templates

**Topic from Template** offers Default, Custom and The Good Docs Project
templates, Markdown/XML variants where available, and a rendered preview.
**Save as Template** uses the current topic buffer without changing the topic.
Custom templates and built-in overrides are stored in BusyMark's application
support directory at `writerside/templates.json`. **File and Code Templates**
stages edits until OK; Cancel leaves storage unchanged. These preferences add no
project metadata.

Template substitution is literal: `${TITLE}` and `${ID}` are replaced once,
with XML title escaping where needed. Velocity expressions and tokens inside
replacement values are not executed. The bundled TGDP catalog is pinned;
relative inline links resolve against its source URL, but there is no automatic
catalog update or image download. Ambiguous and reference-style links remain
unchanged. Preview uses BusyMark's renderer.

## Authoritative references

- [Instances](https://www.jetbrains.com/help/writerside/instances.html)
- [writerside.cfg](https://www.jetbrains.com/help/writerside/writerside-cfg.html)
- [Conditional content](https://www.jetbrains.com/help/writerside/conditional-content.html)
- [Reuse topics and sections](https://www.jetbrains.com/help/writerside/reuse-topics.html)
- [Allow search engine indexing](https://www.jetbrains.com/help/writerside/allow-search-engine-indexing.html)
- [Offline documentation](https://www.jetbrains.com/help/writerside/offline-documentation.html)
- [Modules](https://www.jetbrains.com/help/writerside/help-modules.html)

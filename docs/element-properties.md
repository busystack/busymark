# Element Properties

In a Writerside workspace, **Element Properties** follows the active editing
selection in Editor, Source and Split. Open it with the Editor’s existing
properties button, or open and hide it with the command palette command
**Element Properties**.
Reading shows validated values without allowing changes. Ordinary Markdown and
Nextcloud Notes retain their own authoring behavior.

The **Element** selector shows the inspected type; ancestor choices retain their
titles or identifiers. Editable chapters show their heading/title and anchor in
the corresponding controls, without a repeated identity strip. Paragraphs and
references keep a concise excerpt. A container's
properties button lets you inspect that container while leaving the editing
caret where it was. Choose **Topic Properties** in the same selector for the
topic title, document identity and navigation. The first top-level Markdown H1
owns the logical topic title; later H1 headings keep their own element identity.
A missing H1 is reported rather than selecting a paragraph as the title.
Selections spanning several elements show a selection message instead of
editing an arbitrary element.

Text edits commit on Enter, on leaving the field, or before Save. Escape restores
the last committed value. Save, closing the inspector, and changing the document
or view process pending edits first. Invalid drafts stay with their original
element and explain the problem; correct them or use Escape before continuing.
A changed or removed element produces a conflict instead of applying a delayed
edit to a replacement. Property edits use the document's normal undo, recovery
and save history.

Drag the separator to resize the panel. A focused separator also accepts Left
and Right arrows. The inspector starts closed on each launch, including with an
older saved visible preference. BusyMark remembers its preferred width separately
from the navigation sidebar. Once opened, it follows ordinary selection changes.
In a narrow window the panel becomes a dismissible
right-edge overlay. Closing it returns focus to the active editing surface.

## Common controls

Frequent properties appear first; **Advanced** starts closed and contains other
applicable scalar attributes from the supported schema. An authored-settings
indication makes existing overrides discoverable while the section is closed.
Its explicit expansion is retained while editing. Collapsing a section processes
its drafts first. Empty optional text
fields remove their local attribute when committed. Enum controls offer
**Use default**, which removes the local override. Required attributes must keep
a valid value. Suggestions and pickers do not replace legal variable expressions.

| Element | Properties and source mapping |
| --- | --- |
| Topic | Default XML `title` or Markdown H1 text first, followed by read-only **Topic ID** derived from the filename. **Rename topic file** uses the established reviewed refactoring. Topic navigation and Advanced start collapsed. XML Advanced offers root `help-id`, `switcher-label`, `ignore-vars`, `is-library`, and `last-modified`. Markdown document settings offer the confirmed front-matter `switcher-label` mapping separately from heading attributes. |
| Chapter | Default XML `title` or Markdown heading text, an optional element anchor, published collapsibility and applicable initial state. Advanced retains capitalization, switcher, conditions, context-help, literal-variable settings and the Markdown `title` override. |
| Paragraph | Optional element anchor first. Advanced retains `switcher-key`, `filter`, `instance`, `help-id` and `ignore-vars`. These fields can be left absent while writing content. |
| Procedures | Title, element ID, published collapse and initial state. Existing formatted or conditional XML `<title>` children are preserved. |
| Code | Language maps to XML `lang` or a native fence's language. An explicit Markdown `lang` override takes precedence; changing it preserves the original fence language, and resetting it restores that language. **Source file (src)** is one editable field with file selection and removal. Extraction, emphasis, collapse and collapsed title remain separate. The code-language command opens this block’s Language (`lang`) control in the workspace inspector. `include-lines` and `include-symbol` conflict; emphasis counts the displayed snippet after extraction. |
| Definition lists/items | Schema-supported list layouts, list collapse/state, item title and item state override. Literal `inherited` is an authored item override distinct from an absent attribute. |
| Tabs | Container `group` synchronizes tab sets; child `group-key` and title identify individual tabs. Topic switchers are separate. Existing code-block tab groups are preserved. |
| Lists and items | A Markdown attribute line after a blank line belongs to the whole list. An individual item's ID or condition uses semantic `<list>`/`<li>` markup; conversion preserves the other items, checked task states and ordered starts at every nested level and is one undoable edit. An authored list `start` overrides its first Markdown marker. |
| Images | Source and alternative text use the image model; applicable dimensions, style, thumbnail and **Preview image (preview-src)** are available. The preview can be an image thumbnail or an animated GIF’s initial preview; it is separate from the main `src`. Link wrappers and reference syntax survive scalar property edits. Writerside documents a limitation on sizing external images; authored dimensions do not guarantee external-image builder sizing. |
| Includes/references | **Topic (from)**, **Included element (element-id)** and **Help module (origin)** identify the reference. **Element ID (id)** identifies the include itself. Topic, element and module selection use the current project index. Include selection publishes the reference tuple together. `use-filter` belongs to the include; `filter` belongs to source content. Unavailable resolution remains a diagnostic. |
| Links and shortcuts | **Link target (href)** names the destination; **Help module (origin)** selects its originating module. **Action ID (key)** references a keymap action without replacing literal shortcut content. **Keymap help instance (from-keymap-of)** names a help instance, not a file. |
| Topic | XML root properties or the appropriate native heading/front matter; navigation uses `<show-structure>`. XML-only fields do not acquire invented Markdown equivalents. |

The inspector pairs descriptive localized labels with exact Writerside attribute
names. Less-used schema attributes remain under **Advanced**. Empty inactive
controls are hidden; existing authored values remain inspectable and removable.

Topic identity is independent of titles and anchors. Renaming a topic updates its
filename, XML root ID and references through the existing review. Editing a
heading or explicit anchor does not rename a file. Unsaved documents have no
confirmed file identity. A root ID that differs from its filename is diagnosed
and preserved.

A generated chapter anchor appears as **Generated: …** within the anchor row,
with an empty override editor. It remains selectable and wraps when necessary.
Entering an explicit `id` replaces the generated value; clearing it restores the
heading-derived anchor. Focus, inspection and Save do not author that value.
Attribute explanations and full provenance are available in contextual help:
focus the control and press **F1**, or hover over its property row.

Default XML titles edit only the scalar `title` attribute; formatted and conditional
`<title>` children remain intact. Markdown heading text edits its inline content,
while **Title override (title)** under Advanced edits the separate heading
attribute. The override changes the published chapter title without changing the
heading text. **Edit Title...** reuses the established instance/TOC title workflow
for a uniquely identified entry in the selected instance. When a topic has
multiple entries, use the desired entry's existing TOC action rather than
choosing an arbitrary owner.

The pinned builder does not publish attributes on the topic H1. Inline H1
attribute syntax becomes literal title text; the separate-line form is ignored.
Existing authored H1 attributes and the independently editable heading anchor
remain distinct from Topic ID, with this limitation shown in Advanced. BusyMark
does not offer other unverified H1 or YAML properties as XML-root settings.
The same builder ignores instance-specific `<title>` children in Markdown
topics. The existing Edit Title workflow keeps TOC overrides available and
explains that limitation. Existing instance markup is retained and accessible
in Source, with no new unsupported instance override offered. XML instance
titles are supported. Chapter heading attributes, including explicit `title`,
are supported and tested against the published output.

**Filter (filter)** selects reusable content by criteria. **Help instances
(instance)** selects help outputs and accepts legal names, groups, lists,
exclusions and expressions. **Treat variable text literally (ignore-vars)**
enables literal variable-looking text rather than substituting variables.
Unsupported authored attributes remain preserved, are identified in Advanced,
and remain accessible through **Show in Source**. They are not offered as new
supported properties.

For code, the native file chooser updates the same **Source file (src)** field
as direct typing. It stores a reference from the designated snippets directory
when that reference resolves to the chosen file, or a path relative to the topic
within its help module. Unsupported or out-of-module choices explain that the
reference cannot be resolved. Cancelling changes nothing and selecting a file
never changes that file. BusyMark rejects adding a source reference to a block
with authored code; move or explicitly clear that code first. Removing `src`
preserves authored content and other attributes, without copying referenced
file contents into the topic. **Show in Source** processes pending edits and
navigates to the inspected element’s markup. It does not open the code file.

Image source and alt edits can use local Writerside attribute overrides while
retaining a Markdown reference definition and its link wrapper. Explicit empty
alt text stays authored; the pinned builder uses a filename fallback in the
verified image fixtures. Changing a reference link's destination converts only
that occurrence to a direct Markdown link, retaining formatted link text and
leaving the reference definition and other occurrences untouched. The pinned
builder ignores a native link's `href` attribute override, so BusyMark does not
use that override to implement destination changes.

The inspector targets a complete link even when only part of its caption is
formatted. **Show in Source** navigates to the inspected occurrence's markup,
including repeated variable and shortcut references in the same paragraph.
Source selections identify those same occurrences independently.

Backtick-delimited code and escaped literal braces stay inline content, even
when they look like attributes. A link or image's attached attributes belong to
that inline element, including links containing code and image alt text that looks like an attribute block. Ordinary text edits preserve their formatting and attributes. Blockquote-form admonition IDs and conditions are written
after a blank line so the pinned builder assigns them to the admonition alone.

## Published defaults and editor folding

The selector shows **Use default** when no local override is authored. Its row
subtitle shows **Default: Disabled** for a built-in value, or, for example,
**Default: Expanded · Module** for a module setting. An explicit literal value
does not repeat the same effective value. Inherited values and resolved variable
expressions show a concise **Resolved: …** subtitle when the displayed result
differs from the authored selection. Full provenance remains in keyboard and
accessible contextual help. A module `<default-property>` can change
an omitted property's meaning. Unresolved variable expressions remain visible
without being converted to false or to an arbitrary enum. Opening the panel
does not write effective defaults to source.

Definition-list layout uses the same defaults: a module setting of `medium`
appears beneath **Use default** as **Default: Medium (1:2) · Module**,
including after resetting a local override. Origins distinguish an element
override, parent element, module default, and built-in default.

The supported builder is `2026.08.0328`. Its generated output requires effective
`collapsible="true"` for chapters, procedures, code and definition lists, including
state-only chapter forms. Explicit false disables collapse even when a module
supplies true. This pinned behavior differs from the current chapter reference's
state-only description. A source file or XML self-closing syntax does not itself
enable collapse. See [Writerside verification](development/writerside-verification.md#official-builder-conformance)
for the maintained fixtures and generated-HTML checks.

Definition items get collapse from their list. With no module item default,
absent and literal `inherited` item states both follow the list. With a module
item-state default, absence uses that module default while literal `inherited`
uses the list's state.

Opening content locally to edit it does not dirty the document or change its
published initial state. Publishing properties updates the semantic result
without rewriting unrelated local folding preferences.

## Topic navigation

**Use default** removes the unscoped navigation declaration. **All elements with
title** creates an empty `<show-structure/>`. **No navigation** authors
`for="none"`. These have different Writerside meanings. Selecting **Custom
navigation** exposes `for` and `depth` together without inventing source values.
Supported element types are `chapter`, `procedure`,
`tab` and `def`; a depth-only configuration is also supported. The pending
configuration is validated and published as one undoable change. Invalid drafts
block closing or hiding the section. Resetting removes the declaration instead
of serializing an effective default. Multiple or conditional/scoped declarations
remain protected from this single-declaration editor; use Source to edit them.

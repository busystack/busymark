# Element Properties

In a Writerside workspace, **Element Properties** follows the active editing
selection in Editor, Source and Split. Open or hide it with the command palette
command **Element Properties** or the Editor's existing properties button.
Reading shows validated values without allowing changes. Ordinary Markdown and
Nextcloud Notes retain their own authoring behavior.

The identity and ancestor selector refer to the inspected element. A container's
properties button lets you inspect that container while leaving the editing
caret where it was. Choose **Topic Properties** in the same selector for the
topic title, switcher label and navigation. Selections spanning several elements
show a selection message instead of editing an arbitrary element.

Text edits commit on Enter, on leaving the field, or before Save. Escape restores
the last committed value. Save, closing the inspector, and changing the document
or view process pending edits first. Invalid drafts stay with their original
element and explain the problem; correct them or use Escape before continuing.
A changed or removed element produces a conflict instead of applying a delayed
edit to a replacement. Property edits use the document's normal undo, recovery
and save history.

Drag the separator to resize the panel. A focused separator also accepts Left
and Right arrows. BusyMark remembers visibility and preferred width separately
from the navigation sidebar. In a narrow window the panel becomes a dismissible
right-edge overlay. Closing it returns focus to the active editing surface.

## Common controls

Frequent properties appear first; **Advanced** starts closed and contains other
applicable scalar attributes from the supported schema. Empty optional text
fields remove their local attribute when committed. Enum controls offer
**Use default**, which removes the local override. Required attributes must keep
a valid value. Suggestions and pickers do not replace legal variable expressions.

| Element | Properties and source mapping |
| --- | --- |
| Chapters and procedures | Title, ID, published collapse and initial state. Native Markdown heading text and its explicit `title` override remain separate. Existing formatted or conditional XML `<title>` children are preserved. |
| Code | Language maps to XML `lang` or a native fence's language. An explicit Markdown `lang` override takes precedence; changing it preserves the original fence language, and resetting it restores that language. Source mode/reference, extraction, emphasis, collapse and collapsed title remain separate. `include-lines` and `include-symbol` conflict; emphasis counts the displayed snippet after extraction. |
| Definition lists/items | Schema-supported list layouts, list collapse/state, item title and item state override. Literal `inherited` is an authored item override distinct from an absent attribute. |
| Tabs | Container `group` synchronizes tab sets; child `group-key` and title identify individual tabs. Topic switchers are separate. Existing code-block tab groups are preserved. |
| Lists and items | A Markdown attribute line after a blank line belongs to the whole list. An individual item's ID or condition uses semantic `<list>`/`<li>` markup; conversion preserves the other items, checked task states and ordered starts at every nested level and is one undoable edit. An authored list `start` overrides its first Markdown marker. |
| Images | Source and alternative text use the image model; applicable dimensions, style, thumbnail and preview reference are available. Link wrappers and reference syntax survive scalar property edits. Writerside documents a limitation on sizing external images; authored dimensions do not guarantee external-image builder sizing. |
| Includes/references | Topic, element and module selection use the current project index. Include selection publishes the reference tuple together. `use-filter` belongs to the include; `filter` belongs to source content. Unavailable resolution remains a diagnostic. |
| Topic | XML root properties or the appropriate native heading/front matter; navigation uses `<show-structure>`. XML-only fields do not acquire invented Markdown equivalents. |

For code, selecting a file never changes that file. BusyMark rejects adding a
source reference to nonempty inline code; move or explicitly clear the code first.
Removing a source reference preserves any existing inline content and other
attributes. Existing malformed or unsupported content stays protected and can
be reached with the inspector's **Source** action.

Image source and alt edits can use local Writerside attribute overrides while
retaining a Markdown reference definition and its link wrapper. Explicit empty
alt text stays authored; the pinned builder uses a filename fallback in the
verified image fixtures. Changing a reference link's destination converts only
that occurrence to a direct Markdown link, retaining formatted link text and
leaving the reference definition and other occurrences untouched. The pinned
builder ignores a native link's `href` attribute override, so BusyMark does not
use that override to implement destination changes.

Backtick-delimited code and escaped literal braces stay inline content, even
when they look like attributes. A link or image's attached attributes belong to
that inline element, including links containing code and image alt text that looks like an attribute block. Ordinary text edits preserve their formatting and attributes. Blockquote-form admonition IDs and conditions are written
after a blank line so the pinned builder assigns them to the admonition alone.

## Published defaults and editor folding

**Use default — Expanded**, for example, means no local override is authored and
the effective value is expanded. Hover the control for its origin. A module
`<default-property>` can change an omitted property's meaning. Unresolved
variable expressions remain visible without being converted to false or to an
arbitrary enum. Opening the panel does not write effective defaults to source.

Definition-list layout uses the same defaults: a module setting of `medium`
appears as **Use default — Medium (1:2)**, including after resetting a local
override. Hover the control to see whether the value comes from the element,
module, or built-in default.

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
`for="none"`. These have different Writerside meanings. Custom `for` and `depth`
values edit the same declaration. Multiple or conditional/scoped declarations
remain protected from this single-declaration editor; use Source to edit them.

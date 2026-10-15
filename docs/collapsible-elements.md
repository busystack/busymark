# Writerside collapsible elements

BusyMark renders Writerside collapsible chapters, procedures, code blocks, and
definition lists in Writerside Markdown topics and XML `.topic` files. These
extensions are not interpreted in ordinary Markdown workspaces.

## Chapters

In Writerside Markdown, add the attribute to a heading:

```markdown
## Advanced details {collapsible="true"}

This section is hidden until it is expanded.
```

In semantic markup, use a chapter element:

```xml
<chapter title="Advanced details" collapsible="true">
  <p>This section is hidden until it is expanded.</p>
</chapter>
```

The collapsible chapter owns the content up to the next heading at the same or
a higher level.

## Procedures and code

Procedures use the semantic attribute:

```xml
<procedure title="Build the project" collapsible="true">
  <step>Compile the sources.</step>
  <step>Package the result.</step>
</procedure>
```

For a Markdown code fence, put its attribute block directly after the fence:

````markdown
```kotlin
data class Person(val name: String)
```
{collapsible="true" collapsed-title="Person.kt"}
````

Semantic `code-block` elements support the same `collapsible` and
`collapsed-title` attributes. Without `collapsed-title`, BusyMark uses the
first non-empty code line as the collapsed label.

## Definition lists

Set `collapsible="true"` on the definition list. Each definition becomes an
independent disclosure item:

```xml
<deflist collapsible="true">
  <def title="Open initially" default-state="expanded"><p>Text.</p></def>
  <def title="Closed initially" default-state="collapsed"><p>Text.</p></def>
</deflist>
```

Published state follows authored values, module defaults and the pinned builder's
element-specific rules. Inspect **Element Properties** to see authored overrides
and effective defaults; local editor expansion is separate and source-neutral.
See [Element Properties](element-properties.md) for state-only forms, explicit
false and definition-item inheritance verified against builder `2026.08.0328`.

The syntax follows JetBrains' [Writerside collapsible-elements documentation](https://www.jetbrains.com/help/writerside/collapsible-elements.html).

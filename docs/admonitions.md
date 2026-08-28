# Writerside admonitions

BusyMark recognizes Writerside tips, notes, warnings, and neutral quote blocks
in Writerside Markdown and XML `.topic` files.

In Writerside Markdown, a blockquote is a tip by default:

```markdown
> Try the safer command first.
```

Use a trailing `style` attribute for the other supported presentations:

```markdown
> This limitation applies to all releases.
{style="note"}

> This operation deletes existing data.
{style="warning"}

> Documentation is a product feature.
{style="quote"}
```

BusyMark also recognizes Writerside semantic elements in Markdown and XML
topics:

```xml
<tip>Try the safer command first.</tip>
<note>This limitation applies to all releases.</note>
<warning>This operation deletes existing data.</warning>
<quote>Documentation is a product feature.</quote>
```

The WYSIWYG editing toolbar shows an **Admonition** menu for Writerside
Markdown topics. Select **Tip**, **Note**, **Warning**, or **Quote** to convert
the active block or selected blocks. BusyMark emits Writerside-compatible
blockquote syntax and preserves existing semantic-element syntax when changing
the type of an element-based admonition.

Ordinary Markdown blockquotes remain ordinary quotes. BusyMark does not apply
Writerside's default-tip behavior outside a Writerside Markdown topic.

The supported forms follow JetBrains' [Writerside admonition documentation](https://www.jetbrains.com/help/writerside/admonitions.html).

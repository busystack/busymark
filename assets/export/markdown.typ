// BusyMark Markdown PDF renderer. All document data enters through JSON;
// Markdown text is never evaluated as Typst source.
#let data = json("document.json")
#let document-metadata = data.metadata
#let options = data.options

#set document(
  title: document-metadata.title,
  author: if document-metadata.author == "" { () } else { (document-metadata.author,) },
  description: document-metadata.description,
  keywords: document-metadata.keywords,
)
#assert(data.schemaVersion == 2, message: "Unsupported export payload")
#let typography = options.typography
#let geometry = options.page
#let margins = geometry.marginsPt
#let running-visible() = options.showHeaderFooterOnFirstPage or counter(page).get().first() > 1
#let number-position = if options.pageNumbers == "bottomLeft" { left } else if options.pageNumbers == "bottomRight" { right } else { center }
#set page(
  width: geometry.widthPt * 1pt,
  height: geometry.heightPt * 1pt,
  margin: (top: margins.top * 1pt, right: margins.right * 1pt, bottom: margins.bottom * 1pt, left: margins.left * 1pt),
  // Logical page numbering also supplies native outline page references.
  // First-page visibility belongs to the running footer, never the numbering
  // function: an outline on that page must still show its destination numbers.
  numbering: "1",
  number-align: number-position + bottom,
  header: if options.header == "none" { none } else { context { if running-visible() { text(document-metadata.title) } } },
  footer: if options.footer == "none" and options.pageNumbers == "off" { none } else { context {
    if running-visible() {
      // Native page footer content combines title and counter without overlap.
      if options.footer == "documentTitle" { align(center, text(document-metadata.title)) }
      if options.pageNumbers != "off" { align(number-position, counter(page).display("1")) }
    }
  } },
)
#set text(
  font: typography.bodyFont,
  fallback: true,
  size: typography.bodySizePt * 1pt,
  lang: document-metadata.language.split("-").first(),
  region: if document-metadata.language.split("-").len() == 2 and document-metadata.language.split("-").last().len() == 2 { document-metadata.language.split("-").last() } else { none },
)
#set par(leading: 0.68em)
#set heading(numbering: if options.content.numberHeadings { "1.1" } else { none })
#show heading: it => {
  set text(size: typography.headingSizesPt.at(calc.min(it.level, 6) - 1) * 1pt, weight: "bold")
  it
}
#show raw: set text(font: typography.codeFont, size: typography.codeSizePt * 1pt)
#show link: set text(fill: rgb(options.accentColor))

#let value-or(item, key, default) = item.at(key, default: default)

#let render-math(item, inline: false) = {
  let asset = value-or(item, "asset", "")
  let source = value-or(item, "text", "")
  if asset == "" {
    if inline { raw(source) } else {
      block(
        width: 100%,
        fill: rgb("fff4e5"),
        inset: 7pt,
        radius: 3pt,
        raw(source, block: true),
      )
    }
  } else {
    let natural-width = float(value-or(item, "width", "1")) * 1pt
    let natural-height = float(value-or(item, "height", "1")) * 1pt
    let depth = float(value-or(item, "depth", "0")) * 1pt
    if inline {
      box(
        width: natural-width,
        height: natural-height,
        baseline: depth,
        image(
          asset,
          width: natural-width,
          height: natural-height,
          fit: "contain",
          alt: source,
        ),
      )
    } else {
      block(
        width: 100%,
        above: 0.8em,
        below: 0.8em,
        breakable: false,
        align(center, layout(size => image(
          asset,
          width: calc.min(natural-width, size.width),
          fit: "contain",
          alt: source,
        ))),
      )
    }
  }
}

#let render-inlines(items) = {
  for item in items {
    let kind = item.kind
    let children = value-or(item, "children", ())
    let body = if children.len() > 0 {
      render-inlines(children)
    } else {
      text(value-or(item, "text", ""))
    }

    if kind == "text" {
      body
    } else if kind == "strong" {
      strong(body)
    } else if kind == "emphasis" {
      emph(body)
    } else if kind == "underline" {
      underline(body)
      let summary = value-or(item, "summary", "")
      if summary != "" { footnote(text(summary)) }
    } else if kind == "strikethrough" {
      strike(body)
    } else if kind == "code" {
      raw(value-or(item, "text", ""))
    } else if kind == "link" {
      let destination = value-or(item, "destination", "")
      if destination == "" {
        body
      } else if destination.starts-with("#") {
        link(label(destination.slice(1)), body)
      } else {
        link(destination, body)
      }
    } else if kind == "image" {
      let asset = value-or(item, "asset", "")
      let alt = value-or(item, "alt", "")
      if asset == "" {
        emph(text(if alt == "" { "[Image unavailable]" } else { "[Image: " + alt + "]" }))
      } else {
        image(asset, width: 1.25em, height: 1.25em, fit: "contain", alt: alt)
      }
    } else if kind == "math" {
      render-math(item, inline: true)
    } else if kind == "softBreak" {
      text(" ")
    } else if kind == "hardBreak" {
      linebreak()
    } else {
      body
    }
  }
}

#let render-display-image(item) = {
  let asset = value-or(item, "asset", "")
  let alt = value-or(item, "alt", "")
  if asset == "" {
    emph(text(if alt == "" { "[Image unavailable]" } else { "[Image: " + alt + "]" }))
  } else {
    layout(size => image(
      asset,
      width: 100%,
      height: 72% * size.height,
      fit: "contain",
      alt: alt,
    ))
  }
}

#let render-table(block-data, render) = {
  let rows = value-or(block-data, "children", ())
  if rows.len() == 0 {
    none
  } else {
    let column-count = value-or(block-data, "columnCount", calc.max(..rows.map(row => value-or(row, "children", ()).len())))
    let cells = ()
    for row in rows {
      let is-header = value-or(row, "header", false)
      let row-cells = ()
      for cell in value-or(row, "children", ()) {
        let cell-body = [#render-inlines(value-or(cell, "inlines", ()))#for child in value-or(cell, "children", ()) { render(child) }]
        let alignment = value-or(cell, "align", "left")
        let cell-align = if alignment == "center" {
          center
        } else if alignment == "right" {
          right
        } else {
          left
        }
        row-cells.push(table.cell(
          align: cell-align,
          x: value-or(cell, "x", auto),
          y: value-or(cell, "y", auto),
          colspan: value-or(cell, "colspan", 1),
          rowspan: value-or(cell, "rowspan", 1),
          fill: if value-or(cell, "header", is-header) { rgb("f1f3f5") } else { none },
          if value-or(cell, "header", is-header) { strong(cell-body) } else { cell-body },
        ))
      }
      if is-header {
        cells.push(table.header(..row-cells))
      } else {
        for cell in row-cells { cells.push(cell) }
      }
    }
    table(
      columns: if value-or(block-data, "columnWidths", ()).len() == column-count {
        value-or(block-data, "columnWidths", ()).map(width => if width != "" { float(width) * 0.75pt } else if value-or(block-data, "fixedColumns", false) { 1fr } else { auto })
      } else { column-count },
      inset: 5pt,
      stroke: 0.5pt + rgb("c8cdd4"),
      ..cells,
    )
  }
}

#let render-list(block-data, render) = {
  let list-type = value-or(block-data, "listType", "bullet")
  let items = value-or(block-data, "children", ()).map(item => {
    let task = value-or(item, "task", none)
    if task != none {
      box(width: 1.35em, text(if task { "☑" } else { "☐" }))
    }
    render-inlines(value-or(item, "inlines", ()))
    let nested = value-or(item, "children", ())
    if nested.len() > 0 {
      for nested-block in nested { render(nested-block) }
    }
  })
  if list-type == "none" {
    for item in items { block(item) }
  } else if value-or(block-data, "ordered", false) {
    if list-type == "alpha-lower" {
      enum(
        start: value-or(block-data, "start", 1),
        numbering: "a.",
        ..items,
      )
    } else {
      enum(start: value-or(block-data, "start", 1), ..items)
    }
  } else {
    list(..items)
  }
}

#let render-block(block-data) = {
  let kind = block-data.kind
  let inlines = value-or(block-data, "inlines", ())
  let children = value-or(block-data, "children", ())
  let block-anchor = value-or(block-data, "anchor", "")
  if block-anchor != "" { [#metadata(block-anchor) #label(block-anchor)] }
  if kind == "heading" {
    let element = heading(
      level: value-or(block-data, "level", 1),
      outlined: true,
      render-inlines(inlines),
    )
    let anchor = value-or(block-data, "id", "")
    if anchor == "" { element } else { [#element #label(anchor)] }
  } else if kind == "paragraph" {
    par(render-inlines(inlines))
  } else if kind == "code" {
    let language = value-or(block-data, "language", "")
    block(
      width: 100%,
      fill: rgb("f4f5f7"),
      inset: 8pt,
      radius: 3pt,
      if language == "" {
        raw(value-or(block-data, "text", ""), block: true)
      } else {
        raw(value-or(block-data, "text", ""), block: true, lang: language)
      },
    )
  } else if kind == "math" {
    render-math(block-data)
  } else if kind == "list" {
    render-list(block-data, render-block)
  } else if kind == "admonition" {
    let style = value-or(block-data, "style", "note")
    let fill = if style == "warning" {
      rgb("fff4d6")
    } else if style == "tip" {
      rgb("e8f7ed")
    } else {
      rgb("eaf2fb")
    }
    block(
      width: 100%,
      fill: fill,
      inset: 9pt,
      radius: 4pt,
      if children.len() > 0 {
        for child in children { render-block(child) }
      } else {
        render-inlines(inlines)
      },
    )
  } else if kind == "blockquote" {
    quote(
      block: true,
      if children.len() > 0 {
        for child in children { render-block(child) }
      } else {
        render-inlines(inlines)
      },
    )
  } else if kind == "thematicBreak" {
    block(above: 0.8em, below: 0.8em, line(length: 100%, stroke: 0.6pt + rgb("aeb4bc")))
  } else if kind == "image" {
    let image-body = {
      for item in inlines {
        if item.kind == "image" {
          render-display-image(item)
        } else {
          render-inlines((item,))
        }
      }
    }
    let destination = value-or(block-data, "destination", "")
    align(center, if destination == "" {
      image-body
    } else if destination.starts-with("#") {
      link(label(destination.slice(1)), image-body)
    } else {
      link(destination, image-body)
    })
  } else if kind == "video" {
    let asset = value-or(block-data, "asset", "")
    let source = value-or(block-data, "source", "")
    let body = if asset == "" {
      block(
        width: 100%,
        fill: rgb("f7f7f8"),
        inset: 10pt,
        radius: 3pt,
        align(center, emph("Video: " + source)),
      )
    } else {
      block(
        breakable: false,
        align(center, image(asset, width: 100%, fit: "contain", alt: "Video")),
      )
    }
    block(
      above: 0.8em,
      below: 0.8em,
      if source.starts-with("https://") { link(source, body) } else { body },
    )
  } else if kind == "table" {
    render-table(block-data, render-block)
  } else if kind == "visualization" {
    let asset = value-or(block-data, "asset", "")
    let alt = value-or(block-data, "alt", "Diagram")
    if asset == "" {
      emph(text("[" + alt + " unavailable]"))
    } else {
      block(
        above: 0.8em,
        below: 0.8em,
        breakable: false,
        align(center, layout(size => image(
          asset,
          width: 100%,
          height: 70% * size.height,
          fit: "contain",
          alt: alt,
        ))),
      )
    }
  } else if kind == "openApiReference" {
    block(
      above: 0.8em,
      below: 0.8em,
      for child in children { render-block(child) },
    )
  } else if kind == "rawText" {
    block(
      width: 100%,
      fill: rgb("f7f7f8"),
      inset: 7pt,
      radius: 3pt,
      raw(value-or(block-data, "text", ""), block: true),
    )
  } else if kind == "group" {
    for child in children { render-block(child) }
  } else {
    render-inlines(inlines)
  }
}

#if options.content.includeToc {
  outline(depth: options.content.tocDepth)
  v(1em)
}

#for block-data in data.blocks { render-block(block-data) }

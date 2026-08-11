// BusyMark Markdown PDF renderer. All document data enters through JSON;
// Markdown text is never evaluated as Typst source.
#let data = json("document.json")
#let metadata = data.metadata
#let options = data.options

#set document(
  title: metadata.title,
  author: if metadata.author == "" { () } else { (metadata.author,) },
  description: metadata.description,
  keywords: metadata.keywords,
)
#set page(
  paper: options.paper,
  flipped: options.landscape,
  margin: (
    x: options.marginHorizontalPt * 1pt,
    y: options.marginVerticalPt * 1pt,
  ),
  numbering: if options.pageNumbers { "1" } else { none },
  number-align: center + bottom,
)
#set text(
  fallback: true,
  size: 10.5pt,
  lang: metadata.language,
)
#set par(leading: 0.68em)
#set heading(numbering: none)
#show heading.where(level: 1): set text(size: 22pt, weight: "bold")
#show heading.where(level: 2): set text(size: 17pt, weight: "bold")
#show heading.where(level: 3): set text(size: 13.5pt, weight: "bold")
#show heading.where(level: 4): set text(size: 11.5pt, weight: "bold")
#show link: set text(fill: rgb("2563a5"))

#let value-or(item, key, default) = item.at(key, default: default)

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

#let render-table(block-data) = {
  let rows = value-or(block-data, "children", ())
  if rows.len() == 0 {
    none
  } else {
    let column-count = calc.max(..rows.map(row => value-or(row, "children", ()).len()))
    let cells = ()
    for row in rows {
      let is-header = value-or(row, "header", false)
      let row-cells = ()
      for cell in value-or(row, "children", ()) {
        let cell-body = render-inlines(value-or(cell, "inlines", ()))
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
          if is-header { strong(cell-body) } else { cell-body },
        ))
      }
      for ignored in range(value-or(row, "children", ()).len(), column-count) {
        row-cells.push(none)
      }
      if is-header {
        cells.push(table.header(..row-cells))
      } else {
        for cell in row-cells { cells.push(cell) }
      }
    }
    table(
      columns: column-count,
      inset: 5pt,
      stroke: 0.5pt + rgb("c8cdd4"),
      fill: (x, y) => if y == 0 { rgb("f1f3f5") } else { none },
      ..cells,
    )
  }
}

#let render-list(block-data, render) = {
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
  if value-or(block-data, "ordered", false) {
    enum(start: value-or(block-data, "start", 1), ..items)
  } else {
    list(..items)
  }
}

#let render-block(block-data) = {
  let kind = block-data.kind
  let inlines = value-or(block-data, "inlines", ())
  let children = value-or(block-data, "children", ())
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
  } else if kind == "list" {
    render-list(block-data, render-block)
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
  } else if kind == "table" {
    render-table(block-data)
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

#for block-data in data.blocks { render-block(block-data) }

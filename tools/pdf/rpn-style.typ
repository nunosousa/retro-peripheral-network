// Layout of the RPN PDFs: A4 landscape, document-control header and footer,
// per-document contents and breakable tables (column widths are chosen by
// rpn-reader.lua). Only fonts embedded in Typst are used (build-pdf.sh passes
// --ignore-system-fonts), so the committed PDFs build identically anywhere.
// The rpn-* functions below are called from the markup emitted by
// rpn-reader.lua.

#let project = "Retro Peripheral Network"

#let accent = rgb("#1f3a5f")
#let link-color = rgb("#1a5fb4")
#let muted = luma(105)
#let rule-color = luma(190)
#let header-fill = rgb("#e4eaf1")
#let code-fill = luma(246)

#let body-font = "Libertinus Serif"
#let mono-font = "DejaVu Sans Mono"

// Needed by pandoc's Typst writer for horizontal rules.
#let horizontalrule = line(length: 100%, stroke: 0.5pt + rule-color)

#let parse-date(value) = {
  let m = value.match(regex("^(\d{4})-(\d{2})-(\d{2})$"))
  if m == none { auto } else {
    let (y, mo, d) = m.captures.map(int)
    datetime(year: y, month: mo, day: d)
  }
}

#let sep = [#h(0.45em)·#h(0.45em)]

// Metadata of the last document started on or before the current page;
// none on the cover of the combined set.
#let doc-on-page() = {
  let started = query(<rpn-doc>).filter(m => m.location().page() <= here().page())
  if started.len() > 0 { started.last().value }
}

#let doc-starts-on-page() = {
  query(<rpn-doc>).any(m => m.location().page() == here().page())
}

#let page-header = context {
  let doc = doc-on-page()
  if doc != none and not doc-starts-on-page() {
    set text(size: 9pt, fill: muted)
    block(
      width: 100%,
      inset: (bottom: 4pt),
      stroke: (bottom: 0.5pt + rule-color),
      grid(
        columns: (1fr, auto),
        align: (left + bottom, right + bottom),
        [#text(weight: "bold", fill: accent, doc.id)#sep#doc.title],
        [Revision #doc.revision#sep#doc.date],
      ),
    )
  }
}

#let page-footer = context {
  let doc = doc-on-page()
  set text(size: 8.5pt, fill: muted)
  block(
    width: 100%,
    inset: (top: 4pt),
    stroke: (top: 0.5pt + rule-color),
    grid(
      columns: (1fr, auto),
      column-gutter: 2em,
      align: (left + top, right + top),
      if doc == none { project } else [#project#sep#doc.status],
      [Page #counter(page).display() of #counter(page).final().first()],
    ),
  )
}

#let eyebrow = text(size: 10pt, weight: "semibold", fill: muted, tracking: 0.12em, upper(project))

#let contents-title(body) = block(below: 1.2em, text(size: 16pt, weight: "bold", fill: accent, body))

#let contents(target, first-level) = {
  // Internal links are coloured in running text but not in the contents.
  show link: set text(fill: black)
  show outline.entry.where(level: first-level): it => {
    v(0.5em, weak: true)
    strong(it)
  }
  columns(2, gutter: 14mm, outline(
    title: none,
    target: target,
    indent: n => (n - first-level + 1) * 1.6em,
  ))
}

// Cover and contents of the combined set, built from the documents' metadata.
#let rpn-set-front() = {
  v(6mm)
  eyebrow
  v(1mm)
  text(size: 28pt, weight: "bold", fill: accent)[Specification set]
  v(1mm)
  line(length: 100%, stroke: 1.2pt + accent)
  v(4mm)
  context {
    let docs = query(<rpn-doc>).map(m => m.value)
    table(
      columns: (auto, auto, auto, auto, 1fr),
      table.header([Document ID], [Title], [Revision], [Date], [Status]),
      table.hline(),
      ..docs.map(d => (d.id, d.title, d.revision, d.date, d.status)).flatten(),
    )
  }
  [Links between these documents point within this volume. Each document
  is also published separately with the same content.]
  pagebreak()
  contents-title[Contents]
  contents(heading.where(level: 1).or(heading.where(level: 2)), 1)
}

#let rpn-doc-start(anchor: "", id: "", title: "", revision: "", date: "", status: []) = {
  pagebreak(weak: true)
  [#metadata((id: id, title: title, revision: revision, date: date, status: status)) <rpn-doc>]
  v(6mm)
  eyebrow
  v(1mm)
  [#heading(level: 1, title) #label(anchor)]
  text(size: 13pt, fill: muted)[#id#sep Revision #revision]
  v(1mm)
  line(length: 100%, stroke: 1.2pt + accent)
  v(4mm)
}

#let rpn-doc-contents(start: "", end: "") = {
  pagebreak(weak: true)
  contents-title[Contents]
  let sections = heading.where(level: 2).or(heading.where(level: 3))
  contents(sections.after(label(start)).before(label(end)), 2)
  pagebreak(weak: true)
}

#let rpn-doc-end(anchor) = [#metadata(none) #label(anchor)]

#let rpn-setup(title: none, date: "", body) = {
  set document(title: title, author: project, date: parse-date(date))
  set page(
    paper: "a4",
    flipped: true,
    margin: (x: 18mm, top: 22mm, bottom: 20mm),
    header: page-header,
    footer: page-footer,
  )
  set text(font: body-font, size: 10.5pt, lang: "en", region: "GB")
  set par(justify: true, leading: 0.62em, spacing: 1.05em)
  set list(indent: 0.4em, body-indent: 0.5em)
  set enum(indent: 0.4em, body-indent: 0.5em)

  show link: set text(fill: link-color)

  show heading: set text(fill: accent, weight: "bold")
  show heading.where(level: 1): it => block(below: 0.5em, text(size: 28pt, it.body))
  show heading.where(level: 2): set text(size: 15pt)
  show heading.where(level: 2): set block(above: 1.9em, below: 0.9em)
  show heading.where(level: 2): it => block(
    width: 100%,
    sticky: true,
    inset: (bottom: 4pt),
    stroke: (bottom: 0.6pt + accent),
    it.body,
  )
  show heading.where(level: 3): set text(size: 12.5pt)
  show heading.where(level: 3): set block(above: 1.5em, below: 0.75em)
  show heading.where(level: 4): set text(size: 11pt)

  set table(
    inset: (x: 5pt, y: 4pt),
    stroke: (_, y) => if y > 0 { (bottom: 0.4pt + rule-color) },
    fill: (_, y) => if y == 0 { header-fill },
  )
  set table.hline(stroke: 0.8pt + accent)
  show table: set text(size: 9pt)
  show table: set par(justify: false, leading: 0.5em)
  show table: set block(above: 1.1em, below: 1.3em)
  show table.cell.where(y: 0): strong

  show raw: set text(font: mono-font)
  show raw.where(block: true): set text(size: 8.5pt)
  show raw.where(block: true): set par(justify: false)
  // Keep diagrams on one page; only very long listings may break.
  show raw.where(block: true): it => block(
    width: 100%,
    breakable: it.text.split("\n").len() > 40,
    fill: code-fill,
    stroke: 0.5pt + rule-color,
    radius: 2pt,
    inset: (x: 8pt, y: 7pt),
    it,
  )
  // A highlight (unlike a box) lets long inline code wrap at its spaces.
  show raw.where(block: false): highlight.with(
    fill: luma(236),
    top-edge: "ascender",
    bottom-edge: "descender",
    extent: 1pt,
    radius: 1.5pt,
  )
  // Keep identifiers such as SRS-IN-011 on one line (boxing keeps the real
  // hyphen, so the PDF text stays searchable).
  show raw.where(block: false): it => {
    show regex("\S+-\S+"): box
    it
  }

  body
}

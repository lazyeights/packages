#let pars = state("paragraphs", 1)
#let n- = context [
  #let num = pars.get()
  #pars.update(n => n + 1)
  #num. #h(2em)
]

#let shadow-box(..args, content,
    fill: white,
    stroke: 1pt + black,
    dx: 3pt,
    dy: 3pt,
    ) = {
    box(layout(size => {
      let content = box(fill: fill,  width: size.width, stroke: stroke, ..args, content)
      let (height, ) = measure(content)
      let shadow = box(fill: silver, width: size.width, height: height, ..args)
       place(dx:dx, dy:dy, shadow)
       content
    })) 
}

#let single-spaced(body) = {
  set par(leading: .17em)
  body
}

#let double-spaced(body) = {
  set par(leading: 1.33em)
  body
}  

#let normal-dotm(
  body,
  base-font-family: "Linux Libertine",
  base-font-size: 12pt,
  body-line-spacing: "single",
  footnote-font-size: 10pt,
  footnote-line-spacing: "single",
  list-line-spacing: "single",
  justified: true,
) = {

  // Normalize text placement
  set text(
    font: base-font-family,
    size: base-font-size, 
    top-edge: 1em, 
    bottom-edge: "baseline"
  )

  // Paragraph spacing (single or double-spacing)
  let body-leading = .17em
  if body-line-spacing =="double" {
    body-leading = 1.33em
  }
  set par(leading: body-leading, justify: justified, first-line-indent: 0.5in)
  show par: set block(above: 1.33em, below: 1.33em)

  let list-leading = .17em
  if list-line-spacing =="double" {
    list-leading = 1.33em
  }

  // Bullet list (single-spacing, 0.5in padding)
  set list(body-indent: 1em)
  show list: it => {
    set par(leading: list-leading)
    block(inset: (left: 0.5in, right: 0.5in), it)
  }

  // Numbered list (single-spacing, 0.5in padding)
  set enum(body-indent: 1em, numbering: "(a)")
  show enum: it => {
    set par(leading: list-leading)
    pad(left: 0.5in, right: 0.5in, it)
  }

// Heading (single-spacing, 0.5in indents)
set heading(numbering: (..numbers) => {
  let level = numbers.pos().len()
  if (level == 1) {
    return numbering("1")
  } else if (level == 2) {
    return numbering("I.", numbers.pos().at(level - 1))
  } else if (level == 3) {
    return numbering("A.", numbers.pos().at(level - 1))
  } else {
    return numbering("1.", numbers.pos().at(level - 1))
  }
})

show heading: it => [
    #let indent = 0.5in * (counter(heading).get().len() -1)
    #set text(size: base-font-size, top-edge: 1em, bottom-edge: "baseline")
    #block(inset: (left: indent), above: 1.33em, below: 1.33em)[
      #set par(leading: .17em, justify: false)
      #place(dx: -0.5in, counter(heading).display())
      #it.body
    ]
]

show heading.where(level: 1): it => [
  #set par(justify: false, first-line-indent: 0em)
  #set align(center)
  #set text(size: base-font-size, top-edge: 1em, bottom-edge: "baseline")
  #it.body
]

// Footnote
  set footnote.entry(gap: .7em)
  show footnote.entry: it => {
    set par(leading:.17em, justify:true)
    set text(size: footnote-font-size, top-edge: 1em, bottom-edge: 0em)
    h(1em)
    it.note
    h(0.5em)
    it.note.body
  }

  // Blockquote
  show quote: it => {
    set text(size: base-font-size, top-edge: 1em, bottom-edge: "baseline")
    set par(leading: .17em, justify: true)
    set block(above: 1.33em, below: 1.33em)
    pad(left:1.0in, right:1.0in, it.body)
  }

  // Table
  set table(inset: (top: .1em, left: .5em, right: .5em, bottom: .5em))
  show table.cell: it => {
    set text(top-edge: 1em, bottom-edge: "baseline")
    single-spaced(it)
  }

  // Figure
   set figure(supplement: none)
   show figure: it => {
     {
     set text(top-edge: "cap-height", bottom-edge: 0pt, size: 10pt)
     set text(font: "Fira Mono", size: 9pt)
     set par(leading: .65em, justify: false)
     show par: set block(above: 2em, below: 2em)
     shadow-box(inset: 0.5em, radius: 3pt, it.body)
   }
   set text(top-edge: "cap-height", bottom-edge: 0pt, size: 12pt)
   align(center, it.caption)
  }

  // Link
  show link: it => text(fill: navy, underline(it))
  
  // Ref
  show ref: it => text(fill: red.darken(20%), strong(it))

  body
}
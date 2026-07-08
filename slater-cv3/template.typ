#let to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-string).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let baylor-blue = rgb("#003087")

#let latex = {
  set text(font: "New Computer Modern", weight: "regular")
  box(stack(dir: ltr,
    [L],
    h(-0.25em),
    move(dy: -0.2em, text(size: 0.7em)[A]),
    h(-0.25em),
    [T],
    h(-0.15em),
    move(dy: 0.2em, [E]),
    h(-0.15em),
    [X]
  ))
}

#show bibliography: set par(hanging-indent: 0pt)

#let cv(
  authors: (),
  name: none,
  date: none,
  margin: (x: 0.75in, y: 0.75in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "Linux Libertine",
  fontsize: 10pt,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
  )
  set par(
    justify: true,
    leading: 0.55em,
    hanging-indent: 0pt,
  )
  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize,
  )

  // Links and Highlights
  show link: set text(fill: baylor-blue)
  show "Baylor University": name => text(fill: baylor-blue, weight: "bold")[#name]
  show regex("Slater"): strong
  show regex("Carson"): strong

  // Header
  // Use explicit name if provided, otherwise try authors list
  let display-name = if name != none { name } else if authors.len() > 0 { authors.first().name } else { none }
  
  if display-name != none {
    block(width: 100%, below: 1.5em)[
      #grid(
        columns: (1fr, auto),
        align(left + bottom)[#text(size: 18pt, weight: "bold")[#display-name]],
        if date != none {
          align(right + bottom)[#text(size: 9pt, fill: rgb("#666666"), style: "italic")[Updated: #date]]
        }
      )
      #v(-0.4em)
      #line(length: 100%, stroke: 1.5pt)
    ]
  }

  doc
}

// Function for a section with label on the left
#let section(title, content) = {
  grid(
    columns: (1.7in, 1fr),
    gutter: 1.2em,
    [#set text(weight: "bold", size: 9pt, hyphenate: false); #set par(justify: false); #upper(title)],
    [#content]
  )
  v(1.2em)
}

// Function for entries within a section
#let entry(title: none, institution: none, date: none, description: none, location: none) = {
  block(width: 100%)[
    #grid(
      columns: (1fr, auto),
      [
        #if institution != none [#text(fill: baylor-blue, weight: "bold")[#institution]]
        #if location != none [, #location]
      ],
      [#if date != none [*#date*]]
    )
    #if title != none [#text(style: "normal")[#title]]
    #if description != none [#v(-0.3em) #text(size: 0.9em)[#description]]
  ]
  v(0em)
}

#let citation(authors: none, year: none, title: none, venue: none, url: none, note: none) = {
  block(width: 100%)[
    #if authors != none [#authors. ]
    #if year != none [#year. ]
    #if title != none ["#title". ]
    #if venue != none [#text(style: "italic")[#venue]. ]
    #if note != none [#text(size: 0.85em, weight: "bold", fill: gray)[(#note)] ]
    #if url != none [#link(url)]
  ]
  v(0.6em)
}

#let format-date(d) = {
  if type(d) == dictionary {
    if "month" in d {
      str(d.month) + " " + str(d.year)
    } else {
      str(d.year)
    }
  } else {
    str(d)
  }
}

#let proc-years(yrs) = {
  if type(yrs) == str { return yrs }
  if type(yrs) == int { return str(yrs) }
  if type(yrs) == dictionary {
    if "start" in yrs {
      let start-str = format-date(yrs.start)
      if "end" in yrs {
        let end-str = format-date(yrs.end)
        start-str + sym.dash.en + end-str
      } else {
        start-str + sym.dash.en + "Present"
      }
    } else if "end" in yrs {
      format-date(yrs.end)
    } else {
      ""
    }
  } else {
    ""
  }
}

#let list-education(file) = {
  let data = yaml(file).education
  for inst-name in data.keys() {
    // Skip Wheaton to handle manually in QMD as requested
    if inst-name == "Wheaton College (IL)" or inst-name == "Wheaton College" { continue }
    for item in data.at(inst-name) {
      entry(
        date: proc-years(item.year),
        title: item.degree,
        institution: inst-name,
        description: if "description" in item { item.description } else { none }
      )
    }
  }
}

#let list-appointments(file) = {
  let data = yaml(file).appointments
  for inst-name in data.keys() {
    let items = data.at(inst-name)
    if items.len() == 1 {
      let item = items.at(0)
      entry(
        date: proc-years(item.year),
        title: item.position,
        institution: inst-name,
        description: if "description" in item { item.description } else { none }
      )
    } else {
      block(width: 100%)[
        #grid(
          columns: (1fr, auto),
          [#text(fill: baylor-blue, weight: "bold")[#inst-name]],
          none
        )
        #v(0.3em)
        #for item in items [
          #block(width: 100%, inset: (left: 1.0em))[
            #grid(
              columns: (1fr, auto),
              [#text(style: "normal", weight: "medium")[#item.position]],
              [*#proc-years(item.year)*]
            )
            #if "description" in item and item.description != none [
              #v(-0.3em)
              #text(size: 0.9em)[#item.description]
            ]
          ]
          #v(0.4em)
        ]
      ]
      v(0.4em)
    }
  }
}

#let list-positions(file) = {
  let data = yaml(file).positions
  for inst-name in data.keys() {
    let items = data.at(inst-name)
    if items.len() == 1 {
      let item = items.at(0)
      entry(
        date: proc-years(item.year),
        title: item.position,
        institution: inst-name,
        description: if "description" in item { item.description } else { none }
      )
    } else {
      block(width: 100%)[
        #grid(
          columns: (1fr, auto),
          [#text(fill: baylor-blue, weight: "bold")[#inst-name]],
          none
        )
        #v(0.3em)
        #for item in items [
          #block(width: 100%, inset: (left: 1.0em))[
            #grid(
              columns: (1fr, auto),
              [#text(style: "normal", weight: "medium")[#item.position]],
              [*#proc-years(item.year)*]
            )
            #if "description" in item and item.description != none [
              #v(-0.3em)
              #text(size: 0.9em)[#item.description]
            ]
          ]
          #v(0.4em)
        ]
      ]
      v(0.4em)
    }
  }
}

#let list-honors(file) = {
  let honors = yaml(file).honors
  for honor in honors {
    entry(
      date: if "year" in honor { str(honor.year) } else { "" },
      title: honor.title,
      institution: if "organization" in honor { honor.organization } else { none },
      description: if "description" in honor { honor.description } else { none }
    )
  }
}

#let list-bibliography(file) = {
  set par(hanging-indent: 0pt)
  bibliography(file, title: none, full: true, style: "chicago-author-date")
}

#show: doc => cv(
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    (
      name: [$it.name.literal$],
      $if(it.phone)$ phone: "$it.phone$", $endif$
      $if(it.email)$ email: "$it.email$", $endif$
      $if(it.url)$ url: "$it.url$", $endif$
    ),
$endif$
$endfor$
  ),
$endif$
$if(date)$
  date: [$date$],
$endif$
  doc,
)

$body$

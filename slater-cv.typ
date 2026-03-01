// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}

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

#set bibliography(style: "chicago-author-date")

#let cv(
  authors: none,
  date: none,
  cols: 1,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 12pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  linestretch: 1,
  linkcolor: "#800000",
  doc,
) = {

  // sorry no sharing CVs
  let author = if authors != none {
    authors.first()
  } else {
    none
  }

  set page(
    paper: paper,
    margin: margin,
    numbering: "1"
  )
  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize
  )

    show link: this => {
    if type(this.dest) != label {
      text(this, fill: rgb(linkcolor.replace("\\#", "#")))
    } else {
      text(this, fill: rgb("#0000CC"))
    }
  }

  // handle first page header
  set heading(numbering: sectionnumbering)
  show heading.where(level: 1): head => block(width: 100%)[#text(weight: "bold", to-string(head.body)) #v(-14pt) #line(length: 100%)]

  if authors != none {
    align(center, {
      if "degrees" in author {
        text(weight: "bold", size: 24pt, author.name + ", " + author.degrees)
      } else {
        text(weight: "bold", size: 24pt, author.name)
      }
      if "role" in author [
        \ #author.role
      ]

      if "department" in author [
        \ #author.department
      ]

      if "university" in author [
        \ #author.university
      ]
    })

    let contact_block = ()
    let approx_fills = ()
    if "phone" in author {
      contact_block.push([#link("tel:" + author.phone)])
      approx_fills.push(1fr)
    }
    if "email" in author {
      contact_block.push([#link("mailto:" + to-string(author.email))])
      approx_fills.push(2fr)
    }
    if "website" in author {
      contact_block.push([#link(to-string(author.website))])
      approx_fills.push(3fr)
    }

    let n_contacts = contact_block.len()

    if n_contacts > 0 {
      grid(
        columns: approx_fills,
        inset: 0pt,
        gutter: 0pt,
        ..contact_block.map(contact => align(center, {
          contact
          })
        )
      )
    }
  }

  if date != none {
    align(center)[#date]
  }
  //line(length: 100%)

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
    line(length: 100%)
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#let proc-years(yrs) = {
  if "start" in yrs {
    if "end" in yrs {
      str(yrs.start) + sym.dash.en + str(yrs.end)
    } else {
      str(yrs.start) + sym.dash.en + "Present"
    }
  } else if "end" in yrs {
      str(yrs.end)
  } else {
    none
  }
}

#let list-education(file) = {
  let info = yaml(file).education

  let n_uni = info.len()

  for i in range(n_uni) {
    text(weight: "bold", size: 16pt, info.keys().at(i))
    v(-0.5em)
    for uni in info.values().at(i) {
      grid(
        inset: 0pt,
        columns:(4fr, 1fr),
        align: (left, right),
        gutter: 0pt,
        uni.degree, proc-years(uni.year)
      )
    }
  }
}

#let list-appointments(file) = {
  let info = yaml(file).appointments

  let n_jobs = info.len()

  for i in range(n_jobs) {
    text(weight: "bold", size: 16pt, info.keys().at(i))
    v(-0.5em)
    for job in info.values().at(i) {

      grid(
          columns:(4fr, 1fr),
          align: (left, right),
          gutter: 0pt,
          job.position, if "year" in job { proc-years(job.year) } else { "" }
      )
    }
  }
}

#let list-positions(file) = {
  let info = yaml(file).positions

  let n_jobs = info.len()

  for i in range(n_jobs) {
    text(weight: "bold", size: 16pt, info.keys().at(i))
    v(-0.5em)
    for job in info.values().at(i) {

      grid(
          columns:(4fr, 1fr),
          align: (left, right),
          gutter: 0pt,
          job.position, if "year" in job { proc-years(job.year) } else { "" }
      )
    }
  }
}

#let list-honors(file) = {
  let honors = yaml(file).honors

  for honor in honors {
    grid(
      columns: (1fr, 11fr),
      align: (left, left),
      gutter: 0.75em,
      // Show year if it exists
      if "year" in honor { str(honor.year) } else { "" },
      block[
        #strong(honor.title)
        #if "organization" in honor {
          sym.dash.em
          emph(" " + honor.organization)
        }
        #if "description" in honor {
          sym.dash.em
          text(" " + honor.description)
        }
      ]
    )
    v(0.5em)
  }
}

#let list-bibliography(file) = {
  bibliography(file, title: none,
    full: true, style: "chicago-author-date")
}

#show: doc => cv(
  authors: (
    (
      name: [Carson Slater],
                  university: [Baylor University],
                  department: [Department of Statistical Science],
            
            degrees: [PhD],
      
            role:  [Graduate Research Assistant],
      
            phone: "123456789",
      
            email: [Carson\_Slater1\@baylor.edu],
                  website: [https:\/\/carsonslater.github.io]
          ),
    ),
  date: [March 2026],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


= Using this template
<using-this-template>
The goal of this template is to combine Quarto’s best features with typst’s best to get a cv powered by shortcodes. For the best exerience, you will want to combine shortcodes with text in Quarto. The shortcodes will format standard entries, but do not cover all possible cases. As such, you may want to format some things using `typst` blocks or any other Quarto inputs. This template was designed by #link("https://christophertkenny.com/")[Christopher T. Kenny];. Full directions listed at the end of this document.

= Appointments
<appointments>
#list-appointments("education.yaml")

= Education
<education>
#list-education("education.yaml")

= Books
<books>
#block[
#block[
Burns, Nancy E., Kay L. Schlozman, and Sidney Verba. 2001. #emph[The Private Roots of Public Life: Gender and the Paradox of Political Inequality];. Cambridge: Harvard University Press.

] <ref-burns2001private>
#block[
Verba, Sidney. 2000. #emph[Representative Democracy and Democratic Citizens: Philosophical and Empirical Understandings];. University of Utah Press.

] <ref-verba2000representative>
#block[
Schlozman, Kay L., Sidney Verba, and Henry E. Brady. 1995. #emph[Voice and Equality: Civic Voluntarism in American Democracy];. Cambridge: Harvard University Press.

] <ref-verba1995voice>
#block[
King, Gary, Robert O. Keohane, and Sidney Verba. 1994. #emph[Designing Social Inquiry: Scientific Inference in Qualitative Research];. Princeton: Princeton University Press.

] <ref-king1994designing>
#block[
Prewitt, Kenneth, Robert Salisbury, and Sidney Verba. 1991. #emph[Introduction to American Government];. 6th ed. New York: Harper; Row.

] <ref-prewitt1991introgov>
#block[
Verba, Sidney. 1987. #emph[Elites and the Idea of Equality: A Comparison of Japan, Sweden, and the United States];. Cambridge: Harvard University Press.

] <ref-verba1987elites>
#block[
Verba, Sidney, and Gary R. Orren. 1985. #emph[Equality in America: The View from the Top];. Cambridge: Harvard University Press.

] <ref-verba1985equality>
#block[
Almond, Gabriel A., and Sidney Verba. 1980. #emph[The Civic Culture Revisited];. Edited by Gabriel A. Almond and Sidney Verba. Boston: Little, Brown.

] <ref-almond1980civic>
#block[
Schlozman, Kay L., and Sidney Verba. 1979. #emph[Injury to Insult: Unemployment, Class, and Political Response];. Cambridge: Harvard University Press.

] <ref-schlozman1979injury>
#block[
Nie, Norman, Jae-on Kim, and Sidney Verba. 1978. #emph[Participation and Political Equality: A Seven Nation Comparison];. New York: Cambridge University Press.

] <ref-verba1978seven>
#block[
Pye, Lucian, and Sidney Verba. 1977. #emph[The Citizen and the State];. Edited by Lucian Pye and Sidney Verba. Stamford: Greylock Publications.

] <ref-verba1977citizen>
#block[
Nie, Norman, John Petrocik, and Sidney Verba. 1976. #emph[The Changing American Voter];. Cambridge: Harvard University Press.

] <ref-verba1976voter>
#block[
Nie, Norman, and Sidney Verba. 1972. #emph[Participation in America: Political Democracy and Social Equality];. New York: Harper; Row.

] <ref-verba1972america>
#block[
Ahmed, Bashiruddin, Anil Bhatt, and Sidney Verba. 1971. #emph[Caste, Race, and Politics: A Comparison of India and the United States];. Beverly Hills: Sage Publications.

] <ref-verba1971caste>
#block[
Binder, Leonard, James S. Coleman, Joseph LaPalombara, Lucian Pye, Sidney Verba, and Myron Weiner. 1971. #emph[Crises of Political Development];. Vol. VII. Studies on Political Development. Princeton: Princeton University Press.

] <ref-binder1971crises>
#block[
Kim, Jae-on, Norman Nie, and Sidney Verba. 1971. #emph[The Modes of Democratic Participation];. Beverly Hills: Sage Publications.

] <ref-verba1971modes>
#block[
Converse, Philip E., Milton J. Rosenberg, and Sidney Verba. 1970. #emph[Vietnam and the Silent Majority: The Dove’s Guide to Public Opinion];. New York: Harper; Row.

] <ref-verba1970vietnam>
#block[
Almasy, Elina, Stein Rokkan, Sidney Verba, and Jean Viet. 1969. #emph[Comparative Survey Analysis];. Paris: Mouton.

] <ref-verba1969survey>
#block[
Pye, Lucian, and Sidney Verba. 1965. #emph[Political Culture and Political Development];. Edited by Lucian Pye and Sidney Verba. Vol. V. Studies in Political Development. Princeton: Princeton University Press.

] <ref-pye1965culture>
#block[
Almond, Gabriel A., and Sidney Verba. 1963. #emph[The Civic Culture: Political Attitudes and Democracy in Five Nations];. Princeton: Princeton University Press.

] <ref-almond1963civic>
#block[
Verba, Sidney. 1961. #emph[Small Groups and Political Behaviour: A Study of Leadership];. Princeton: Princeton University Press.

] <ref-verba1961small>
#block[
Knorr, Klaus, and Sidney Verba. 1961. #emph[The International System: Theoretical Essays];. Edited by Klaus Knorr and Sidney Verba. Princeton: Princeton University Press.

] <ref-knorr1961international>
] <refs-books>
= Peer-Reviewed Articles
<peer-reviewed-articles>
#block[
#block[
Verba, Sidney. 2006. “Fairness, Equality, and Democracy: Three Big Words.” #emph[Social Research: An International Quarterly] 73 \(2): 499–540.

] <ref-verba2006fairness>
#block[
Schlozman, Kay L., Nancy Burns, and Sidney Verba. 2003. “Unequal at the Starting Line: Creating Participatory Inequalities Across Generations and Among Groups.” #emph[American Sociologist] 34.

] <ref-schlozman2003unequal>
#block[
Verba, Sidney. 2003. “What If the Dream of Participation Turned Out to Be a Nightmare.” #emph[Perspectives on Politics] 1 \(4).

] <ref-verba2003nightmare>
#block[
Schlozman, Kay L., Nancy Burns, and Sidney Verba. 2002. “Who Bowls?: The \(Un)changing Stratification of Participation.” Edited by Barbara Norrander and Clyde Wilcox. #emph[Understanding Public Opinion];.

] <ref-verba2002whobowls>
#block[
Verba, Sidney et al. 2000. “Rational Action and Political Participation.” #emph[Journal of Theoretical Politics] 12 \(3).

] <ref-verba2000rational>
#block[
Brady, Henry E., Kay L. Schlozman, and Sidney Verba. 1999. “Prospecting for Participants: Rational Expectations and the Recruitment of Political Activists.” #emph[American Political Science Review] 93.

] <ref-verba1999prospecting>
#block[
Schlozman, Kay L., Nancy Burns, and Sidney Verba. 1999. “What Happened at Work Today: A Multi-Stage Model of Gender, Employment, and Political Participation.” #emph[Journal of Politics] 61 \(1).

] <ref-verba1999work>
#block[
Verba, Sidney. 1997. “Democracy and the Market: Dilemmas of Equality.” #emph[Iowa International Papers];.

] <ref-verba1997market>
#block[
Burns, Nancy, Kay L. Schlozman, and Sidney Verba. 1997a. “Knowing and Caring about Politics: Gender and Political Engagement.” #emph[Journal of Politics] 59 \(4).

] <ref-verba1997gender>
#block[
Schlozman, Kay L., Henry E. Brady, and Sidney Verba. 1997. “The Big Tilt: Participatory Inequality in America.” #emph[The American Prospect] 8 \(34).

] <ref-verba1997tilt>
#block[
Burns, Nancy, Kay L. Schlozman, and Sidney Verba. 1997b. “The Public Consequences of Private Inequality: Gender, the Family and Political Participation.” #emph[American Political Science Review] 91 \(2).

] <ref-verba1997consequences>
#block[
Brady, Henry E., Kay L. Schlozman, and Sidney Verba. 1995. “Beyond SES: A Resource Model of Political Participation.” #emph[American Political Science Review] 89 \(2).

] <ref-verba1995beyond>
#block[
Schlozman, Kay L., Nancy Burns, and Sidney Verba. 1995. “Is There Another Voice: Women and Participation.” #emph[American Journal of Political Science] 39 \(2).

] <ref-verba1995voice>
#block[
Verba, Sidney. 1995. “The Citizen as Respondent: Survey Research and American Democracy.” #emph[American Political Science Review] 89 \(1).

] <ref-verba1995respondent>
#block[
Schlozman, Kay L., Nancy Burns, and Sidney Verba. 1994. “Gender and the Pathways to Participation: The Role of Resources.” #emph[Journal of Politics] 56 \(4).

] <ref-verba1994gender>
#block[
Brady, Henry E., Kay L. Schlozman, and Sidney Verba. 1994. “Participation’s Not a Paradox: The View from American Activists.” #emph[British Journal of Political Science] 24.

] <ref-verba1994paradox>
#block[
Schlozman, Kay L., Henry E. Brady, and Sidney Verba. 1993a. “Citizen Activity: Who Participates? What Do They Say?” #emph[American Political Science Review] 87 \(2).

] <ref-verba1993citizen>
#block[
Schlozman, Kay L., Henry E. Brady, and Sidney Verba. 1993b. “Race, Ethnicity and Political Resources.” #emph[British Journal of Political Science] 23 \(4).

] <ref-verba1993race>
#block[
Verba, Sidney. 1993. “The Voice of the People.” #emph[PS: Political Science and Politics] 26 \(4).

] <ref-verba1993voice>
#block[
Schlozman, Kay L., and Sidney Verba. 1977. “Unemployment, Class Consciousness and Radical Politics: What Didn’t Happen in the Thirties.” #emph[Journal of Politics] 39 \(2).

] <ref-verba1977unemployment>
#block[
Shabad, Goldie, and Sidney Verba. 1977. “Workers’ Councils and Participation: The Yugoslav Experience.” #emph[American Political Science Review] 71.

] <ref-verba1977yugoslavia>
#block[
Kim, Jae-On, Norman Nie, and Sidney Verba. 1975. “The Amount and Concentration of Political Activity.” #emph[Political Methodology] 2 \(1).

] <ref-verba1975amount>
#block[
Kim, Jae-On, Norman Nie, and Sidney Verba. 1974. “Participation and the Life Cycle.” #emph[Comparative Politics] 6 \(3).

] <ref-verba1974lifecycle>
#block[
Brody, Richard A., and Sidney Verba. 1972. “Hawk and Dove: The Search for an Explanation of Policy Preferences on Vietnam.” #emph[Acta Politica] 7 \(2).

] <ref-verba1972hawk>
#block[
Brody, Richard A., and Sidney Verba. 1970. “Participation, Preferences and the War in Vietnam.” #emph[Public Opinion Quarterly] 34 \(3).

] <ref-verba1970vietnam>
#block[
Verba, Sidney. 1967a. “Democratic Participation.” #emph[Annals of the American Academy of Political and Social Science] 373.

] <ref-verba1967democratic>
#block[
Verba, Sidney et al. 1967. “Public Opinion and the War in Vietnam.” #emph[American Political Science Review] 61 \(2).

] <ref-verba1967opinion>
#block[
Verba, Sidney. 1967b. “Some Dilemmas in Comparative Research.” #emph[World Politics] 20 \(1).

] <ref-verba1967dilemmas>
#block[
Verba, Sidney. 1965. “Organizational Membership and Democratic Consensus.” #emph[Journal of Politics] 27 \(3).

] <ref-verba1965membership>
#block[
Verba, Sidney. 1964. “Simulation, Reality, and Theory in International Relations.” #emph[World Politics] 16 \(4).

] <ref-verba1964simulation>
#block[
Davis, Morris, and Sidney Verba. 1960. “Party Affiliation and International Opinions in Britain and France.” #emph[Public Opinion Quarterly] 24.

] <ref-verba1960affiliation>
#block[
Verba, Sidney. 1960. “Political Behavior and Politics.” #emph[World Politics] 12.

] <ref-verba1960behavior>
] <refs-articles>
= Book Chapters
<book-chapters>
#block[
#block[
Verba, Sidney, Kay L. Schlozman, and Nancy Burns. Forthcoming. “Family Ties: Understanding the Intergenerational Transmission of Participation.” In #emph[The Social Logic of Politics];, edited by Alan S. Zuckerman. Philadelphia: Temple University Press.

] <ref-verba_inpress_family>
#block[
Verba, Sidney et al. 2002. “Who Bowls? Political Equality, the Record of the Past Decades.” In #emph[Understanding Public Opinion];, edited by Clyde Wilcox and Barbara Norrander. Washington, D.C.: CQ Press.

] <ref-verba2002whobowls>
#block[
Verba, Sidney et al. 1999. “Civic Participation and the Equality Problem.” In #emph[Civic Engagement in American Democracy];, edited by Theda Skocpol and Morris P. Fiorina, 427–60. Washington, D.C.: Brookings Institution Press.

] <ref-verba1999civic>
#block[
Verba, Sidney. 1997. “The Civic Culture and Beyond: Citizens, Subjects, and Survey Research in Comparative Politics.” In #emph[Comparative European Politics: The Story of a Profession];, edited by Hans Daalder. London: Pinter.

] <ref-verba1997civicculture>
#block[
Verba, Sidney. 1995. “Race, Ethnicity and Participation.” In #emph[Counting by Race];, edited by Paul Peterson. Princeton: Princeton University Press.

] <ref-verba1995race>
#block[
Verba, Sidney. 1990. “Politics, Economics, and Equality.” In #emph[The Political Legitimacy of Markets and Government];, edited by Thomas R. Dye. Greenwich, Conn.: JAI Press.

] <ref-verba1990politics>
#block[
Verba, Sidney. 1986. “Comparative Politics: Where Have We Been? Where Are We Going?” In #emph[Comparative Politics: The State of the Discipline];, edited by Howard Wiarda. Westview Press.

] <ref-verba1986comparative>
#block[
Verba, Sidney, and Norman Nie. 1975. “Political Participation.” In #emph[Handbook of Political Science];, edited by Fred Greenstein and Nelson Polsby. Reading, MA: Addison-Wesley.

] <ref-verba1975participation>
#block[
Verba, Sidney. 1971a. “Cross-National Survey Research: The Problem of Credibility.” In #emph[Comparative Methodologies];, edited by Ivan Vallier. Berkeley: University of California Press.

] <ref-verba1971credibility>
#block[
Verba, Sidney. 1971b. “Sequences and Development.” In #emph[Crises of Political Development];, edited by Leonard Binder, James S. Coleman, Joseph LaPalombara, Lucian W. Pye, Sidney Verba, and Myron Weiner. Princeton: Princeton University Press.

] <ref-verba1971sequences>
#block[
Verba, Sidney. 1965a. “Comparative Political Culture.” In #emph[Political Culture and Political Development];, edited by Lucian W. Pye and Sidney Verba. Princeton: Princeton University Press.

] <ref-verba1965culture>
#block[
Verba, Sidney. 1965b. “Germany: The Remaking of Political Culture.” In #emph[Political Culture and Political Development];, edited by Lucian W. Pye and Sidney Verba. Princeton: Princeton University Press.

] <ref-verba1965germany>
#block[
Verba, Sidney. 1965c. “The Kennedy Assassination and the Nature of Political Commitment.” In #emph[The Kennedy Assassination and the American Public: Social Communication in Crisis];, edited by Bradley S. Greenberg and Edwin B. Parker. Stanford: Stanford University Press.

] <ref-verba1965kennedy>
#block[
Verba, Sidney. 1961. “Assumptions of Rationality and Non-Rationality in Models of the International System.” In #emph[The International System: Theoretical Essays];, edited by Klaus Knorr and Sidney Verba. Princeton: Princeton University Press.

] <ref-verba1961rationality>
] <refs-bookchapters>
= Honors
<honors>
#list-honors("honors.yaml")

= Service
<service>
#list-positions("positions.yaml")

= Shortcodes
<shortcodes>
This template is made of a base template and a shortcode, `{{< cv type file >}}`.

- type: points to one of the supported shortcode types below
- file: points to a file with a field with the same title as `type`

This allows you to get the full benefits from Quarto, while having sensible formatting options. Notably, these fill from a yaml file \(or a series of them).

The supported shortcodes types are:

- appointments: for academic appointment information \(example file: `education.yaml` under `appointments`)
- education: for education history \(example file: `education.yaml` under `education`)
- positions: for other positions or services \(example file: `positions.yaml`)
- honors: for listing honors \(example file: `honors.yaml`)

Note that all of these will fill in based on the order in the YAML. I recommend listing them in reverse order and potentially moving any lifetime awards to the top.

= Listing references
<listing-references>
This template ships with an adjusted version of `chicago-author-date.csl`, as `nosort-chicago-author-date.csl`. The two differences here are that it doesn’t sort, so whatever order is in your `.bib` file is the order that the references will be displayed. Second, it does not replace authors with `---` when you coauthor with the same group repeatedly. As there is no sorting, this looks funny if you have a random case of this, compared to a normal bibliography. If your `.bib` is messy, use `revsort-chicago-author-date.csl` instead, which reverse sorts by year.

To include a reference, I currently use the `pandoc-ext/multibib` extension. When Quarto updates to use Typst 0.13.0 in version 1.7, this will no longer be necessary.

The current format thus looks like:

+ Add the following to the YAML:

```
bibliography:
  books: "books.bib"
  bookchapters: "book_chapters.bib"
  articles: "journal_articles.bib"
```

#block[
#set enum(numbering: "1.", start: 2)
+ Include a ref div where you want to insert the references:
]

```
:::{#refs-KEY}
:::
```

where key is one of the keys in your YAML \(e.g., `book`, `bookchapters`, or `articles`).

This is totally open and you could include things like "Working Papers" with their own bib file.

The key limitation \(currently) is that you require a different `.bib` file for each of your types of citation listings.

= Other tips: General Quarto syntax work
<other-tips-general-quarto-syntax-work>
== Tables
<tables>
Here, we can see that you can use text or a tables if included functions are insufficient. For full documentation on Quarto, see: #link("https://quarto.org/docs/guide/");.

#figure(
align(center)[#table(
  columns: 3,
  align: (col, row) => (right,left,right,).at(col),
  inset: 6pt,
  [rank], [package], [count],
  [1],
  [rlang],
  [1672290],
  [2],
  [ggplot2],
  [1624767],
  [3],
  [cli],
  [1389491],
  [4],
  [Rcpp],
  [1386753],
  [5],
  [dplyr],
  [1361177],
)]
)

== Raw Typst
<raw-typst>
Typst is much easier to learn than LaTeX in my opinion. If you want to add some custom features, you can do that with raw Typst chunks.

For example, suppose that this is a fake CV for a famed, but deceased, member of the Harvard faculty. You might want to add a quote from the NYT obit:

#quote(attribution: "Sam Roberts, NYTimes", block: true)[
  Sidney Verba, whose pioneering research comparing political behavior among the world’s democracies became a classic book among students of politics, died on March 4 at his home in Cambridge, Mass. He was 86.
]




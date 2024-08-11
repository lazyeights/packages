#import "util.typ": *
#import "parser.typ": parse_case

/*
  cases is the global storage for registered cases and their
  formating.

case = (
  title: string,            // full case title ("Ashcroft v Iqbal")
  citation: string,         // full reporter citation ("556 U.S. 662")
  parenthetical: string,    // court/date parenthetical ("2009")
  short_cite: [content],    // content for short inline citation without pincite [Iqbal, 556 U.S. at ]
  display: [content],       // content for table of authorities, including line breaks:
                               [_Ashcroft v. Iqbal_, \ 556 U.S. 662, 129 S. Ct. 1937, 173 L. Ed. 2d 868, 859 (2009)]
)
*/
#let cases = state("cases", (:))

/*
  Registers a case to display in the table of authorities.

  The given content is parsed to extract the citation components and 
  must be properly formatted in Bluebook style.
  
  The given content also defines the look of the case in the table. It should
  include any typsetting and line breaks.
  
  The `key` can be auto-generated, in which case it defaults to the first
  name of the case and the citation. For example:

    register_case[_Ashcroft v. Iqbal_, \ 556 U.S. 662 (2009)]

  generates a key of `ashcroft556us662`.

  This `register_case` function does not, by itself insert a label into the document content. A
  separate call to `#toa_cases()` must be made somewhere.
*/
#let register_case(
  key: none,
  display) = {

  let raw_case = content_to_str(display)
  let parsed_case = parse_case(raw_case)

  assert(parsed_case != (:), message: "register_case: failed to parse case: " + raw_case)

  // if the key is not given, generate one
  let new_key = key
  if new_key == none or new_key == auto {
    new_key = lower(parsed_case.short_title + parsed_case.citation).trim().replace(regex("[^\w\d]"), "").trim("-")
  }

  let new_case = (
      title: parsed_case.full_title,
      citation: parsed_case.citation,
      parenthetical: parsed_case.parenthetical,
      short_cite: [#emph(parsed_case.short_title), #parsed_case.volume #parsed_case.reporter at ],
      display: display,
    )

  cases.update(x => {
    x.insert(new_key, new_case)
    return x
  })
}

/*
  query_label_page_locs returns an array of page locations
  where the given label is located. Only returns one location
  per page.

  TODO: Get correct page numbering

  Must be called within a context.
*/
#let query_label_page_locs(key) = {
    let elems = query(
      selector(label(key))
    )
    let all_locs = elems.map(x => x.location())
    let unique_refs = all_locs.fold((:), 
      (refs, x) => {
        refs.insert(str(x.page()), x) 
        return refs 
    })
    return unique_refs.values()
}

/*
  display_case inserts an entry for the table of authorities.

  TODO: insert link to pages
*/
#let display_case(key, display, show_hidden: false) = context {
  let refs = query_label_page_locs("__citator:" + key)
  let pages = refs.map(x => link(x)[#x.page()]).join(", ")

  let caption = if pages == none and show_hidden == false { 
    none
  } else if pages == none and show_hidden == true {
    [#display #box(width: 1fr, repeat[.]) #highlight[ERROR!]]
  } else {
    [#display #box(width: 1fr, repeat[.]) #pages]
  }
  
  return [
    #par(
      hanging-indent: 1em,
      first-line-indent: 0em,
    )[
      #figure(
        kind: "__citator_case", 
        supplement: "",
        numbering: none,
        caption: caption
      )[]
      #label(key)
    ]
  ]  
}

/*
  toa_cases inserts a complete table of authorities.
*/
#let toa_cases() = context {
  for key in cases.final().keys() {
    let case = cases.final().at(key)
    display_case(key)[#case.display #raw(lang: "typst", "<" + key + ">")]
  }  
}

/*
  case marks an inline citation to a case in a document.

  The case is added to the table of authorities if it does not exist.
  Because the marked content defines how the entry is displayed in the
  table of contents, line breaks can be included but the are stripped 
  from the inline display.

  The `key` can inferred from the given display content, 
  in which case it defaults to the first name of the case.
  If it cannot resolve the key to an case in the table of
  authorities it will fail.

  Examples:

    #case[_Bell Atl. Corp. v. Twombly_, 550 U.S. 544, 570, 127 S.Ct. 1955, 167 L.Ed.2d 929 (2007)]
    #case(key: "bell550us544")[_Twombly_, 550 U.S. at 570]
*/
#let case(key: none, form: "long", display) = context {

  let new_key = key

  // if the key is not given, generate one
  if new_key == none or new_key == auto {
    let parsed_case = parse_case(content_to_str(display))
    assert(parsed_case != (:), message: "case: must define `key` for invalid/incomplete citation `" + content_to_str(display) + "`")
    
    new_key = lower(parsed_case.short_title + parsed_case.citation).trim().replace(regex("[^\w\d]"), "").trim("-")
  }

  if cases.get().keys().contains(new_key) == false {
    register_case(key: key, display)
  }

  // TODO: Keep this line break if TOA case entry is dynamically generated?
  [#show linebreak: none; #link(label(new_key), highlight(display))#label("__citator:" + new_key)]
}

#let handle-case-ref(target, supplement) = {
  let target_label = target
  let cited_case = cases.get().at(str(target_label))

  if supplement == auto {
    // No supplement. Display the full case citation.
    return highlight[
      #link(target_label, cited_case.display)#label("__citator:" + str(target_label))
    ]
  } else if cited_case.citation.matches(regex("(?i)wl|lexis")).len() > 0 {
    // Pincite is to Westlaw or Lexis citation.
    return highlight[
      #link(target_label, cited_case.short_cite + ", *" + supplement)#label("__citator:" + str(target_label))
    ]
  } else {
    // Pincite is to regular reporter citation.
    return highlight[#link(target_label, cited_case.short_cite + supplement)#label("__citator:" + str(target_label))]
  }
}

#let short-cite(case) = {

}

#let citator-setup(body) = {
  show figure.where(kind: "__citator_case"): it => it.caption

  /*
  ref is overriden here to handle short-form references 
  to cases (e.g., `@iqbal[668]`).

  A supplement can be provided for a pin cite, and will
  distinguish between regular reporter and Westlaw/LEXIS citations
  to properly format the pincite.
*/
show ref: it => {
    if(it.element != none and it.element.func() == figure and it.element.kind == "__citator_case") {
      return handle-case-ref(it.target, it.supplement)
    } else {
      it
   }
}

  body
}
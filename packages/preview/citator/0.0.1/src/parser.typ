#let load_reporters() = {
  let raw_reporters = read("data/reporters.txt")
  raw_reporters = raw_reporters.replace("\n", "|").replace(".", "\.").replace(" ", "\\s")
  return raw_reporters
}

/*
  raw_authority <string>
*/
#let parse_case(raw_authority) = {
  assert(type(raw_authority) == "string", message: "parse_case: `raw_authority` must be string type")
  
  // Locate and extract the reporter / database matches and bail if invalid
  let reporters = load_reporters()
  let re = regex("(?i)(\d+)+\s*("+reporters+")\s?(\d+)")
  let matches = raw_authority.matches(re)

  if matches.len() == 0 {
    return (:)
  }

  // Extract first reporter citation.
  let first_match = matches.first()
  let (volume, reporter, page) = first_match.captures
  let citation = (volume, reporter, page).join(" ")

  // Special case for Westlaw or Lexis database citations
  if reporter.matches(regex("(?i)^wl|lexis")).len() > 0 {
    (volume, reporter, page) = ("", citation, "")
  }
  
  // Extract full case title
  let full_title = raw_authority.slice(0, first_match.start).trim().trim(",")

  // Extract short case title.
  // TODO: Ignore "In re" and "In the matter of"
  let match = full_title.match(regex("(?i)(\w+)"))
  let short_title = if match == none {
    ""
  } else {
    match.captures.first()
  }
  
  // Separate any pincite and the case / date parenthetical
  let remainder = raw_authority.slice(matches.last().end)
  let pincite = remainder.match(regex("^,\s*(\*?\d+).*"))
  if pincite != none {pincite = pincite.captures.first()}
  let parenthetical = remainder.match(regex("(\(.*\))"))
  if parenthetical != none {parenthetical = parenthetical.captures.first()}

  return (
    full_title: full_title,
    short_title: short_title,
    volume: volume,
    reporter: reporter,
    page: page,
    citation: citation,
    pincite: pincite,
    parenthetical: parenthetical,
  )
}
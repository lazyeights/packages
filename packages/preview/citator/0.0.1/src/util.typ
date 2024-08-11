#let content_to_str(content) = {
  if content.has("text") {
    content.text
  } else if content.func() == smartquote {
    "\""
  } else if content.has("children") {
    content.children.map(content_to_str).join("")
  } else if content.has("child") {
    content_to_str(content.child)
  } else if content.has("body") {
    content_to_str(content.body)
  } else if content == [ ] {
    " "
  }
}
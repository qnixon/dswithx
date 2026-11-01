The counting needs one workaround. A `Map` accepts any value as a key, but
it compares arrays by identity, so after counting the triple
`["has_link", "yes", "spam"]`, looking up a new array with the same three
strings returns `undefined`. We join the parts into one string,
`"has_link|yes|spam"`, instead. A missing key still returns `undefined`, and
`?? 0` turns that into zero, so add-one smoothing works for unseen values.

Division is always floating point: `3 / 55` is `0.0545...`, not the `0`
Ruby's integer division gives. Labels are sorted alphabetically, and only a
strictly higher score replaces the best, so a tie goes to the first label.
There was no built-in classifier to skip.

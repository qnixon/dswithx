Ruby's hashes do the work. `tally` counts the labels in one call, and
`Hash.new(0)` makes a counter whose missing keys read as zero. Arrays work as
hash keys, so `value_counts[[f, row[f], row[LABEL]]] += 1` counts a feature,
value, and label together. `max_by` keeps the first maximum, so sorting the
labels first gives the tie rule.

Two things push back. Integer division truncates: `3 / 55` is `0`, and
`Math.log(0)` is `-Infinity`, with no error. Every probability uses `fdiv` to
avoid that. And a method defined with `def` can't see the script's local
variables, so the scorer is a lambda that closes over the counts. As on
other pages, we split lines on commas by hand, because `csv` has been a
bundled gem rather than part of the default standard library since Ruby 3.4.

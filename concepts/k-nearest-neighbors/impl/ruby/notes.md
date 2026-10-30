Ruby reads cleanly here. `partition` splits training from test seeds in one
call, `tally` turns the five neighbor labels into vote counts, and `max_by`
picks the winner. Distance is a one-liner,
`Math.sqrt(a.zip(b).sum { |x, y| (x - y)**2 })`, and it works for any number
of features. For exactly two, `Math.hypot(dx, dy)` would also do.

The catch is sorting. Ruby's `sort_by` is not stable: when we sorted 100
pairs on a key with only two values, equal keys came back out of their
original order. So `classify` sorts by `[distance, i]`, where `i` is the
file position from `each_with_index`. Equal distances then keep file order,
as in the other languages. Each line is split on commas by hand, which works
because no field in this file is quoted.

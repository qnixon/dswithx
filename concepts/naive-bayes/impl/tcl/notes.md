We count with dictionaries. `dict incr` adds one to a key and starts a new
key at 1, so `label_counts` needs no setup. A list is also a string, so
`[list $f $v $label]` works as a single dict key for each feature, value,
and label. `dict get` on a missing key is an error, so a small `count_of`
reads unseen keys as zero.

Integer division is the trap: `3 / 55` is `0`, and `log(0)` is `-Inf` with
no error, so every probability multiplies by `1.0` first. Labels are tried
in `lsort` order, and only a strictly higher score wins, so a tie goes to
the first. Tcl has no classifier to skip; Tcllib isn't installed.

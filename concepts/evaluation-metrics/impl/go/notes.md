`encoding/csv` reads the file, and each row becomes a `part` struct with a
`bool` and a `float64`. A tagless `switch` sorts every part into true
positives, false positives, false negatives, and true negatives, taking the
first case that holds.

Go never mixes `int` and `float64` in arithmetic, so dividing an `int` by
a `float64` doesn't compile, and every ratio wraps its counts in
`float64(...)`. The AUC loops over all 33 times 167 pairs, scoring 2 for a
win and 1 for a tie in an `int`.

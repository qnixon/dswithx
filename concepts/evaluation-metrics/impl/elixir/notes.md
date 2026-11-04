Each part becomes a `{defective, score}` tuple. At each threshold,
`Enum.frequencies` counts the `{flagged, defective}` pairs, and the four
cells of the confusion matrix are four lookups, with 0 for a missing pair.
The false-negative count is named `fn_`, because `fn` starts an anonymous
function and can't be a variable.

The AUC is a comprehension over every defective and good score, 33 times
167 pairs, and a `cond` gives 2 for a win, 1 for a tie, and 0 for a loss.
`Enum.sum` adds them, and `/` gives a float only at the end.

Maps do all the counting. A struct with `feature`, `value`, and `label`
fields works as a map key, so `valueCounts[key{f, row[f], row[label]}]++`
counts all three together, and a missing key reads as zero. A map of `bool`
values serves as a set for the distinct values of each feature.

The trap is order. Go randomizes map iteration, so ranging over the label
counts would try the labels in a different order on different runs, and an
exact tie could go either way. We copy the labels into a slice and sort it,
so a tie always goes to the alphabetically first. Every count is an `int`,
so each probability converts with `float64()` before dividing.

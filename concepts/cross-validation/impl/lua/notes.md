The classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
of k, and one over the 5 folds. Lua has no slicing, so we build each split
by filtering on row number. One pass with `ipairs` sends rows `first` to
`last` to `held_out` and the rest to `rest`, which keeps file order on both
sides.

Fold bounds use `//`, which divides and rounds down, and they start at 1
because Lua arrays do. Lua has no cross-validation, kNN, or counter type,
and `table.sort` isn't stable, so its comparison breaks distance ties by
row number.

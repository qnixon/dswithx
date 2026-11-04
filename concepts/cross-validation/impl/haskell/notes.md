The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Each fold comes from two calls to
`splitAt`: the first cuts off the rows before the fold, and the second cuts
the 30 held-out rows from the rows after them, so `before ++ after` is that
round's training set.

Picking the best k reuses the vote's trick. `foldl1` with a strict `>`
keeps the earlier, smaller k on a tie, where `maximumBy` would return the
last. Haskell's `base` library has no cross-validation or kNN function, so
both loops are written out.

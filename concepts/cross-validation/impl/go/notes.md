The kNN classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Cross-validation adds two loops: one over
the odd values of k, and one over the 5 folds.

Go slices make the held-out fold free: `train[a:b]` is a view of 30 rows,
not a copy. The other 120 rows need care. `append(train[:a], ...)` looks
right, but it writes into the array `train` shares, so it overwrites the
fold being tested. On this data that mistake reports 100% accuracy for k = 1.
`slices.Concat` copies into a new slice instead. The standard library has no
cross-validation, so every step is written out.

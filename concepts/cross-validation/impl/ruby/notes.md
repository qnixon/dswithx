The classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
of k, and one over the 5 folds. Slicing builds each split. `train[start, n]`
takes `n` rows from `start`, so the held-out fold is `train[f * size, size]`,
and `rest` joins the rows before it to `train[(f + 1) * size..]`, an endless
range that runs to the last row.

Ruby has no cross-validation in its standard library, and the Rumale gem,
which has it, isn't installed. `sort_by` isn't stable, so the sort key is
`[distance, i]`, which keeps equal distances in file order.

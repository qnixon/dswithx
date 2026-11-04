The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
`1:2:15`, and one over the 5 folds. Each fold is a range such as `31:60`,
which includes both ends, and `train[fold]` copies those seeds into a new
array. `vcat` joins the seeds before and after the held-out block.

Julia's MLJ package has cross-validation built in, but it isn't installed.
The sort is stable, so equal distances keep file order, and a `Dict` counts
the votes, with ties settled by walking the nearest seeds in order.

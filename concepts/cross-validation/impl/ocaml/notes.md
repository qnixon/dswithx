The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. To build the folds, `List.mapi` numbers
the training rows, and `List.partition` splits them on `i / size = f`: the
30 rows of fold `f` are held out, and the other 120 train. Integer `/`
rounds down for positive numbers, so rows 0 to 29 are fold 0.

The best k comes from a `List.fold_left` that prints each accuracy as it
goes and replaces the leader only on a strictly larger score, so ties keep
the smaller k. OCaml's standard library has no cross-validation or kNN.

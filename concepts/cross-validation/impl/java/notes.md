The kNN classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Cross-validation wraps it in two loops,
one over the odd values of k and one over the 5 folds. `subList` builds
each split: it returns a view of the training list, not a copy, so the
held-out block costs nothing, and the rest is a new `ArrayList` of the rows
before the block plus `addAll` of the rows after it.

Java's standard library has no cross-validation; Weka's `crossValidateModel`
does this, but Weka isn't installed. `List.sort` is stable, so equal
distances keep file order, and `groupingBy` counts the votes.

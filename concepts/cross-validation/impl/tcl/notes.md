The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
of k, and one over the 5 folds. `lrange` cuts each fold, and both of its
indices are included, so fold 1 is `lrange $train 0 29`. `concat` joins
the pieces before and after it. For the first fold, the "before" piece is
`lrange $train 0 -1`, which is simply empty.

Tcl has no cross-validation command, and Tcllib isn't installed. The
distance is written out with `sqrt`, `lsort -real -index 0` is stable, so
equal distances keep file order, and a dict counts the vote.

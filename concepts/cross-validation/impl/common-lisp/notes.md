The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. For each fold, `subseq` copies out the 30
held-out rows, and `append` joins the stretches before and after them into
that round's training set. One `loop` walks the folds and sums the correct
counts.

`(floor 150 5)` gives the fold size, 30. Dividing by a double, not by the
integer 150, keeps the accuracy from becoming an exact fraction such as
71/75. Only a strictly larger accuracy replaces the leader, so ties keep
the smaller k. Common Lisp has no cross-validation or kNN function.

The classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
of k, and one over the 5 folds. Array slices build each split.
`@$train[$lo .. $hi]` takes one block of 30 rows, and `rest` takes the rows
at two ranges in one slice. For the first fold, `0 .. -1` is an empty range,
so no special case is needed.

Perl has no cross-validation or kNN, and CPAN modules aren't installed. The
sort block compares distances, then row numbers, so equal distances keep the
earlier seed, and a hash counts the votes.

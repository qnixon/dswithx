The kNN classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed by `#define`. Cross-validation adds two loops:
one over the odd values of k, and one over the 5 folds.

C has no slices, so the two sides of each split are built differently. The
held-out fold is a pointer to its first row plus a count of 30, with nothing
copied. The other 120 rows are copied, in file order, into a reusable
`rest` buffer. Because `qsort` breaks distance ties by row number, keeping
`rest` in file order is what keeps the earlier training seed. There is no
cross-validation in the standard library, so every step is written out.

The kNN classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Cross-validation adds two loops: one over
the odd values of k, and one over the 5 folds.

The held-out fold is a slice, `&train[start..end]`, which borrows 30 rows
without copying them. The other 120 rows come from `chain`, which joins the
rows before and after the fold into a vector of references, in file order.
A shared `&` borrow is read-only, so the fold can't be changed by accident.
`sort_by` is stable, so equal distances keep the earlier seed. Crates such
as linfa and smartcore offer cross-validation, but none is installed.

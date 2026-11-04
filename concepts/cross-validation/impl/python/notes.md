The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Cross-validation wraps it in two loops:
one over the odd values of k, and one over the 5 folds. Slicing builds each
split: `held_out` is one block of 30 rows, and `rest` joins the slices
before and after it.

Python's standard library has no cross-validation; scikit-learn's
`cross_val_score` and `KFold` do this, but scikit-learn isn't installed.
`math.dist` gives the distance, `sorted` is stable so equal distances keep
file order, and `Counter` tallies the votes.

The kNN classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Cross-validation wraps it in two loops:
`stride(from:through:by:)` gives the odd values of k, and a plain range
gives the 5 folds. A range subscript such as `train[start..<end]` gives an
`ArraySlice`, a view that shares the array's storage, so we wrap it in
`Array(...)` for the held-out block, and `+` joins the slices before and
after it into the rest.

Swift's standard library has no cross-validation or kNN. `sorted(by:)` is
stable, so equal distances keep file order, and a `Dictionary` counts the
votes.

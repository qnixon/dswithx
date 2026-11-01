Each row is read into a `Dict` from column name to value, and the counts go
into two more: one keyed by label, and one keyed by a
`(feature, value, label)` tuple. `get(counts, key, 0)` reads a missing
count as zero, so unseen combinations need no special case before add-one
smoothing.

A `Dict` doesn't keep insertion order, so the labels are sorted before
scoring. `argmax` then returns the first of equal scores, which sends an
exact tie to the alphabetically first label, matching Python's tie rule.
Julia's standard library has no naive Bayes, so there was nothing to skip.

The classifier is the same as on the k-nearest neighbors page, with the
training seeds and `k` passed in. Each fold is an index range, `rows`, and R
builds both halves of the split from it: `train[rows, ]` is the held-out
block of 30, and `train[-rows, ]` is everything else, because a negative
index drops rows instead of picking them. `mapply()` takes `MoreArgs` for
the seeds and `k` that every call shares.

Base R has no cross-validation function. The `class` package, home of
`knn.cv()`, and caret's `trainControl()` aren't installed in this image, so we
write out both loops, the one over k and the one over folds.

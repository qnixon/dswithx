Each point is a `defstruct` record, so `(point-x p)` reads its x. Assignment
is a `mapcar` of `nearest` over the points, and `nearest` keeps a centroid
only if it is strictly closer, so a tie would go to the lower index. To
notice that nothing changed, we compare the whole new assignment with the
last one using `equal`, which checks two lists element by element; `eq`
would only ask whether they are the same list in memory.

Common Lisp has no clustering, mean, or distance function to skip, so we
write the squared distance and the mean ourselves. An empty cluster would
keep its old centroid, though this data never produces one.

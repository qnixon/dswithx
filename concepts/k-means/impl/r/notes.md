Matrices fit k-means well. The points are a two-column matrix,
`colSums(members) / nrow(members)` moves a centroid, and
`centroids[assignment, ]` lines each point up with its own centroid, so the
inertia is one `sum()`. `which.min()` returns the first minimum, which is the
lower-index tie rule, and `identical()` checks whether anything changed.

The trap is that subsetting a matrix down to one row silently turns it into
a plain vector unless you pass `drop = FALSE`.

`kmeans()` is built in, but its default algorithm is Hartigan-Wong, not the
loop on this page. `kmeans(points, centers = points[1:3, ], algorithm =
"Lloyd")` reproduces our result exactly: 5 iterations, sizes 52, 50, and 48,
and inertia 423.627610.

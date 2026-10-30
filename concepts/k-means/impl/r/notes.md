<!-- Placeholder text: to be written. -->

**Easy:** matrices fit the algorithm well. `colSums(members) / nrow(members)`
moves a centroid, `centroids[assignment, ]` lines each point up with its own
centroid so the inertia is one `sum()`, and `which.min()` returns the first
minimum, which is exactly the lower-index tie rule. `kmeans()` is built in,
but its default algorithm is Hartigan-Wong, not Lloyd's; the from-scratch
loop needs `kmeans(points, points[1:3, ], algorithm = "Lloyd")` to compare.

**Hard:** 1-based cluster numbers are convenient for output but mean the
"lower index" rule is about 1..3, not 0..2. Subsetting a matrix down to one row
silently drops it to a vector unless `drop = FALSE` is passed.

Each point is a `Point` record with `X` and `Y` fields, and the centroids
are a fixed array indexed by `Cluster`, a subtype covering 1 to 3. We start
from the first three points, assign each point to its nearest centroid, and
move each centroid to its cluster's mean. Ada's `=` compares two arrays
element by element, so one `exit when New_Assignment = Assignment` notices
that nothing changed.

Ada's standard library has no k-means and no distance function, so we write
out the squared distance. One quirk: `Append` needs `Point'(...)`, because
a bare aggregate could also be a vector, and the call becomes ambiguous.

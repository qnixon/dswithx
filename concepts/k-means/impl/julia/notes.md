Points are vectors, and Julia's arithmetic works on whole vectors: `sum`
over a cluster's members adds them coordinate by coordinate, so the new
centroid is just `sum(members) / length(members)`. Picking the members is a
mask, `points[assignment .== j]`, which keeps the points whose assignment
equals `j`.

`argmin` returns the first of equal values, so a point tied between two
centroids goes to the lower-numbered one, as in Python. Clusters are
numbered from 1, matching the output lines. Neither Base nor `Statistics`
has a k-means function, so there was nothing to skip.

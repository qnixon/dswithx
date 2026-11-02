Each point is a small `struct` with `x` and `y` fields, so the data is one
array of `Point` that `read_points` grows with `realloc`. Assigning a struct
copies it, so `centroids[j] = points[j]` can't overwrite a data point when a
centroid moves.

We notice that nothing changed with a flag: every assignment starts at −1,
and the pass sets `changed` whenever a point's nearest centroid differs from
its stored one. `nearest` compares squared distances, which rank centroids
the same way, so it needs no `sqrt`, and only a strictly smaller distance
wins, so ties go to the lower index. C has no k-means function to avoid.

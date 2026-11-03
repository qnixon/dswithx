Each point is a `TPoint` record with `X` and `Y` fields, held in one
dynamic array, and the three centroids sit in a fixed-size
`array[0..K - 1]`. A record is a value, so `Centroids[J] := Points[J]`
copies it, and moving a centroid can't change a data point.

We notice that nothing changed with a flag: every assignment starts at −1,
and the pass sets `Changed` whenever a point's nearest centroid differs
from its stored one. `Nearest` compares squared distances, which rank
centroids the same way, so it needs no `Sqrt`, and only a strictly smaller
distance wins, so ties go to the lower index. None of the installed units
has a k-means routine to avoid.

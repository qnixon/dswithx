A point is a small `Point` struct with `x` and `y` fields, and `zip`
pairs the two columns into points. Swift arrays compare with `==`
element by element, so we notice that nothing changed by comparing the
whole new assignment with the last one. Before the first pass the last
assignment is an empty array, which never equals one with 150 entries.

Nearest-centroid search is a plain loop. Only a strictly smaller distance
replaces the best, so a tie goes to the lower index. We compare squared
distances, which needs no square root, and inertia uses them directly. An
empty cluster keeps its old centroid. Swift has no clustering, so there
was no built-in to skip.

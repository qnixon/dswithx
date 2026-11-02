The points are rows of a 150-by-2 matrix, so each step works on all of them
at once. `points - centroids(j, :)` subtracts one centroid from every row,
and `sum(..., 2)` adds across each row to give squared distances. Then
`min(distances, [], 2)` returns each row's nearest column, the first one on a
tie, so ties go to the lower-numbered centroid.

`isequal` compares the new assignment with the last, and it checks shape as
well as values. A new centroid is `sum(members, 1) / rows(members)`, written
out instead of calling `mean`. Core Octave has no `kmeans`, and the
statistics package isn't installed.

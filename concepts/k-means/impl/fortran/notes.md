Fortran stores arrays column by column, so each point is a column of a
2-by-150 array and `points(:, i)` is one point. `centroids = points(:, 1:k)`
copies the values, so moving a centroid can't overwrite a data point.

`minloc` returns the first of equal distances, so a tie goes to the
lower-numbered centroid, and clusters are numbered from 1, matching the output.
A new centroid is `sum(points(1, :), mask=assignment == j)` over the member
count, skipped when the count is zero. The helper is `nearest_centroid`
because `nearest` is already an intrinsic: it returns the next representable
number. gfortran has no k-means intrinsic, so there was nothing to skip.

The points live in two parallel arrays, `X` and `Y`, and the centroids in
`CX` and `CY`, all given a fixed size with `DIM`. Each pass of the loop runs
two subroutines: `GOSUB 2000` assigns every point to its nearest centroid
and sets `CH` to 1 if any point moved, and `GOSUB 3000` moves each centroid
to the mean of its points. Squared distances rank centroids the same way as
distances, so we never call `SQR`, and only a strictly smaller distance
wins, so ties go to the lower cluster. `STR$(1)` gives `" 1"`, with a
leading space, so `MID$` trims it before building names like `centroid_1_x`.
BASIC has no k-means function to avoid.

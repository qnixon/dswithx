We store each degree's augmented normal equations as a two-dimensional
`double precision[][]`, stacked from one-row arrays by `array_agg`.
Elimination is `WITH RECURSIVE`, one row per cleared column. A query
can't assign to one array entry, so each step builds a whole new
matrix: a `CASE` maps every row to its source row, which performs the
pivot swap, and the lower rows subtract a multiple of the pivot row. A
second recursive query does back substitution. Note that `m[2]` on a 2D
array is NULL, not row 2. We skip `regr_slope`, which fits only a line;
core PostgreSQL has no polynomial fit or linear solver.

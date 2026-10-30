Each half of an iteration is natural SQL. "Nearest centroid" is `ORDER BY`
distance `LIMIT 1` over three candidates, and "move to the mean" is a
`GROUP BY` on the cluster with `sum` and `count`.

The loop is the hard part. SQL has none, so we use `WITH RECURSIVE`, where
each step is one row holding the whole state as arrays: centroid x values,
centroid y values, and every point's cluster. PostgreSQL rejects aggregates
in the recursive step, so the assign and update steps sit in `LATERAL`
subqueries. "The first three points" also needs file order, which a table
doesn't have; it comes from the `row_id` column the harness adds while
loading. Core PostgreSQL has no k-means function to skip.

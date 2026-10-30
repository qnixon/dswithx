<!-- Placeholder text: to be written. -->

**Easy:** each half of an iteration is natural SQL: "nearest centroid" is
`ORDER BY distance LIMIT 1` over the three centroids, and "move to the mean"
is a `GROUP BY` cluster.

**Hard:** the loop. SQL has no loop, so this uses `WITH RECURSIVE`, where each
step produces one row holding the whole state as arrays (centroid x and y
values, and every point's cluster). PostgreSQL does not allow aggregates
directly in the recursive step, so the assign and update steps sit in
`LATERAL` subqueries. A PL/pgSQL function with a real loop would also work;
the recursive query was kept because it stays in plain SQL and each step
still reads top to bottom. "The first three points" also needs file order,
which a table doesn't have; it comes from the `row_id` column the harness
adds while loading.

SQL has no matrices, so we store them long: one row per entry, `(i, j, r)`.
Then a matrix times a vector is a `GROUP BY i` with `sum(r * v[j])`, and
the correlation matrix itself is a self-join of the standardized scores on
`row_id`. Power iteration is `WITH RECURSIVE` twice, once per component,
each row holding the step number and the vector as a `double precision[]`.
PostgreSQL rejects aggregates in the recursive step, so the product sits in
a `LATERAL` subquery. `unnest ... WITH ORDINALITY` turns the final array back
into numbered rows. We skip `avg`, `stddev_samp`, and `corr`, which would
give the same correlations; core PostgreSQL has no eigenvector function.

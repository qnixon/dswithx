SQL has no loops, so the folds and the values of k become columns. Numbering
the training rows from 0 with `row_number()` and dividing by 30 gives each
row its `fold`, and a self-join on `train.fold <> held.fold` pairs every
seed with the 120 seeds outside its fold.

We rank those neighbors once. Joining the ranking to `generate_series(1,
15, 2)` on `rank <= k` gives the k nearest for every k at once, and
`GROUP BY k` counts the votes. `ORDER BY accuracy DESC, k` with `LIMIT 1`
picks the best k, smaller on a tie. As on the kNN page, `train.id` breaks
distance ties. PostgreSQL has no kNN or cross-validation built in.

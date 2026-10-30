SQL describes results instead of loops, and the fit is just a few sums
over one table. Three common table expressions follow the formulas in
order: `means`, then `sums` of squares and cross-products, then `fit`. The
second pass over the data is a join to the one-row `means` result.

The means need their own step because aggregates can't nest: `sum(hours -
sum(hours) / count(*))` is an error. Printing also takes care, since
`round(value, 6)` doesn't exist for `double precision`, so each result is
cast to `numeric` first. PostgreSQL could do the whole job with
`regr_slope`, `regr_intercept`, `corr`, and `regr_r2`, which match this
query's results. We avoided them here.

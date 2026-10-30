<!-- Placeholder text: to be written. -->

**Easy:** the whole fit is a few sums over one table. Each common table
expression (means, then sums of squares, then the fit) is one line of the
formula, and the second pass over the data is just a join to the one-row
`means` result.

**Hard:** not much. The means have to be computed in their own step before
the deviations can be summed, because an aggregate cannot use another
aggregate over the same rows. (The built-ins `regr_slope`, `regr_intercept`,
`corr`, and `regr_r2` do each result in one call.)

PostgreSQL has a family of regression aggregates, so the whole fit is one
`SELECT` over the table. `regr_slope`, `regr_intercept`, and `regr_r2` give
the line and its R squared, and `corr` gives r.

The trap is the argument order. Every one of them takes the predicted value
first and the predictor second, `regr_slope(score, hours)`, the reverse of
how you'd write a point (x, y). Swap them and you get the slope of hours on
score instead, a different line. The family also includes `regr_sxx`,
`regr_sxy`, and `regr_syy`, the very sums the from-scratch version writes
out.

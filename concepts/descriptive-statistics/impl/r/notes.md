<!-- Placeholder text: to be written. -->

**Easy:** everything. Arithmetic is vectorized, so the variance is
`sum((values - mean_value)^2) / (n - 1)` with no loop, and `read.csv` returns
columns by name. R is the one language here where the from-scratch version is
the harder way: `mean()`, `median()`, `var()`, and `sd()` would each do a line
in one call.

**Hard:** 1-based indexing makes the median's middle positions easy to get off
by one.

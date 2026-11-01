R can fit this in one call: `glm(passed ~ hours + sleep, family = binomial)`.
We avoided it, along with `mean()` and `sd()`. On this data, `glm` reaches
the same three weights to six decimals in 5 iterations of iteratively
reweighted least squares, where we take 1000 plain gradient steps.

Matrix arithmetic does the looping for us. With a column of 1s for the
intercept, `x %*% w` gives every row's score at once, and `t(x) %*% errors`
sums error times input for each weight. One catch: the matrix keeps its
column names, and `%*%` passes them on to the weights, so `design()` calls
`unname()` to keep the printed labels clean.

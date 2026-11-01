Gradient descent is a loop, and SQL has none, so we use `WITH RECURSIVE`
again. Each row of the recursion is one step: the step number and the
three weights, 1001 rows from step 0 to step 1000. Inside a step, the
gradient is three `sum` aggregates over the scaled training rows, divided
by `count(*)`. PostgreSQL rejects aggregates in the recursive term itself
("aggregate functions are not allowed in a recursive query's recursive
term"), so they sit in a `LATERAL` subquery that sees the old weights.

The scaling uses `sum` and `count` in place of `avg` and `stddev_samp`.
Core PostgreSQL has no logistic regression, sigmoid, or logit function to
skip; `exp` and `ln` do the rest.

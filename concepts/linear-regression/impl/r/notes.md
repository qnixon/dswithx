R was built for this, so the from-scratch version is the long way around.
`lm(score ~ hours)` fits the line in one call, and `cor()` gives r. We
avoided both, and `mean()` too, to show the arithmetic.

Vectorization keeps it short anyway. `x - mean_x` is a whole vector of
deviations, so `sum((x - mean_x) * (y - mean_y))` is the cross-product sum with no loop,
and `read.csv` hands back the columns by name as `data$hours` and
`data$score`. Printing is short too: `sprintf` also works on vectors, so one
call formats all four named results, and this is the shortest
implementation on the page.

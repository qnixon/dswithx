We read `hours` and `score` as two separate lists, each found by its header
name. Pairing them back up takes no zip: `maplist(product, Dxs, Dys,
Products)` walks both lists side by side, so the first hours deviation meets
the first score deviation. The same `sum_of_products` rule gives Sxx, Syy,
and Sxy.

SWI-Prolog has no mean, regression, or correlation predicate to avoid. Its
`library(statistics)` reports run time and memory, not data. So `mean` is a
three-line rule, and the two passes are just the order of the goals in
`main`: the means come first, and the deviations use them.

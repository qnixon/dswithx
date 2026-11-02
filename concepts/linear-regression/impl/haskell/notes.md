We read `hours` and `score` as two separate lists of `Double`, each found by
its header name, and `zip` pairs them back up row by row for the
cross-products. There are no loops: each sum is a list comprehension handed
to `sum`, such as `[(x - meanX) * (y - meanY) | (x, y) <- zip xs ys]`, which
reads almost like the formula for Sxy.

Base has no mean, so a small `mean` function divides `sum` by `length`, with
`fromIntegral` turning the `Int` count into a `Double`. The two passes are
just the order of the `let`: the means are defined first, and the
deviations use them. No regression or correlation function is called.

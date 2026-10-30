Python stays close to the formulas. `csv.DictReader` reads both columns by
their header names, and each of the three sums is a single generator
expression. `zip(xs, ys)` pairs every `hours` value with its `score`, so the
cross-product sum, `sum((x - mean_x) * (y - mean_y) for x, y in zip(xs,
ys))`, reads like the formula.

What we left out is the built-in. The standard library's `statistics` module
has `linear_regression`, which returns the slope and intercept, and
`correlation`, which returns r. Both give the same numbers as this file. We
skipped them so the sums stay visible. In real code you'd reach for them.

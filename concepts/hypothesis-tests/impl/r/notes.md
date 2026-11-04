We never shuffle at random. `combn(plants, n)` lists every choice of 8 of
the 16 plants, one per column, in an 8 by 12,870 matrix. Passing
`FUN = sum` gives each choice's total instead, so one call returns all
12,870 totals as a vector, and the count of extreme splits is a single
vectorized `sum()` of a comparison. `combn()` lives in the utils package,
which ships with R and loads by default.

`read.csv()` reads the grams as integers, so the totals stay whole numbers
and `>=` never meets a near-tie. The coin package has permutation tests,
but it isn't installed.

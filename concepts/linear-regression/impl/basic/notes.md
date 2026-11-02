BASIC has no regression, correlation, or even sum function, so we write the
two passes out. The first `FOR` loop adds up hours and scores for the means.
The second adds the squared deviations and the cross-products, three running
totals updated on one line separated by colons. The slope, intercept, and
`r` then come from those sums, with `SQR` for the square root.

Both columns live in arrays sized by `DIM`, so `X` and `Y` hold at most
1,000 rows each. Names here are short (`XX`, `XY`, `MX`) because every
variable is global and shared with the subroutines. `PRINT USING
"#.######"` prints six decimals, since a plain `PRINT` shows only about
seven digits.

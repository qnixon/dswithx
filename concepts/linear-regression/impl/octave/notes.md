Octave can fit this line in one call. `polyfit(x, y, 1)` returns the slope
and intercept, 5.202961 and 42.225716, and the backslash solve
`[ones(n, 1) x] \ y` gives the same pair in the other order. `corr` gives r,
0.927659. We skip all three so the sums stay visible.

Whole-array arithmetic keeps those sums to one line each: `x - mean_x` is
the column of deviations, and `sum((x - mean_x) .* (y - mean_y))` is the
cross-product sum. The dots matter, because plain `*` would ask for a matrix
product of two 100-by-1 columns, which is an error. The two columns come from
the same `read_column` helper as descriptive statistics.

C's standard library has no regression, correlation, mean, or even `sum`
function, so there was nothing to skip: every total is a `for` loop. The
program reads each column with the same `read_column` helper as the
descriptive-statistics page, once for `hours` and once for `score`, and
pairs them by position: row `i` of the file is `xs[i]` and `ys[i]`.

The two passes are two loops. The first adds up the means; the second
collects all three sums of deviations at once. The count `n` is a `size_t`,
an unsigned integer, but dividing a `double` by it converts it to `double`
first, so `sum_x / n` needs no cast.

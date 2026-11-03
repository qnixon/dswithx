Free Pascal's `Math` unit has `Mean` and `TotalVariance`, the sum of
squared deviations, but no covariance, correlation, or regression
function, and we leave out the two it does have. Every sum is a `for`
loop over two arrays of doubles.

The program reads each column with the same `ReadColumn` helper as the
descriptive-statistics page, once for `hours` and once for `score`, and
pairs them by position: row `I` of the file is `Xs[I]` and `Ys[I]`. The
first loop adds up the means, and the second collects all three sums of
deviations at once. `Sqrt` is the only call from outside the program.

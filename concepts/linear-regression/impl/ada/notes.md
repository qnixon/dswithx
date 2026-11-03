Ada's standard library has no sum, mean, covariance, or regression
function, so every total is a `for` loop over two arrays. Ada 2022's
`'Reduce` attribute could fold a sum, but loops keep the two passes
clear.

We read each column with the same `Read_Column` and `Field` helpers as the
descriptive-statistics page, once for `hours` and once for `score`, and
pair them by position: row `I` of the file is `Xs (I)` and `Ys (I)`. The
first loop adds up both means, and the second collects all three sums of
deviations at once. The means, slope, and `R` are constants, declared once
their values are known. `Sqrt` is the only call from outside the program.

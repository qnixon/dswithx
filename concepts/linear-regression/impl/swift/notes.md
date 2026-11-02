Swift has no regression or correlation function, so we write out the two
passes the formulas need. The first pass takes the means with
`reduce(0, +)`, and the second sums the squared deviations and
cross-products. `zip(xs, ys)` pairs each `hours` value with its `score`,
and `squareRoot()`, a method on `Double`, finishes the correlation.

The same `readColumn` helper as descriptive statistics reads each column
by name, so the file is read twice. Swift won't divide a `Double` by an
`Int`, so the count becomes `Double(xs.count)` before it divides the sums.
Foundation, which ships with Swift, reads the file and formats six
decimals with `String(format:)`.

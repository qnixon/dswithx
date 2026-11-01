Go has no regression function, so the from-scratch version is the only
version. One loop builds all three sums at once: each pass computes the
deviations `dx` and `dy` and adds `dx * dx`, `dy * dy`, and `dx * dy`.
`var sxx, syy, sxy float64` declares them together, and Go starts every
number at zero, so they need no initial value.

The reader takes the column names as a variadic `...string` argument and
returns one slice per column, found by header name with `slices.Index`. As
everywhere in Go, the count is an `int` and must be converted with
`float64()` before it can divide a sum.

Each row is a `[Double]` with a leading 1 for the intercept, so `dot` is
one `zip`, `map`, and `reduce(0, +)`. A step builds the whole gradient
first, then replaces the weights with a new array,
`zip(weights, gradient).map { w, g in w - learningRate * g }`, so every
weight moves from the same gradient.

Watch the lengths. `zip` stops at the shorter array, so
`dot([1, 2, 3], [10, 20])` quietly gives 50 instead of an error: forget the
leading 1 on a test row and the prediction is just wrong. Foundation
supplies `exp`, `log`, and `String(format:)`. Swift has no logistic
regression, so there was no built-in to skip.

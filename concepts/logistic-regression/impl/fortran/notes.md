The training rows are a matrix `x` whose first column is all ones, for the
intercept. `matmul` and `transpose` are intrinsics, so each step is two
lines: `p = sigmoid(matmul(x, weights))`, then
`weights = weights - learning_rate * matmul(transpose(x), p - y) / n`. The
whole gradient is computed before any weight changes.

`sigmoid` is declared `elemental`: written for one number, it also applies
itself to every element of an array. Where Python's `math.exp` raises an
error on overflow, gfortran's `exp(1000)` returns `Infinity`, so `sigmoid`
gives 0 for very negative scores. Fortran has no logistic regression
intrinsic, and LAPACK isn't installed, so there was nothing to skip.

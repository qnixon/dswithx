`outer(z, 0:degree, "^")` builds the matrix of powers in one call, and
`t(z) %*% z` gives the normal equations. Our `gauss` function then runs
Gaussian elimination: `which.max` finds the pivot row, and
`m[c(col, pivot), ]` swaps two rows by indexing. Each elimination step
subtracts a whole row at once.

Base R could do all of this with `solve()`, or with `lm()` on
`poly(speed, 8, raw = TRUE)`; we avoided both. On this data,
`lm` gives the same train and test errors to six decimals, even on raw
speeds, because it uses a QR decomposition rather than the normal
equations.

We read each drive into an `(x, y)` tuple and sort it into a training or
test list. `fit` adds up the normal equations in a `[[Double]]`, and
`solve` appends b to each row, then runs Gaussian elimination with
partial pivoting. The pivot row is the largest entry found by `max` with
a comparison closure, and the swap is one call to `swapAt`.

Swift arrays are values, so the matrix `solve` changes is its own copy
and the caller's equations stay untouched. Apple's Accelerate framework
has a solver, but it isn't available in our Linux image.

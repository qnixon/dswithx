Julia writes this the way the math does. `corr = Z' * Z / (n - 1)` is the
correlation matrix, `M * v` is a power-iteration step, and deflation is
`corr - value_1 * pc_1 * pc_1'`, where `pc_1 * pc_1'` is an outer product
because `'` turns a column into a row.

The standard library already has the answer: `eigen` from `LinearAlgebra`,
with `cor` from `Statistics`, gives the same eigenvalues and loadings. But
`eigen` returned both vectors pointing the other way, with every loading
negative on the first. That's why every version here makes the first entry
positive.

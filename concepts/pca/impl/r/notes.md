R can do all of this in one call: `prcomp(x, scale. = TRUE)`, or
`eigen(cor(x))`. We avoided both, along with `scale()`, `sd()`, and `cor()`.
On this data, `prcomp` and `eigen` find the same two eigenvalues (2.496154
and 1.110197) and the same loadings, except that both return PC1 with every
sign flipped, so student 1 scores -1.712316 on it there. Either direction is
a valid eigenvector; we pick the one with a positive first entry.

Matrix arithmetic keeps the rest short. `t(z) %*% z / (n - 1)` builds the
whole correlation matrix at once, and `outer(v, v)` gives the table of
`v[i] * v[j]` that deflation subtracts.

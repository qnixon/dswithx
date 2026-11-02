`eigen` comes from `LinearAlgebra`, a Julia standard library, and finds
every eigenvalue and eigenvector of a matrix at once. `Statistics` supplies
`cor`, which builds the correlation matrix directly from the raw scores.

Wrapping the matrix in `Symmetric` tells `eigen` it can use the faster
symmetric method, which also guarantees real results. That method returns
the eigenvalues from smallest to largest, so `sortby = -` reverses the
order. Here both components come back with every sign flipped, so the
first-entry-positive rule is what makes them match.

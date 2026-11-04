Each drive becomes a `[speed, litres]` pair, sorted into train and test as
the lines are split. For each degree we fill the normal equations, then
`solve` runs Gaussian elimination on an augmented copy. At each column,
`max_by` finds the row with the largest entry, and a parallel assignment,
`m[a], m[b] = m[b], m[a]`, swaps the two rows.

`minmax` gives the training range in one call, and a lambda maps each speed
onto −1 to 1. The matrix gem's `Matrix#lup` could solve the system
directly, but it's a bundled gem, not part of the standard library, so we
leave it out.

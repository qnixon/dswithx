Octave has matrices built in, so most steps are one line. The correlation
matrix is `Z' * Z / (n - 1)`, and each power-iteration step is
`w = M * v` followed by `v = w / norm(w)`, where `norm` is the vector's
length. Deflation needs the outer product of the first component with
itself, and here that's just `pc_1 * pc_1'`, a column times a row.

Octave ships `eig`, `svd`, `cov`, and `corr`, which would do the real work,
so we skip them. We call our matrix `corr_matrix`, because a variable named
`corr` would hide the built-in function. Call it after that, and the error
message notes that the variable "shadows function".

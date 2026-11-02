Fortran was built for this kind of arithmetic. The correlation matrix is one
line, `matmul(transpose(z), z) / (n - 1)`, and each power-iteration step is
`v = matmul(m, v)` followed by `v = v / norm2(v)`, where `norm2`, the
vector's length, is a Fortran 2008 intrinsic. Deflation needs the outer
product of `pc_1` with itself, which we build with `spread`: it copies the
vector into the columns, or the rows, of a 4 by 4 matrix, and multiplying
the two element by element gives every `pc_1(i) * pc_1(j)`. Fortran has no
eigenvalue intrinsic, and LAPACK, the usual Fortran library for it, isn't
installed, so there was nothing to skip.

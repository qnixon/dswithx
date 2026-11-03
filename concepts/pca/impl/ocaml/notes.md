A matrix is an array of row arrays, so `corr.(i).(j)` reads row i, column
j, counting from 0. `mat_vec` maps each row to its dot product with the
vector. Power iteration is a `for` loop that sets
`v := normalize (mat_vec m !v)` 1,000 times: `v` is a `ref`, a mutable
box, where `!v` reads it and `:=` replaces it.

The built-in we skip doesn't exist here. OCaml's standard library has no
matrix module or eigenvalue routine, and `Matrix.mul` fails with
`Unbound module "Matrix"`. Owl, the usual numerical library, comes through
opam, but neither opam nor Owl is installed, so the correlation matrix,
deflation, and every product are written out.

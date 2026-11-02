A vector is a list of numbers and a matrix is a list of rows, so `mat-vec`
is one `mapcar` of `dot` over the rows, and `(apply #'mapcar #'list rows)`
turns rows into columns. Common Lisp has 2-D arrays too, read with
`(aref m i j)`, but lists need no index bookkeeping here. There's no
eigenvalue routine to skip.

Each power-iteration step builds a new list, and `top-eigenvector` returns
two values, the eigenvalue and the vector, which `multiple-value-bind`
catches by name. Flipping the sign is `(mapcar #'- v)`, since `-` with one
argument negates it.

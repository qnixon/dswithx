A vector is a plain list and the matrix is a list of row lists, so
`[lindex $corr $i $j]` reads row i, column j, and `mat_vec` is one `lmap`
that takes the dot product of each row with the vector. Power iteration is a
`for` loop that sets `v [normalize [mat_vec $m $v]]` 1000 times, and
deflation builds a second matrix row by row with `lappend`.

The built-in we skip doesn't exist here: Tcl's own commands have no matrix
type or eigen solver. Tcllib's `math::linearalgebra` package has one, but it
isn't installed, so `package require math::linearalgebra` fails with "can't
find package".

The augmented matrix is a list of row lists. `lindex $m $r $c` reads an
entry and `lset m $r $c` writes one in place, and swapping two rows is two
`lset` calls on whole rows. Lists are values, so `solve` changes only its
own copy, never the caller's.

The speeds are whole numbers, and Tcl's `/` rounds down when both sides are
integers, so the scale divides by `2.0`. There's no solver to skip: Tcl's
own commands have no matrix type, and Tcllib's `math::linearalgebra`, which
does, isn't installed.

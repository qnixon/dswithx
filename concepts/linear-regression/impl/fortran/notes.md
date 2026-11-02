Fortran has no regression or correlation intrinsic: asking gfortran for an
intrinsic named `mean`, `cor`, or `regress` is a compile error, so there was
nothing to skip. The sums are written out instead.

Whole-array arithmetic keeps them short. `x - mean_x` is the array of every
deviation, so `sum((x - mean_x)**2)` is one line, and
`dot_product(x - mean_x, y - mean_y)` adds the cross-products. Each column is
found by name in the header, and an internal `read` turns its text into a
number. The count `n` is an integer, but dividing a real sum by it promotes it
automatically, so `sum(x) / n` needs no conversion.

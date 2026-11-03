The matrix is an array of array refs, so `$corr[$i][$j]` reads row i,
column j, counting from 0, and assigning to it creates each row as needed.
Three small subs carry the linear algebra: `dot` sums products with `map`,
`mat_vec` takes the dot product of each row with the vector, and
`normalize` rescales to length 1. Power iteration is one line that
repeats `normalize(mat_vec($m, $v))` 1,000 times.

Perl's core has `sqrt` but no matrices or eigenvalues. CPAN's PDL and
Math::MatrixReal have both, but neither is installed, so we write the
steps out, with `sum` from List::Util as the only import.

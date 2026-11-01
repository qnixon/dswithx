Vectors are plain arrays and the matrix is an array of rows, so each step is
one line: `transpose` turns the rows into columns for the means and standard
deviations, `Array.new(k) { |i| ... }` builds the correlation matrix, and
power iteration is `STEPS.times { v = normalize(mat_vec(m, v)) }`.

The built-in we skip is `Matrix#eigensystem`, from the bundled `matrix` gem.
On this correlation matrix it found 2.496154 and 1.110197 too, but listed the
eigenvalues smallest first. Its eigenvector for 2.496154 matched ours, and
its one for 1.110197 pointed the opposite way, starting at -0.497992. As in
the other Ruby implementations, we also skip the `csv` gem and split lines
by hand.

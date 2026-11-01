Python's standard library has no matrix type and no eigenvalue routine, and
NumPy, where `numpy.linalg.eigh` would do this in one call, isn't
installed. So the matrices are lists of lists, and two small helpers do
the linear algebra: `mat_vec` multiplies a matrix by a vector with one
`sum` per row, and `dot` multiplies two vectors. Everything else is built
from those two.

The correlation matrix is one nested list comprehension, and deflation is
another. `top_eigenvector` runs for both components unchanged: the deflated
matrix just has a different largest eigenvalue.

`Eigensystem` comes with the matrix types in Annex G of the Ada standard,
so it's part of the standard library. Given a symmetric matrix, it fills
`Values` with every eigenvalue, largest first, and `Vectors` with the
matching eigenvectors as columns, replacing both power iteration and
deflation.

The rest is the from-scratch version: the same loops standardize the
scores, and `Transpose (Z) * Z` builds the correlation matrix. `Eigensystem`
returns the second component with every sign flipped, so `Component`
applies the sign rule, making each one's first entry positive.

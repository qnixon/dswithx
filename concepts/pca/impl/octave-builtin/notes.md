`eig` finds every eigenvalue and eigenvector of a matrix at once, so it
replaces both power iteration and deflation. Called as `[V, D] = eig(M)`,
it returns the eigenvectors as the columns of `V` and the eigenvalues on
the diagonal of `D`, smallest first. `sort` with `"descend"` puts the
largest first, and its second result reorders the columns to match.

`corr` builds the correlation matrix, and `mean` and `std` standardize
the scores for the first student's position. Here `eig` already returns
each component with a positive first entry, but we apply the sign rule
anyway, as the from-scratch version does.

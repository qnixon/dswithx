The 4 × 4 correlation matrix is a table of rows, each a table of entries,
so `WS-CORR(I, J)` reads like math, and a single `MOVE` copies the whole
matrix into the working copy that power iteration multiplies. Values are
fixed-point decimals with 18 places, and all 14 decimals we printed match
Python's doubles. Rounding doesn't build up over the 1000 normalizations,
because each step pulls the vector back toward the eigenvector: with only
9 places, the results still agree to about 1e-9. The program runs in about
13 milliseconds. GnuCOBOL has `MEAN`, `VARIANCE`, and `STANDARD-DEVIATION`,
which we skip, but nothing for matrices or eigenvectors. At 288 lines,
it's four times the 72-line Python.

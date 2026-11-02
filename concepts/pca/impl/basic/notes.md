The 4 × 4 correlation matrix is a 2-D array, `C(4, 4)`, and the two
components fill the rows of `PC(2, 4)`. Power iteration is the subroutine
at line 5000. It can't take arguments, so the caller copies the matrix into
`M` and sets `CI` to 1 or 2 to say which row to fill. Multiplying `M` by the
vector is another subroutine, at line 7000. There are no matrix or
eigenvector functions to avoid; even a vector's length is a loop and `SQR`.
`STR$(1)` gives `" 1"`, with a leading space, so the labels use `MID$` to
drop it. The whole run takes under a second.

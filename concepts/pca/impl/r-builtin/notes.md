`prcomp()` is base R's PCA. With `scale. = TRUE` it standardizes each
column first (the trailing dot is part of the argument's name), so its
components match the correlation matrix the from-scratch version builds.

It returns three pieces we use: `rotation`, with one component per column;
`sdev`, the standard deviation along each, whose square is the eigenvalue;
and `x`, every student's score on every component. `prcomp()` returns the
first component with all four signs negative, so we flip any column whose
first entry is negative, and flip the scores to match.

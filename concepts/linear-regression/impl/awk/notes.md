awk splits each line on `FS = ","` for you, so finding the `hours` and
`score` columns in the header takes one short loop, and the running totals
need no setup because every variable starts at zero. `sqrt` and `printf`
are built in, so the end of the program reads like the formulas.

The formulas need the means before the deviations, and awk reads a file
once, line by line. So we keep every pair in two arrays, `x[n]` and `y[n]`,
and do the fit in the `END` block after the last line. awk has no
regression function, so there was nothing to skip. The program sticks to
POSIX awk and runs unchanged on mawk, which the tests use, and on the awk
that ships with macOS.

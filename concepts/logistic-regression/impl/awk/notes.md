awk has no vectors or matrices, so every sum is a written-out loop. That
makes the update rule easy to see: one pass over the training rows adds up
`g0`, `g1`, and `g2`, and only after the pass do the three weights change.
`exp`, `log`, and `sqrt` are built in, which is all the math this needs.

The rows are kept in `x[i, j]`. awk has no true two-dimensional arrays; it
joins the two indexes with `SUBSEP` into one key. The fitting runs in `END`,
after the whole file is read. awk has no regression function, so there was
nothing to skip. It sticks to POSIX awk and runs on mawk and on macOS awk.

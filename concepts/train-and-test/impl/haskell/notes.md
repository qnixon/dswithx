A matrix is a list of rows, and the elimination is recursive rather than a
loop. `eliminate` takes out the row with the largest first entry (partial
pivoting), subtracts a multiple of it from every other row, and calls
itself on the smaller system that's left. Back substitution then works up
the triangle, one unknown per row.

Each normal-equation entry is a list comprehension summing `z ^ (i + j)`
over the training drives. Haskell's `^` takes a whole-number exponent and
multiplies, so no `**` is needed. Nothing here calls a fitting or solving
function: every step of the least-squares fit is written out.

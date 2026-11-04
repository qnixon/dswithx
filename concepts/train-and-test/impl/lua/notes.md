The augmented matrix is a table of row tables, indexed from 1, so entry `i`
of a row holds power `i - 1`. Swapping two rows is one multiple assignment:
`m[col], m[pivot]` on the left takes `m[pivot], m[col]`, which trades the two row references
without copying a number. `table.move` copies each row of the equations
into the matrix first, so the caller's stays as it was.

Elimination and back substitution are plain numeric `for` loops, and `^`
raises the scaled speeds to each power.

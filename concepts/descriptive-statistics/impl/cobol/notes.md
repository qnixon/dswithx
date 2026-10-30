COBOL does the arithmetic better than any other language here. Every number
is a fixed-point decimal with a declared size, `PIC S9(9)V9(6)`, so the sum
of the commutes is exactly 3561.3, with no floating-point rounding at all.
Its `SORT` statement works on an in-memory table, so the median is easy too.

Everything around the arithmetic is long. Each variable is declared up front
with its exact width, splitting a CSV line takes an `UNSTRING` loop, and
printing a number means moving it into an "edited" picture and trimming the
padding. The result runs about three times as long as the Python.

One trap: COBOL has had `VARIANCE` and `STANDARD-DEVIATION` functions since
1989, but they divide by n, not n − 1. Using them would print different
numbers from every other language on this page.

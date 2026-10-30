<!-- Placeholder text: to be written. -->

**Easy:** exact arithmetic. Every number is a fixed-point decimal with a
declared size, so the sum of the data is exactly 3561.3, with no
floating-point error. Sorting is easy too: COBOL's `SORT` statement works on
an in-memory table as well as on files.

**Hard:** everything around the arithmetic. Every variable is declared up
front with its exact width, splitting a CSV line takes an `UNSTRING` loop,
and printing a number means moving it into an "edited" picture like
`-(12)9.9(6)` and trimming the padding.

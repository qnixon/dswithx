<!-- Placeholder text: to be written. -->

**Easy:** count, sum, minimum, and maximum are core SQL aggregates, and
common table expressions (`WITH ...`) let each step be named and read top to
bottom like a script.

**Hard:** the median. SQL has no notion of "the middle row" until you number
the rows with a window function, `row_number() OVER (ORDER BY minutes)`, and
pick the middle positions. (The built-in `percentile_cont(0.5)` does it in one
call.)

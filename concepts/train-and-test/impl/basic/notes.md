There are no built-ins to skip here, so every step is a numbered block of
lines. The equations sit in a fixed `M(9, 10)` array, big enough for degree
8, with the right-hand side as the last column. Swapping two rows is a `FOR`
loop that trades one entry at a time through `T`. Powers come from repeated
multiplication, and predictions use Horner's rule.

Watch the loops. A `FOR` with an empty range still runs once in bwbasic:
`FOR R = 3 TO 2` runs its body with `R` = 3. So elimination and back
substitution, whose inner ranges are empty on the last row, use `WHILE`
loops instead.

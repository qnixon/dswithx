Points are pairs, `(Double, Double)`, and the assignment is a plain list of
cluster numbers. With no loops, `run` repeats by calling itself with the
moved centroids. Its previous assignment is a `Maybe [Int]`: `Nothing`
before the first pass, then `Just` the last list, so "nothing changed" is
one `==` between whole lists.

`nearest` numbers the centroids with `zip [0 ..]` and takes `minimumBy` on
squared distance. `minimumBy` keeps the first of equal values, so a tie goes
to the lower index; `maximumBy` keeps the last, so it would need care. The
exponents are typed `(2 :: Int)`, or `-Wall` warns that it guessed.

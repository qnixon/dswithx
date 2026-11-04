Each part becomes a `(Bool, Float64)` tuple, and one loop per threshold
sorts every part into true positives, false positives, false negatives, and
true negatives. In Julia, `/` on two `Int`s gives a `Float64`, so
`tp / (tp + fp)` needs no conversion; `div` is the integer division.

For the AUC, a single `for d in defective, g in good` loop visits all 33
times 167 pairs, scoring 2 for a win and 1 for a tie. `count(first, parts)`
counts the defective parts by applying `first` to each tuple.

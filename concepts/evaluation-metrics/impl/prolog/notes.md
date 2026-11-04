Each part becomes a term `Defective-Score`. Four clauses of `outcome/3`
say which cell of the confusion matrix a part lands in, and
`aggregate_all(count, ...)` counts the parts in each cell at a threshold.
Every metric is a ratio of those counts.

For the AUC, three clauses of `pair_points/3` give 2 for a win, 1 for a
tie (`=:=` compares numbers by value), and 0 for a loss, and
`aggregate_all` with `sum(Points)` adds them over every defective and good
pair, 33 times 167 of them. The total stays an integer until the last
division.

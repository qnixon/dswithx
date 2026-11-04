`read.csv()` reads both columns as numbers, and the code never loops over
parts. `score >= threshold` is a logical vector, and each count is the
`sum()` of two such vectors combined with `&`, since `TRUE` counts as 1.

For the AUC, `outer(bad, good, ">")` builds a 33 by 167 logical matrix
with one cell for every pair of a defective part and a good one. Twice its
sum plus the sum of the `"=="` matrix gives the points. The pROC package
has an `auc()` function, but it isn't installed.

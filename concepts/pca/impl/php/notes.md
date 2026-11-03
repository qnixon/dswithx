The matrix is an array of row arrays, so `$corr[$i][$j]` reads row i,
column j, counting from 0, and assigning to it creates each row as needed.
Three small functions carry the linear algebra: `dot` sums products with
`array_map` and `array_sum`, `mat_vec` takes the dot product of each row
with the vector, and `normalize` rescales to length 1. Power iteration
repeats `normalize(mat_vec($m, $v))` 1,000 times.

PHP has `sqrt` but no matrices or eigenvalues, so we write the steps out.
`array_column($z, $i)` pulls one subject's column out of every row, which
is how each correlation is built.

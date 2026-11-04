Each drive becomes a `[speed, litres]` pair, pushed onto the train or test
array by its `split` column. For each degree we fill the normal equations
with nested loops, then `solve` runs Gaussian elimination on an augmented
copy, swapping up the row with the largest entry in each column. A
destructuring assignment, `[m[a], m[b]] = [m[b], m[a]]`, swaps two rows in
one line.

Speeds are mapped onto −1 to 1 from the training range, which
`Math.min(...speeds)` and `Math.max(...speeds)` find by spreading the array
into arguments. JavaScript's `**` operator raises a negative `z` to a whole
power without trouble.

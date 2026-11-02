The tree is an array of `node` values, a derived type with a feature, a
threshold, the numbers of its two children, and a prediction. `grow` takes
a node number before it grows the children, so the table is already in
preorder and printing it is a plain loop. `grow` calls itself, and gfortran
14 rejects that unless the function is marked `recursive`, even with
`-std=f2018`. Rows are passed as lists of row numbers, and
`pack(rows, x(rows, f) <= threshold)` keeps the ones that go left. Logicals
compare with `.eqv.`, since `==` on them is an error. Fortran has no tree
or sort intrinsic, so the sort of distinct values is written out.

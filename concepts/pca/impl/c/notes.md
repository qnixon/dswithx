The correlation matrix is a plain `double corr[4][4]`, since the four
subjects fix its size, and the students' scores live in one block of
memory typed `double (*)[4]`, a pointer to rows of four, so `z[i][j]`
works while `realloc` grows it. The CSV columns are found by name after
`strtok` cuts each line at its commas.

C has no matrix product, so `mat_vec` writes one out as two nested loops,
and because a function can't return an array, it fills one the caller
passes in. Power iteration, deflation, and the sign rule are a few more
short loops.

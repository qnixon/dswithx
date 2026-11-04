We read each drive into a `Point` record and sort it into a training or
test list by its split column. `fit` adds up the normal equations in a
`double[][]`, and `solve` copies each row one entry longer to hold b,
then runs Gaussian elimination with partial pivoting.

Because a `double[][]` is an array of row arrays, the pivot swap trades
two references in three lines and copies no entries. Beyond `Math.pow`, `Math.abs`, and
`Math.sqrt`, every step is a loop we wrote.

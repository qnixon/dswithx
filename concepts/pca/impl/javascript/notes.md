Vectors are plain arrays and the matrix is an array of rows. Every step is a
`map`, which also passes each element's index, so
`corr.map((row, i) => row.map((x, j) => ...))` builds the deflated matrix
entry by entry. `sum` hands `reduce` a starting 0: without it, `reduce` on an
empty array throws a `TypeError`, "Reduce of empty array with no initial
value". Node has no matrix type and no eigenvalue routine; none of its
built-in modules exports anything named for a matrix, an eigenvector, or PCA,
and `DOMMatrix`, which browsers provide, is undefined in Node.

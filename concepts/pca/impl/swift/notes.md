Swift has no matrix type, so the correlation matrix is a `[[Double]]`, an
array of row arrays. `matVec` maps `dot` over the rows, and power
iteration is a loop that replaces `v` with `normalize(matVec(m, v))`.

Arrays are values, not references. We deflate by writing
`var deflated = corr` and then subtracting in place with
`deflated[i][j] -= ...`, and `corr` is left unchanged, rows and all. In
Java the same assignment would share the rows. The standard library has
no linear algebra or eigenvalue routine, so there was no built-in to skip,
and Apple's Accelerate framework isn't in this image: `import Accelerate`
fails with "no such module".

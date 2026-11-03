Ada's Annex G gives us `Real_Vector` and `Real_Matrix`, and we use their
`*` as a general tool, the way Fortran uses `matmul`: `Transpose (Z) * Z`
builds the correlation matrix, `M * V` is one power-iteration step, and
`abs V` is a vector's length. The same `*` on two vectors returns a number
or a matrix, whichever the context asks for, so `PC_1 * PC_1` is the
outer product that deflation subtracts. Annex G also has `Eigensystem`,
which finds the same components up to sign, but it performs the method
itself, so we leave it out. Alire crates aren't installed.

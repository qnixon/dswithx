The matrices are Annex G's `Real_Matrix` and `Real_Vector`, whose index
ranges we choose, so coefficients count from 0 like the powers. We use
their `Transpose` and `*` to build the normal equations and the
predictions, since multiplying matrices is a general tool.

Annex G also has `Solve`, which would solve the system in one call; we
skip it and write out Gaussian elimination instead. A 2-D array has no row
objects, so partial pivoting swaps two rows one entry at a time. An array
aggregate with a `for` inside maps every speed onto −1 to 1.

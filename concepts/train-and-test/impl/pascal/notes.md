The equations live in a fixed `TMatrix`, sized for degree 8, with the
right-hand side in its last column; lower degrees use its top-left corner.
`Solve` takes the matrix by value, so it works on its own copy, and swaps
two rows one entry at a time through `Temp`.

No installed unit has a linear solver to skip. Free Pascal's NumLib has
one, but it isn't installed in this image. With warnings treated as errors,
the compiler rejected a function result filled in a loop as possibly
uninitialized, so `Solve` clears its answer with `FillChar` first.

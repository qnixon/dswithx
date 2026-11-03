The correlation matrix is a fixed `array[1..4, 1..4] of Double`. In Pascal
the bounds are part of the type, so the subjects count from 1 while the
dynamic array of students counts from 0. No installed unit has an
eigenvalue routine, and we leave out the Math unit's `Mean` and `StdDev`,
so standardizing, power iteration, deflation, and the sign rule are short
loops. Unlike a C function, `MatVec` returns a whole fixed-size array.

Watch the bounds: range checks are off by default. `V[0]` on an
`array[1..4]` fails to compile when the 0 is a constant, but with a
variable index it runs without an error.

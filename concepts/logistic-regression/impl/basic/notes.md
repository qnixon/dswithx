The three weights are plain variables, `W0`, `W1`, and `W2`, and the
sigmoid is a one-line function, `DEF FNP(X1, X2)`. It reads the global
weights each time it's called, so it always predicts with the current
step's weights. Training rows go in a 2-D array, `A(200, 2)`, and test rows
in `B`, each sized up front with `DIM`. There's no mean, regression, or
matrix function to avoid: every sum is a `FOR` loop, and the only
built-ins used are `EXP`, `LOG`, and `SQR`. The 1000 steps over 150
students take about 4.5 seconds. Swapping `EXP` for a square barely
changes that, so the interpreter's loop, not the exponential, sets the
pace.

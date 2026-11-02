The training rows are a matrix `X` with a column of ones for the
intercept, so each step is two lines:
`errors = sigmoid(X * weights) - y`, then
`weights = weights - LEARNING_RATE * (X' * errors) / n`, where `X'` is the
transpose. The whole gradient is computed before any weight changes.

The trap is the dot in `1 ./ (1 + exp(-z))`. With a plain `/`, Octave
treats the vector as a system to solve: the first step quietly builds a 150
by 150 matrix, and the second stops with a "nonconformant arguments" error.
We skip optimizers such as `fminunc`. Core Octave has no `glmfit`, and the
statistics package isn't installed.

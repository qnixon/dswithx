This version looks like the math. The training rows are a matrix `X` with
a column of ones for the intercept, so each step is two lines:
`errors = sigmoid.(X * weights) .- y`, then
`weights -= LEARNING_RATE * (X' * errors) / n`, where `X'` is the
transpose. The whole gradient is computed before the weights change.

The trap is the dot in `sigmoid.(...)`. Without it, `sigmoid` gets a whole
vector and `exp` stops with a `MethodError`. Where Python's `math.exp`
raises an error above about 709, Julia's returns `Inf`, so `sigmoid` gives
0.0 for very negative scores. There's no logistic regression in the standard
library to skip.

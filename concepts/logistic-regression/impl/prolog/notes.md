A Prolog variable gets one value and keeps it, so nothing here updates
the weights. `step(Xs, Ys, Weights, Next)` relates one list of weights to
the next, and `descend` counts down from 1,000, passing `Next` along.
Because the recursive call comes last, Prolog reuses its stack frame: we
ran 20,000 steps inside a 2 MB stack. Every error comes from the old
weights before `Next` is built, so all three weights move from the same
gradient.

There's no logistic regression or matrix library in SWI-Prolog to skip.
The `[X, Y]>>Goal` lambdas come from `library(yall)`, and `transpose`,
which turns rows into columns, from `library(clpfd)`. Both ship with
SWI-Prolog.

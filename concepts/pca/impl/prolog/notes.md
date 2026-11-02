A vector is a list of numbers and a matrix is a list of rows, so
`mat_vec` is one `maplist` of `dot` over the rows, and `dot` is a
`foldl` that adds up products. `transpose`, from `library(clpfd)`, turns
the rows of scores into columns, and `library(yall)` supplies the
`[X, Y]>>Goal` lambdas; both ship with SWI-Prolog. There's no eigenvalue
or matrix library to skip.

Variables can't be reassigned, so each power-iteration step builds a new
list, and `power` counts down from 1,000, passing it along. The recursive
call comes last, so Prolog reuses its stack frame: a million steps ran
inside a 2 MB stack.

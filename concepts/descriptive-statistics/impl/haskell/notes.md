There are no loops here and no variable is ever changed. Every value in
`main` is defined once in a `let`, and the totals come from `sum`, which
folds the list into one number. The variance is a list comprehension,
`[(x - mean) ^ 2 | x <- values]`, which reads almost like the formula.

The plumbing is where Haskell asks for care. `length` returns an `Int`,
which can't divide a `Double`, so `fromIntegral` converts it. There's no
CSV reader in `base`, so `splitOnComma` splits each line with
`break`, calling itself on the rest. And `median` indexes the sorted list
with `!!`, which walks it from the start.

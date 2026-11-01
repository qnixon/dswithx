Every statistic here is one short expression over the whole column, with no
loops. `+/X` is the sum, and `+/(X-MEAN)*2` subtracts the mean from every
value, squares each difference, and adds them up. APL evaluates right to
left with no precedence, so `÷N-1` divides by `N-1`. `X[⍋X]` sorts: `⍋`
returns the order, and indexing applies it. The median averages the values
at the floor and ceiling of `(N+1)÷2`, which works for odd and even counts
alike.

APL has no mean, median, or variance primitives, so there is nothing to
avoid. The real work is output: `0 6⍕` writes 0.94 as `.940000` and a negative
with `¯`, so we add the zero and the `-` ourselves.

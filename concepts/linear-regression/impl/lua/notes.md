Lua reads each column into its own array, then pairs them by position.
There's no `zip`, so a numeric `for i = 1, n` loop uses one index for both
arrays: `xs[i]` and `ys[i]` come from the same row. That loop builds all
three sums at once, and `math.sqrt` turns them into r.

Lua's standard library has no regression, correlation, mean, or even
`sum`, so every total is a loop. There's no CSV reader or split function
either: `gmatch("[^,]+")`, a Lua pattern, finds each field between
commas, and `tonumber` turns it into a number. Remember that `/` always
gives a float, even when both sides are integers.

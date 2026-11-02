There's no loop and no weight that changes. `step` takes one list of
weights and returns the next, and `iterate (step xs ys) [0, 0, 0] !! 1000`
applies it 1,000 times: `iterate` builds the endless list of every step's
weights, and laziness means only the first 1,001 are ever made. Because
`step` computes all the errors from the old weights before building the new
list, every weight moves from the same gradient.

The training rows are a list of lists. `transpose` turns them into columns,
so each weight's gradient is one `dot` of the errors with a column. Each
CSV row becomes a function from a column name to its field, so
`r "hours"` reads like a lookup.

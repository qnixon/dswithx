Each student is a `struct` holding a fixed array of three inputs, the first
always 1 so that weight 0 acts as the intercept, plus the label. The
training and test rows go into two growable arrays that double with
`realloc`, and `strtok` cuts each CSV line at its commas.

Every step adds up the whole gradient in a nested loop over students and
weights, then moves all three weights at once. C has no vectors or matrix
products, so `predict` writes the weighted sum out as a loop. Watch the
last line: `correct / test.n` would be integer division, giving 0, so we
cast `correct` to `double` first.

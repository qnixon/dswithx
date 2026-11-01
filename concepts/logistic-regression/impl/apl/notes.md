Batch gradient descent is two matrix products. `XT+.×⍵` gives every
training row's w·x at once, and after the sigmoid and subtracting the
labels, `errors+.×XT` sums error × input for all three weights. So a
whole step is one line, `⍵-RATE×GRADIENT ⍵`, with no loop over rows.

The loop over steps needs no `∇` function either. The power operator `⍣`
applies a function a fixed number of times, so `(STEP⍣STEPS)3⍴0` runs all
1000 steps from zero weights. Prepending the intercept's 1 is `1,`, which
adds a column to the left of a table.

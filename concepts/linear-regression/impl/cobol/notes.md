COBOL does the arithmetic exactly. Every value is a fixed-point decimal
with a declared size, such as `PIC S9(12)V9(12)`. The inputs have one
decimal place, so the means and all three sums of squares come out exact,
with no floating-point rounding. The first rounding happens at the slope.
Each sum is one `COMPUTE` inside a `PERFORM VARYING` loop.

The catch is that precision is declared, not given. A `COMPUTE` truncates
to the target's picture unless you write `ROUNDED`. Everything around the
arithmetic is long too: `UNSTRING` splits each line, and finding two
columns by name and storing the pairs takes as much code as the regression.
At 154 lines, it's almost four times the Python. GnuCOBOL has `MEAN` and
`VARIANCE` functions but no regression or correlation function.

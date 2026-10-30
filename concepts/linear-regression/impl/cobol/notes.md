<!-- Placeholder text: to be written. -->

**Easy:** the formulas. Once the pairs are in a table, the sums of squared
deviations and cross-products are one `COMPUTE` each inside a
`PERFORM VARYING` loop, and `FUNCTION SQRT` handles the correlation. The input
sums are exact fixed-point decimals.

**Hard:** precision is something you declare, not something you get. A
`COMPUTE` truncates to the target's picture unless you say `ROUNDED`, so the
means, slope, and intercept are held to 12 decimal places to keep the printed
six digits right. Finding two columns by header name and storing the pairs
takes as much code as the regression itself.

R was built for exactly this, so the from-scratch version is the long way
around. `mean()`, `median()`, `var()`, and `sd()` are all built in, and
`var()` already divides by n − 1. We avoided them to show the arithmetic.

Even so, vectorization keeps it short. `values - mean_value` subtracts the
mean from every value at once, so the variance needs no loop, and one
`sprintf` call formats all eight results together. The trap is indexing:
R counts from 1, so the two middle values of 120 are `values[60]` and
`values[61]`.

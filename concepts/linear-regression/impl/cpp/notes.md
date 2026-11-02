Like the C version, this one reads `hours` and `score` with the same
`read_column` helper, once each, and pairs them by position: row `i` of the
file is `xs[i]` and `ys[i]`. C++ has no regression or correlation function,
so there's nothing to skip, but its `<numeric>` header replaces C's loops.
`std::accumulate` adds up each column for the means, a lambda subtracts the
mean from every value, and `std::inner_product`, which walks two ranges side
by side, gives all three sums of squares and cross-products.

Like `accumulate`, `inner_product` adds in the type of its starting value.
On 28.6, 43.8, and 11.5 dotted with themselves it returns 2867 from `0` and
2868.6499999999996 from `0.0`.

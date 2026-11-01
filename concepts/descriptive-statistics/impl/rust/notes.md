Rust makes you say what you mean about numbers. `values.sort()` won't
compile on `f64`, because NaN compares unequal to everything and so floats
have no total order; `sort_by(f64::total_cmp)` supplies one. Dividing a
float by the `usize` count is also a compile error, so each count is
converted with `as f64` first. And `sum()` sometimes needs its type spelled
out, as `sum::<f64>()`, before the compiler will accept it.

There was no built-in to skip: the standard library has no mean, median, or
variance at all. It has no CSV parser either, so we split each line on
commas and find the `minutes` column by its header name.

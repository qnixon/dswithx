Each drive becomes an `(f64, f64)` tuple, and the matrix is a
`Vec<Vec<f64>>`, so `m.swap(col, pivot)` exchanges two rows in one call.
Finding the pivot needs care: `f64` doesn't implement `Ord`, because NaN
has no place in a total order, so `max_by_key` on an `f64` doesn't
compile. We use `max_by` with `total_cmp` instead.

Powers come from `powi`, which raises to an `i32` exponent. The scaling
closure is passed to `fit` and `rmse` as `impl Fn(f64) -> f64`. No crates
are installed in this image, and the run uses `rustc` directly.

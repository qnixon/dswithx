Each part becomes a `(bool, f64)` tuple. One loop per threshold matches on
the pair `(flagged, defective)`, and the compiler checks that all four
cases are covered. The false-negative count is `fn_`, because `fn` is a
keyword and `let fn = 1` doesn't compile.

The counts are `u32`, so a small closure, `ratio`, converts both sides
with `as f64` before dividing. The AUC loops over all 33 times 167 pairs,
scoring 2 for a win and 1 for a tie in a `u64`. No crates are installed in
this image, and the run uses `rustc` directly.

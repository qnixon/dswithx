We never shuffle at random. Each split is a `u32` from 0 to 65,535 whose
binary digits mark the chosen plants, and `count_ones()` keeps the 12,870
numbers with exactly 8 bits set. For each one, an iterator chain filters the
plant positions whose bit is set and sums their grams.

The totals are `i64`, so `>=` never meets a near-tie, and floats appear only
in the printed means and p-value. The itertools crate has a combinations adapter, but no
crates are installed in this image, and the run uses `rustc` directly.

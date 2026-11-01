Rust's iterators carry the formulas. Each sum is a `map` followed by `sum`,
and `xs.iter().zip(&ys)` pairs every `hours` value with its `score` for the
cross-product sum, much as Python's `zip` does. The column lookup is a small
closure that finds a header name's position, called once for `hours` and
once for `score`.

Most of the extra length is reading the file. The standard library has no
CSV parser, so we split lines on commas and parse each field into an `f64`
ourselves. There was no built-in to skip, either: unlike Python and R, Rust
ships no regression or correlation function.

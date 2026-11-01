Rust's two map types each do a job here. A `HashMap` keyed by
`(feature, value, label)` tuples holds every count, and
`entry(key).or_default()` starts a missing count at zero. Reading is
stricter: indexing a `HashMap` with a key that isn't there panics, so we use
`get(...).unwrap_or(0)` for value-label pairs the training data never saw.

The label counts live in a `BTreeMap`, which keeps its keys sorted, so the
labels come out alphabetically. Only a strictly higher score replaces the
best, so an exact tie goes to the first label. The standard library has no
naive Bayes classifier, so there was no built-in to skip.

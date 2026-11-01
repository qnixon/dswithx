Like Python, Rust sorts all 150 training seeds for every test seed. `sort_by`
is stable, so seeds at an equal distance keep file order, and `total_cmp`
compares the `f64` distances, since floats aren't `Ord`. We sort references
to the seeds, so nothing is copied.

The vote takes more care. Rust has no counter type, so we keep a short list
of (label, count) pairs in first-seen order. Then we pick the winner by hand,
because `max_by_key` returns the last of equal maximums, not the first.
`select_nth_unstable_by` would find the five nearest without sorting the
rest, but it isn't stable, so ties would lose file order.

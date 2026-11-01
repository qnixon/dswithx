The neighbor search is a chain of array methods: `map` pairs each training
seed with its distance, `toSorted` orders the pairs without changing
`train`, and `slice(0, K)` keeps the nearest five. JavaScript's `sort` is
stable, so seeds at an equal distance keep file order without the index
tie-breaker Ruby needs. The comparator matters: with none, `sort` compares
values as strings.

There is no `Counter`, so the vote is counted in a `Map`, which keeps keys
in insertion order. Taking the first label to reach the top count sends a
tied vote to the label seen first among the nearest, as in Python and Ruby.
The standard library has no kNN classifier to skip.

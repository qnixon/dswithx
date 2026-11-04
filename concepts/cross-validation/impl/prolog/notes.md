The kNN classifier is the one from the k-nearest neighbors page, with `K`
passed in: `keysort` orders the `Distance-Variety` pairs stably, so equal
distances keep file order. Each fold comes from `append`, which splits a
list in two once you fix the first part's length. We split off the rows
before the fold, then the fold's 30, and join what's left into `Rest`.

There are no loops. `between(1, 15, K)` generates each k, and
`K mod 2 =:= 1` keeps the odd ones. `findall` collects the per-fold
counts, and `sum_list` adds them. A recursive `best` keeps a new k only
when it's strictly better. SWI-Prolog has no cross-validation library to
avoid.

OCaml keeps each seed as a record, `{ len; wid; variety }`, so `s.len`
reads like a field. For every test seed, `List.stable_sort` orders the
training seeds by distance, and we keep the first five. Stable matters:
`Array.sort` is a heap sort, and a run shows it reorders equal keys, while
`stable_sort` is guaranteed to keep equal distances in file order.

OCaml has no counter type, kNN, or distance function. Votes go in an
association list of `(variety, count)` pairs, and a recursive function
adds one vote at a time. The distance is written out with `sqrt` and
`**`.

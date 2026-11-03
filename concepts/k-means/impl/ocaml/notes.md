Each point is a record, `{ x : float; y : float }`, and the assignment is
an array of cluster numbers. OCaml has `while` loops, but the usual way to
repeat is recursion, so `run` calls itself with the moved centroids. Its
previous assignment is an option: `None` before the first pass, then
`Some` the last array. OCaml's `=` compares arrays element by element, so
"nothing changed" is one `previous = Some assignment`.

The standard library has no k-means, so the means and the
nearest-centroid search are written out. `hypot` exists, but squared
distance ranks centroids the same way without a square root. A tie goes
to the lower index, since only a strictly smaller distance replaces the
best.

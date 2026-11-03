Free Pascal has no kNN classifier, and the dictionary in
`Generics.Collections` won't compile with warnings as errors, so we count
votes the way C does: for each of the five nearest labels, a loop counts
how many of the five share it, compared with `=`, which compares a
string's text.

A `TSeed` record holds a seed's length, width, and variety. For each test
seed we fill an array of distance-and-row records and sort it with
`TArrayHelper.Sort`, passing a comparison function with `@`. That sort is
a quicksort and doesn't keep equal elements in file order, so the
comparison breaks distance ties by row number.

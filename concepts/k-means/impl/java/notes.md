A one-line `Point` record holds each pair, and Java writes the constructor,
the `x()` and `y()` accessors, and `equals` for us. `Math.hypot` gives the
distance, and a loop with a strict `<` picks the nearest centroid, so a tie
would go to the lower index. Each pass builds a fresh `int[]` of
assignments, and `Arrays.equals` compares it with the last one. Don't use
`==` or `.equals` on arrays: both ask whether the two names point at the same
array, so equal assignments would never match. Against the `null`
we start with, `Arrays.equals` is false, so the first pass always continues.
Records can't change, so a moving centroid is a new `Point`, and there is no
built-in clustering to skip.

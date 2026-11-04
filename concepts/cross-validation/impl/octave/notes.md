The classifier from the k-nearest neighbors page becomes a function,
`count_correct`, that takes the query seeds, the training seeds, and `K`.
Each fold is a logical mask: `held = false(n, 1)` starts with all 150 rows
unmarked, and setting one block of 30 to `true` marks the fold. Indexing a
column with `held` picks the held-out rows, and `~held` picks the other
120. Indexing returns a copy, so the training columns never change.

Core Octave has no `cvpartition`, `crossval`, or `fitcknn`. Those come with
the Octave Forge statistics package, which isn't installed.

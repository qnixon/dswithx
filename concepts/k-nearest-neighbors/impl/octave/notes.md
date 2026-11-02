For each test seed, one line computes the distance to all 150 training seeds
at once, as a column, with `.^` and `sqrt`. `[~, order] = sort(d)` then
returns the positions of the sorted distances, and the first five are the
neighbors. Octave's `help sort` says equal elements keep their original
order, so a tie goes to the earlier training row.

There's no counter type, so we count votes with `strcmp`, which compares a
whole cell array of labels with one string and returns a mask to `sum`.
`max` returns the first position of the largest count. Core Octave has
no `knnsearch` or `fitcknn`, and the statistics package isn't installed.

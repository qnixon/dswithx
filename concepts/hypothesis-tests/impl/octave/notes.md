There's no loop over the splits. `nchoosek(1:16, 8)` returns all 12,870
choices of 8 plant positions as rows of a 12,870-by-8 matrix, in dictionary
order. Indexing the grams column with that matrix gives a matrix of grams
the same shape, and `sum(..., 2)` totals each row, so one line yields every
relabeled compost total.

We compare whole-number totals rather than means, so `>=` never meets a
floating-point near-tie. `nchoosek` ships with core Octave and only lists
the choices; the counting is ours. Octave Forge packages, such as
statistics, aren't installed.

We never shuffle at random. `chosen_total/3` has two clauses for each
plant, one that chooses it and one that skips it, so backtracking walks
every way to choose 8 of the 16 plants, 12,870 in all, and the p-value is
exact. `aggregate_all(count, ...)` counts the splits, and counts again the
ones with `abs(D) >= abs(Observed)`.

The totals are integers, so the 6 exact ties all count. `library(lists)`
has `subseq/3`, but it walks all 65,536 subsets, so we'd still filter by
size.

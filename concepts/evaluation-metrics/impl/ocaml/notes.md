Each part becomes a `(bool, float)` pair. One pass per threshold matches
on `(flagged, defective)` to pick which of four `ref` counters to bump:
true positives, false positives, false negatives, or true negatives.
Every metric is a ratio of those counts.

OCaml never mixes `int` and `float`, so a small `ratio` helper converts
both counts with `float_of_int` and divides with `/.`. The AUC walks every
defective score against every good one, 33 times 167 pairs, adding 2 for a
win and 1 for a tie, so the total stays a whole number until the end.

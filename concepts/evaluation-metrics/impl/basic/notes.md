The parts live in two fixed arrays, `DF` for the label and `SC` for the
score. A subroutine at line 2000 takes the threshold in `TH` and its name
in `SF$`, then counts true positives, false positives, false negatives,
and true negatives with four `IF` lines joined by `AND`, since bwbasic
mishandles an `IF` nested inside another.

The AUC loops over every pair of parts and keeps those with a defective
first and a good second, scoring 2 for a win and 1 for a tie. That's
40,000 checks to use 5,511 pairs, still instant.

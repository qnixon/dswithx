We split each line on commas and turn every row into a pair of a boolean
and a Float. `Float()` raises an error on text that isn't a number, where
`to_f` would quietly return `0.0`. One loop per threshold sorts every part
into true positives, false positives, false negatives, and true negatives.

For the AUC, `partition(&:first)` splits the parts into defective and good
in one call, and two nested loops compare all 33 times 167 pairs, scoring 2
for a win and 1 for a tie. In Ruby, `3 / 4` is `0`, so every ratio uses
`fdiv`.

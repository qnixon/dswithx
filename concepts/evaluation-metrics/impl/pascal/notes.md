Each part is a record with a `Boolean` label and a `Double` score, held in
a dynamic array. One loop per threshold sorts every part into one of four
counts: true positives, false positives, false negatives, and true
negatives. Every metric is a ratio of those counts.

The AUC uses two nested `for ... in` loops over the parts, skipping the
wrong labels, and scores 2 for a win and 1 for a tie in an `Integer`. The
threshold is a `Double` parameter, so it's rounded the same way as the
scores it's compared with. `/` gives a decimal even between integers.

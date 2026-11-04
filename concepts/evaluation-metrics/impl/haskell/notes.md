Each part becomes a `(Bool, Double)` pair. One small function, `count`,
takes a flagged value and a defective value and counts the parts with
that combination, so the four cells of the confusion matrix are four calls
to it. Every metric is a ratio of those counts.

The AUC is a list comprehension over every defective score and every good
score, 33 times 167 pairs. `compare` returns `GT`, `EQ`, or `LT`, and
pattern matching turns those into 2, 1, and 0 points, so the total stays
an `Int` until the last division.

Each seed is a tuple, `((length, width), variety)`, and the comprehension
`[seed | ("train", seed) <- seeds]` keeps only the rows whose split matches,
quietly skipping the rest. To find the 5 nearest, we sort all 150 training
seeds with `sortOn`, keyed on distance, and `take 5`. `sortOn` is stable, so
seeds at exactly equal distances keep their file order, and it computes each
key once.

For the vote, `nub` lists each variety once and `filter` counts it. We pick
the winner with `foldl1` rather than `maximumBy`, which returns the last of
equal counts, not the first. No kNN function is called.

The tree is a plain term: `leaf(yes)`, or `split(Feature, Threshold, Left,
Right)` with two more trees inside, so `print` shows the whole model on one
line. The library has red-black trees for lookups but no decision tree.
`grow` is a recursive relation whose split clause holds when both children
are trees grown from each side, and `predict` has one clause per kind of
node, picked by matching the term. `candidate` yields thresholds on
backtracking, `sort` keeps each distinct value once, and `foldl` keeps only
a strictly lower score, so the first split tried wins ties. One trap: we
count leaves with `include(is_leaf, ...)`, because `include(=(leaf(_)),
...)` binds the `_` to the first leaf's label and finds 3 leaves, not 7.

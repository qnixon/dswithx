The tree is a plain nested list: a leaf is `(:leaf t)` or `(:leaf nil)`, and
a split is `(:split feature threshold left right)`. `predict` takes a node
apart with `ecase` and `destructuring-bind`. Because the tree is ordinary
list data, you can print it with `~s`, read it back, and `equal` calls the
two the same. `grow` calls itself on each side, and `best-split` loops over
each feature's midpoints, keeping only a strictly lower score, so the first
split tried wins ties. The standard has no tree to avoid. Watch the names,
though: `*features*` belongs to Common Lisp, and redefining it stops the
compiler with a package lock error.

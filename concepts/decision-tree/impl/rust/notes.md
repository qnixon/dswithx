The tree is an enum: a `Node` is either a `Leaf(bool)` or a `Split` with a
feature, a threshold, and two children. The children are `Box<Node>`; without
the box, rustc rejects the type with "recursive type `Node` has infinite
size". Every `match` on a node must cover both variants, so dropping the
`Leaf` arm from `predict` is a compile error, "non-exhaustive patterns". The
days are borrowed, not copied: each node works on a `Vec<&Day>`. Sorting the
feature values takes `sort_by(f64::total_cmp)`, because `sort()` needs `Ord`,
which `f64` lacks, and `dedup` then drops the repeats. The standard library
has no decision tree, so there was no built-in to skip.

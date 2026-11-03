The tree is a `TNode` record with a feature, a threshold, a prediction,
and two children of type `PNode`, declared as `^TNode`, a pointer to a
node. Pascal lets `PNode` name `TNode` before it is declared, but only
within the same `type` section. A leaf is a node whose children are
`nil`. `Grow` calls itself on each side, getting each node from `New`,
and `FreeTree` hands every node back with `Dispose`, children first.
The run-time library has no tree or classifier, so there was none to
skip. To list a feature's distinct values, we sort with
`TArrayHelper<Double>.Sort` and drop repeats in one pass.

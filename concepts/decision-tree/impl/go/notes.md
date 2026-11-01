One `node` struct serves for both kinds of node, and the children are
pointers, `left, right *node`. A leaf is a node whose children are `nil`; its
`feature` and `threshold` keep their zero values and are never read. The
one-line method `isLeaf` gives that check a name. To list the distinct values
of a feature, we sort with `slices.Sort` and then call `slices.Compact`, which
removes only repeats that sit next to each other: on the unsorted
`[3 1 3 2 2]` it returns `[3 1 3 2]`. The only decision tree in Go's standard
library is an unexported one in `net/http` that matches requests to
patterns, so there was no classifier to skip.

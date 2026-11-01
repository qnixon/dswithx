The tree is plain objects with no class: a leaf is `{ label }` and a split is
`{ feature, threshold, left, right }`, so `"label" in node` tells them apart.
Printing walks the tree with a generator, `function* preorder`, which yields
a node and then hands off to each subtree with `yield*`, and a `for...of`
loop numbers the nodes as they arrive. A `Set` drops repeated values before
sorting. Leave out the comparator and `sort()` compares the numbers as
strings, putting 1013.7 before 999.2. On this data the tree still comes out
the same, but pressure would be tried at 1010, the midpoint of two values
that aren't neighbors. None of Node's built-in modules is a decision tree.

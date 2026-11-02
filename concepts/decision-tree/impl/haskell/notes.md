The tree is an algebraic data type, `data Tree = Leaf Bool | Split Int
Double Tree Tree`, which names itself with no boxes or pointers. `predict`
and `describe` each have one equation per kind of node, so drop the `Leaf`
equation and GHC's `-Wall` reports "Pattern match(es) are non-exhaustive",
which `-Werror` makes fatal. `grow` calls itself on each side, and its
stopping rules are guards tried from top to bottom. For the split search,
`minimumBy` keeps the first of several equal scores, so the first split
tried wins ties. To number nodes, `preorder` flattens the tree into a list
and `zipWith` pairs it with `[1 ..]`. Base has no decision tree, so there
was no built-in to skip.

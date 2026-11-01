APL has no tree type, so we keep the tree as four flat vectors, one item
per node in preorder: a feature number (0 for a leaf), a threshold, a
prediction, and the right child's index. A left child always comes next,
so `GROW` appends a node, recurses left, and then records where the right
side starts.

The split search is array style. `V∘.≤T` builds a table of days by
thresholds, `+⌿` and `Y+.×` count every threshold's left side at once, and
`⍳` finds the first minimum. GNU APL 2.0 rejects the shorthand `FEAT,←0`
and dfn guards like `{⍵=0:1 ⋄ 2}`, so we write `FEAT←FEAT,0` and walk the
tree with a `∇` loop. There is no tree built-in to avoid.

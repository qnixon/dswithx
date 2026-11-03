The tree is a variant record, `Node (Is_Leaf : Boolean)`: the
discriminant, fixed when `new` makes a node, decides whether it holds a
prediction or a feature, a threshold, and two `Node_Access` children, and
reading `Left` on a leaf raises `Constraint_Error`. We chose it over the
`Indefinite_Multiway_Trees` in `Ada.Containers`, since a split has exactly
two sides. Because `Node_Access` names `Node` before its fields exist, Ada
needs the incomplete declaration `type Node (Is_Leaf : Boolean);` first.
`Grow` calls itself on each side, and the split search tries each
threshold in turn. Ada has no classifier, so there was none to
skip; we sort each feature with `Generic_Array_Sort` and skip repeats.

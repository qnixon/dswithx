The tree uses Julia's types. `Leaf` and `Split` are both subtypes of an
abstract `Node`, and `predict`, `show_tree`, and `count_leaves` each have
one method per type. Julia chooses the method from the node's type at run
time (multiple dispatch), so none of them checks what kind of node it has.

`show_tree` prints in preorder by passing the node number down and
returning the next one: `show_tree(node.right, show_tree(node.left, k + 1))`.
Neither Base nor `Statistics` has a decision tree, and the DecisionTree.jl
package isn't installed, so there was nothing to skip.

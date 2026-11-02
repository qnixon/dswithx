Like C's version, the tree is one `struct Node` with a feature, a threshold,
a label, and two children, and a leaf is a node with no children. Here the
children are `std::unique_ptr<Node>`, which owns the node it points to and
deletes it when it goes out of scope, so there's no `malloc`, no `free`, and
no `free_tree`: when `main` ends, the whole tree goes with the root. A
`unique_ptr` can't be copied, only moved, so each node has one owner.
`grow` calls itself on each side, and we let a `std::set` sort each
feature's values and drop repeats. C++ has no tree or classifier to skip.

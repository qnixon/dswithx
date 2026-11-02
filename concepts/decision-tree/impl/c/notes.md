The tree is a `struct node` with a feature, a threshold, a label, and two
child pointers, `struct node *left, *right`. A struct can't hold a copy of
itself, only a pointer to one, and a leaf is a node whose children are
`NULL`. `grow` calls itself on each side, getting every node from `malloc`
and copying each side's days into fresh arrays, which it frees once the
children are built. Nothing cleans up for you, so `free_tree` releases the
children before their parent. To list a feature's distinct values, we sort
with `qsort` and drop repeats in one pass. C has no tree or classifier in
its standard library, so there was none to skip.

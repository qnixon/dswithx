Since every Tcl value is a string, we hold the tree as a nested list: a
leaf is `{leaf yes}`, and a split is `{split feature threshold LEFT RIGHT}`,
where each side is another tree. `grow` calls itself on each side, and
`lindex` takes several indexes at once, so `[lindex $tree 4 3 1]` walks
down into a branch. `lsort -real -unique` gives each feature's distinct
values, and you divide neighbors by `2.0`, not `2`, because
`(63 + 64) / 2` is 63. `upvar` lets the printing proc count leaves in its
caller. Tcllib's `struct::tree` isn't installed, and Tcl has no decision
tree, so the split search is a plain loop.

Perl has no decision tree, and no CPAN module is installed, so we grow the
tree from hash references. A leaf is `{ leaf => 'yes' }`, and a split holds
`feature`, `threshold`, `left`, and `right`, where each side is another hash
ref. `grow` calls itself on each side, and `predict` walks down until it
reaches a node with a `leaf` key.

A hash's keys also make a set, which the split search uses to collect each
feature's distinct values before `sort { $a <=> $b }` orders them. You count
matches with `grep` itself: in scalar context it returns how many items
passed, so no counting loop is needed.

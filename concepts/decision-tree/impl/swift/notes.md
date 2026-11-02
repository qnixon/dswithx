The tree is an enum: a `Node` is either `.leaf(Bool)` or `.split` with a
feature, a threshold, and two children. Because the enum holds itself, we
mark it `indirect`, and Swift stores the children behind references it
manages, with no `Box` to write; leave the keyword off and swiftc stops with
"recursive enum 'Node' is not marked 'indirect'". A `switch` on a node must
cover both cases, so dropping `.leaf` from `predict` fails with "switch must
be exhaustive". `grow` calls itself on each side. Each feature's values go
into a `Set`, which drops repeats, then `sorted()`, and we try the midpoint
of each neighboring pair. Swift has no decision tree, so there was no
built-in to skip.

Tcl keeps each seed as a small list, `{length width variety}`, and
`lassign` unpacks it into variables. For every test seed we pair each
training seed's distance with its label, then `lsort -real -index 0` sorts
those pairs by distance as numbers. Without `-real`, `lsort` would compare
text and put 10 before 9. Because `lsort` is stable, equal distances keep
file order, and `lrange` keeps the first five.

A dict counts the vote: `dict incr` starts a missing label at 0. Tcl has
no kNN or distance command, so the distance is written out with `sqrt`,
though `expr` also offers `hypot`.

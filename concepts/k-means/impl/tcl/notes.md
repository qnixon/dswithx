Each point is a two-element list, and `lassign` unpacks it into x and y.
`hypot` in `expr` gives the distance, and `nearest` replaces its best only
on a strictly smaller distance, so a tie keeps the lower index. Because
every Tcl list is also a string, `$new_assignment eq $assignment` compares
the whole assignment in one test, which is how we notice nothing changed.

`foreach p $points a $assignment` walks the points and their clusters side
by side, and `lsearch -all` returns every index in a cluster, so its
`llength` is the cluster's size. Tcl has no clustering or statistics
commands to avoid, and Tcllib, with its matrix and statistics packages,
isn't installed.

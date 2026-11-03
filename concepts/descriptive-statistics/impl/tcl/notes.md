In Tcl, every value is a string, and commands do all the work. `set`
assigns, `foreach` loops, and arithmetic happens only inside `expr`. Square
brackets run a command and put its result in place, so
`[lindex $values end]` reads the last value.

Tcl's own commands have no mean, median, or variance. Tcllib has them in
`math::statistics`, but it isn't installed, so each is a loop. Sorting is a
general tool: `lsort -real` orders the values as numbers, since a plain
`lsort` compares text and would put 10 before 2. `split` cuts each line at
its commas, and `format %.6f` prints six decimals.

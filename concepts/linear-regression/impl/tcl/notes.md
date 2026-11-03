Tcl reads each column on its own with `read_column`, then pairs them in
one loop. `foreach x $xs y $ys` walks both lists side by side, so each pass
gets one `hours` value and the `score` from the same row. That loop builds
all three sums at once, and `expr` turns them into the slope, intercept,
and r.

Tcl's own commands have no regression, correlation, or even mean. Tcllib
has them in `math::statistics`, but it isn't installed, so each sum is
written out. One thing to know about that two-list `foreach`: if one list
runs short, Tcl pads it with empty strings instead of stopping, so both
columns need the same length.

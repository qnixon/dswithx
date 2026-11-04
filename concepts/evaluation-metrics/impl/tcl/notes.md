Each part is a two-element list of a label and a score, and `lassign`
unpacks it into two variables. One loop per threshold sorts every part
into one of four counts: true positives, false positives, false negatives,
and true negatives. Every metric is a ratio of those counts.

The scores stay strings, as everything in Tcl does, and `expr` compares
them as numbers when they look like numbers, so ties stay ties. Between two
integers, `/` rounds down, so the ratios use `double()` first. Tcllib
isn't installed.

Each example is a two-element list, the feature values and the label, and
`lassign` unpacks it into separate variables. A `for` loop takes the 1000
steps. Inside it, `foreach x $xs y $ys` walks the inputs and labels side by
side, adding each error times input to a running gradient, and then `lmap`
builds the new weights from the old ones, so every weight moves by the same
gradient.

Tcl's built-in commands include no regression, classifier, or matrix type,
so there was no built-in to skip; `sigmoid`, `dot`, and `scale` are short
procs. The accuracy uses `double($correct)`, since `37 / 50` is integer
division in Tcl and gives 0.

A `point` struct with `x` and `y` fields keeps the loop readable, and
`math.Hypot` gives the distance. The nearest centroid comes from a loop with
a strict `<`, so a tie would go to the lower index. `slices.Equal` tells us
when the assignments stopped changing; it treats the `nil` slice we start
with as unequal to any 150 assignments, so the first pass always continues.

The trap is aliasing. `points[:3]` isn't a copy: it shares memory with
`points`, so moving a centroid would overwrite a data point. `slices.Clone`
makes a real copy. As in Python, an empty cluster keeps its old centroid,
and there is no built-in clustering to skip.

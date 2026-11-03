OCaml reads each column into its own list, then `List.map2` walks the two
lists side by side, so each `hours` value meets the `score` on the same
row. If the lists ever differed in length, `map2` would raise
`Invalid_argument` rather than drop the extra values.

OCaml's standard library has no regression, correlation, mean, or even
`sum`; `List.sum` doesn't exist, so we write a one-line `sum` with
`List.fold_left ( +. )`. Floats get their own operators, `+.`, `-.`,
`*.`, and `/.`, and `float_of_int` turns the count into a float before we
divide. `sqrt` turns the sums into r.

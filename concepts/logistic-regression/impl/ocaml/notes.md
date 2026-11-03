The weights are an array, and no step changes it. `step` computes every
error from the old weights, then `Array.mapi` builds the new array, so
every weight moves from the same gradient. A recursive `descend` repeats
`step` 1,000 times and hands back the last array.

OCaml's standard library has no regression, classifier, or matrix type,
so `sigmoid`, `dot`, and `sd` are short functions. `dot` pairs two arrays
with `Array.map2`, which raises `Invalid_argument` if their lengths
differ. The label is read as a float, since `1 - y` with a float `y`
won't compile; it has to be `1. -. y`. `List.partition` splits the rows
into training and test sets in one pass.

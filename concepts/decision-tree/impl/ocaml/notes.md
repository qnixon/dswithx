OCaml's standard library has no decision tree, and no opam package is
installed, so the split search, the growing, and the predicting are all
written out. The tree is a variant type: `Leaf of string`, or `Split` with
an inline record of a feature, a threshold, and two subtrees. The type names
itself, with no pointers or boxes.

`grow` is marked `let rec`, because without it OCaml won't let a function
call itself. `predict` matches on both kinds of node, and a match that
leaves one out fails the build here, since every warning is an error.
`List.sort_uniq` sorts each feature's values and drops repeats, and a fold
keeps the first lowest score.

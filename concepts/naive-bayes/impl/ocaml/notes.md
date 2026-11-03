We count training rows into `Hashtbl`, the standard library's hash table.
Value counts are keyed by a `(feature, value, label)` tuple, which works
because `Hashtbl` hashes and compares keys by value, not by identity.
`Hashtbl.find_opt` returns `None` for a key never seen, so `bump` and
`count_of` start each count at zero. Each row is an association list of
(column, value) pairs, searched with `List.assoc`.

OCaml has no classifier or counting helper, so the smoothing and log
scores are written out. `Hashtbl` keeps its keys in no useful order, so
the labels are sorted first, and only a strictly higher score replaces
the best: an exact tie goes to the alphabetically first label.

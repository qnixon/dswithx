Each seed is a `struct` holding its two measurements and its variety. For
every test seed we sort all 150 training seeds with `sorted(by:)`, which
the standard library's own documentation in the image calls "guaranteed to
be stable", so equal distances keep file order. For the 0.13 mm pair,
Swift gets the same 0.1299999999999999 and 0.13000000000000037 as Python.

Swift has no counter type, so a `Dictionary` counts the votes:
`counts[label, default: 0] += 1` starts a new label at zero. A
dictionary's order changes from run to run, so we pick the winner by
walking the five neighbors nearest first, and a tie would go to the label
met first.

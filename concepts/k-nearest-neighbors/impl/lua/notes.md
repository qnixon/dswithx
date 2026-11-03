Lua keeps each seed as a table with named fields, `{len, wid, label}`, so
`seed.len` reads like a record. For every test seed we score each training
seed's distance, then `table.sort` orders them with our own comparison.
That sort isn't stable, so equal distances could come out in any order;
the comparison breaks ties by row number to keep the earlier seed.

Lua has no counter type, kNN, or distance function. Votes go in a table
keyed by label: a missing key reads as `nil`, so `(votes[label] or 0) + 1`
starts each count at 1. The distance is written out with `math.sqrt` and `^`.

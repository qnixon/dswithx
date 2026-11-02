We turn every training seed into a `Distance-Variety` pair and `keysort`
them. `keysort` is stable and keeps repeated keys, so seeds at exactly equal
distances stay in file order; `sort/2` would drop pairs that are entirely
equal. To take the nearest five, we ask for a list of length 5 that
`append` can find at the front of the sorted pairs.

There's no kNN classifier or counter type. Here `sort/2` dropping repeats
helps: it lists each variety once, `aggregate_all(count, ...)` counts its
votes, and `max_member` picks the winner. The correct count is
`aggregate_all` again, over the test seeds whose vote matches.

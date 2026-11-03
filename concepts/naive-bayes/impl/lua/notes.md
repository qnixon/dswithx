We count with tables. A key that was never set reads as `nil`, so
`(counts[k] or 0) + 1` starts each count at zero. A table can be a key,
but it matches by identity: `t[{1}] = 5` followed by `t[{1}]` gives `nil`,
because the two `{1}`s are different tables. So we join the feature,
value, and label into one string, such as `"has_link|yes|spam"`, which
matches by value.

`#` counts only a table's 1, 2, 3, ... part, so the set of distinct values
is counted with `pairs`. `pairs` has no fixed order, so the labels are
sorted first, and only a strictly higher score wins, so a tie goes to the
first. Lua has no classifier to skip.

Lua's only data structure is the table, so we build the tree from tables:
a leaf is `{predict = "yes"}`, and a split is
`{feature = 1, threshold = 63.5, left = ..., right = ...}`, where each side
is another table. `grow` calls itself on each side. A table's keys also make
a set, which the split search uses to collect each feature's distinct values
before `table.sort` orders them. Lua has no `?:`, so `x <= t and left or
right` picks a side; it works because neither side is `false` or `nil`.
Lua has no decision tree, and no LuaRocks module is installed, so you see
every split tried as a plain loop.

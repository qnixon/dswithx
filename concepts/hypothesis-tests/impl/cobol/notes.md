We step through the splits in increasing order with a table of 8 plant
positions, starting at 1 through 8. `NEXT-SPLIT` finds the last position
that can still move right, moves it one place, and packs the positions
after it just behind it. When even the first position can't move, all
12,870 splits are done.

The grams are whole-number `PIC 9(6)` fields, so every total is an exact
integer, and `FUNCTION ABS` with `>=` counts the 6 ties exactly. The means
are the group totals divided by 8, not `FUNCTION MEAN`.

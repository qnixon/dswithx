We step through the splits in place, with no recursion. `IX(1)` to `IX(K)`
hold the chosen positions in increasing order, starting at 1 to 8. Each
step finds the rightmost position that can still move up, adds one to it,
and refills the positions after it in a run. That visits all 12,870 choices
in dictionary order.

One quirk shaped the code: bwbasic runs a `FOR` body at least once, even
for `FOR M = 4 TO 3`, so line 375 skips the refill loop by hand. Totals are
whole numbers, so the `>=` test has no rounding to trip on.

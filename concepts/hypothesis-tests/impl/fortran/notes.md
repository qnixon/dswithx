We never shuffle at random. The array `chosen` holds the positions of the
8 relabeled plants, starting at 1 to 8. Each pass finds the rightmost
position that can still move up, adds one to it, and resets the positions
after it, so the loop visits all 12,870 sets once, in dictionary order,
with no recursion.

`plants(chosen)` is a vector subscript, the elements at those positions,
so `sum(plants(chosen))` is the relabeled total. Totals are integers, so
the 6 exact ties all count.

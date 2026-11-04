We never shuffle at random. `Enum.shuffle/1` would give one random
relabeling, but with 8 plants in each group we can try all 12,870 splits,
so the p-value is exact. `Enum` has no combinations function, so the
recursive `chosen_totals/2` either adds the first plant and chooses one
fewer from the rest, or skips it.

The pattern `%{"group" => ^group}` in a `for` keeps only one group's rows;
the pin `^` matches the existing value. Totals stay integers, so `>=`
compares whole numbers, and the 6 exact ties all count.

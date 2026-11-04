We never shuffle at random. A four-line recursive function, `chosenTotals`,
lists the total of every way to choose 8 of the 16 plants: each plant is
either in the chosen group or not. That gives exactly 12,870 totals, so the
p-value is exact.

The totals are `Int`, so `abs d >= abs observed` compares whole numbers
and the 6 exact ties all count. `Data.List` has `subsequences`, but it
lists all 65,536 subsets of the 16 plants, so we'd still have to filter
by size.

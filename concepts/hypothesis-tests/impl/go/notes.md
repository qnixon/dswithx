We never shuffle at random. A recursive closure, `choose`, walks every way
to pick 8 of the 16 plants for the compost label, carrying a running total,
and counts all 12,870 splits. A closure can't call itself if it's declared
with `:=`, because the name doesn't exist yet on the right-hand side, so we
write `var choose func(...)` first and assign it after.

The totals are `int`, so `>=` never meets a near-tie. `math.Abs` takes and
returns `float64`, so a three-line `abs` for ints keeps the comparison in
whole numbers.

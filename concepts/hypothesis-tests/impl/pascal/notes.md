A recursive procedure, `Choose`, walks the plants in order. At each plant
it calls itself twice: once taking the plant into the compost group and
once skipping it. When it has taken 8, it counts the split. A branch with
too few plants left to reach 8 returns early, so the walk visits exactly
the 12,870 splits.

The totals are `Integer`, and so is the comparison, so `>=` never meets a
floating-point near-tie. `Concat` joins the two groups' dynamic arrays
into one list of plants, and `Abs` makes the test two-sided.

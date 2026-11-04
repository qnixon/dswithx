We never shuffle at random. With 8 plants in each group, there are exactly
12,870 ways to choose which 8 carry the compost label, so we try them all
and the p-value is exact. `itertools.combinations` lists each choice of 8
plant positions once, in a fixed order.

Because both groups have 8 plants, comparing totals is the same as
comparing means, and the totals stay whole numbers, so `>=` never meets a
near-tie. Python's standard library has no permutation test; SciPy's
`permutation_test` does, but SciPy isn't installed.

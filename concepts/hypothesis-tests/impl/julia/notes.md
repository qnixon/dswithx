We never shuffle at random. Each split is a number from 0 to 65,535 whose
binary digits mark the chosen plants, and `count_ones(mask) == n` keeps the
12,870 numbers with exactly 8 bits set. Julia arrays start at 1, so plant
`i` is bit `i - 1`, read with `(mask >> (i - 1)) & 1`.

Because both groups have 8 plants, comparing totals is the same as comparing
means, and the totals stay `Int`, so `>=` never meets a near-tie. Base Julia
has no combinations function or permutation test. The Combinatorics and
HypothesisTests packages have them, but neither is installed.

We never shuffle at random. `plants.combination(8)` yields each choice of 8
plants once, in a fixed order, so the loop sees all 12,870 splits and the
p-value is exact. Called without a block, `combination` returns an
Enumerator instead, so nothing builds a list of all the splits at once.

Because both groups have 8 plants, comparing totals is the same as comparing
means, and the totals stay whole Integers, so `>=` never meets a near-tie.
`fdiv` turns them into floats only for printing.

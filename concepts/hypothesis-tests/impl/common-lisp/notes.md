We never shuffle at random. Each whole number from 0 to 65,535 stands for
a set of the 16 plants, one bit per plant, and `logcount` counts its 1
bits. The 12,870 numbers with exactly 8 are the splits, and `logbitp`
tells us which plants each one chose, so the p-value is exact.

The grams are read with `parse-integer`, and the totals stay integers, so
`>=` compares whole numbers and the 6 exact ties all count. The means
divide by a double, since `(/ 3231 8)` would give the fraction 3231/8.

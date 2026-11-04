We number the subsets instead of recursing. With 16 plants, each whole
number from 0 to 65,535 is a subset: bit i set means plant i is chosen.
`sprintf('%b', $mask)` writes the bits as text, and `tr/1//` counts the
1s, so we keep the 12,870 masks with exactly 8 bits set and total those
plants' grams.

That checks all 65,536 masks to use a fifth of them, which is still
instant here. Totals are whole numbers, so `>=` is exact. CPAN modules,
such as Algorithm::Combinatorics, aren't installed.

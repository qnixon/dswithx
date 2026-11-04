We treat every whole number from 0 to 2^16 − 1 as a mask: bit i set means
plant i is labeled compost. `Integer.bitCount` counts the set bits, so the
12,870 masks with exactly 8 of them are the splits, and the other 52,666
are skipped. `mask & (1 << i)` tests one bit at a time to add up the chosen
grams.

The sums are `long` integers, so `Math.abs` and `>=` compare whole numbers
and the 6 splits that tie the observed difference all count. We divide only
when printing. Apache
Commons Math has statistical tests, but it isn't installed.

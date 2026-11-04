C's standard library has no combinations helper, so a recursive function,
`choose`, builds the splits. At each plant it either takes the plant, adding
its grams to the running total, or skips it, and it stops when 8 are taken,
so each of the 12,870 ways to pick 8 of the 16 positions is reached exactly
once. It also gives up early when too few plants remain to finish a split.

Every total is a `long`, so the test compares whole numbers with `labs` and
`>=`, and the 6 splits that tie the observed difference count exactly. We
convert to `double` only to print the means and the p-value.

`array_combine` pairs the header names with each line's fields, so every row
is an array keyed by column name. The counts live in nested arrays, as in
`$count[$label][$f][$value]`; writing to a nested key creates the levels
above it. Reading a key that was never set, though, raises a warning, which
fails the run here, so each lookup adds `?? 0` to fall back to zero.

We sort the labels and let only a strictly higher score replace the best, so
an exact tie goes to the alphabetically first label. PHP has no naive Bayes
classifier, so there was no built-in to skip.

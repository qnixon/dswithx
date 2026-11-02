Java's streams have `average()` and `summaryStatistics()`, which would give
each mean in one call, so we skip them and write the sums as plain `for`
loops over `double[]` arrays. A small `mean` method does that for both
columns, and one more loop builds `sxx`, `syy`, and `sxy` together from the
deviations `dx` and `dy`.

The file is read once with `Files.readAllLines`, and `readColumn` pulls each
column out of those lines by header name. Both arrays come from the same
rows in the same order, so `xs[i]` and `ys[i]` always belong to the same
student, and no zipping is needed. Every `printf` passes `Locale.ROOT`.

Java wants everything spelled out. The code lives in a class named `Main`,
every variable has a type, and `readColumn` has to declare that it
`throws IOException`, because Java won't compile a file read that might
fail unless you say what happens. The sums are plain `for` loops over a
`double[]`, and `Arrays.sort` puts the values in order for the median.

Java's streams have `average()` and `summaryStatistics()`, which would give
the mean, min, and max in one call, so we skip them. Watch `printf`, too:
it follows the computer's language settings, and on a German one it prints
29,677500, so every call passes `Locale.ROOT`.

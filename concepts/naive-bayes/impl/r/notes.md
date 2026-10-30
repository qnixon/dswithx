<!-- Placeholder text: to be written. -->

**Easy:** counting is what R does best. `table()` gives the label counts with
names already sorted alphabetically, so `which.max()` (first maximum) gives the
tie rule for free, and `unique()` gives the number of distinct values per
feature for the smoothing denominator. Base R has no naive Bayes classifier;
`naiveBayes()` is in the `e1071` package, not in this image.

**Hard:** `read.csv` guesses column types, so `colClasses = "character"` keeps
the yes/no values as plain strings. A single data frame row is still a data
frame, so `row[[f]]` is needed to pull out one value.

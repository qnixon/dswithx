R reads like a description of the method. `table(train$label)` counts the
labels and returns them with sorted names, and `which.max` picks the first
maximum, so the tie rule comes for free. Comparing a column to a value gives
a logical vector, and `sum()` counts the `TRUE`s, so
`sum(in_label[[f]] == row[[f]])` is a whole count in one expression. That's
why this version keeps no count table: it recounts the matching training
rows each time it scores.

Watch the indexing. With `f` holding a feature name, `row$f` looks for a column literally
named `f` and returns `NULL`; `row[[f]]` uses the variable. And
`colClasses = "character"` stops `read.csv` from guessing types: a column of
`T` and `F` would come back logical. Base R has no naive Bayes classifier;
`naiveBayes()` lives in the `e1071` package, which isn't installed here.

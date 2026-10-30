<!-- Placeholder text: to be written. -->

**Easy:** the distances from one test seed to all 150 training seeds are a
single vectorized expression, `order()` ranks them (and is stable, so equal
distances keep file order), and `table()` counts the votes. Base R has no
`knn()`; that lives in the `class` package, which is not in this image.

**Hard:** filtering a data frame by row (`data[data$split == "train", ]`) needs
the trailing comma, and looping over test rows reads best with `mapply()` over
the two feature columns rather than over the rows of the data frame.

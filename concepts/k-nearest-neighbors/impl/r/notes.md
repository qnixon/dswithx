R measures distance without a loop.
`sqrt((train$length_mm - length_mm)^2 + (train$width_mm - width_mm)^2)`
compares one test seed with all 150 training seeds at once,
`order(distance)[1:k]` picks the five nearest, and `table()` counts the vote.
`order()` keeps tied values in their original order, so equal distances keep
file order.

Where R pushes back is shape. Picking rows needs the trailing comma in
`data[data$split == "train", ]`, and `mapply()` runs `classify` over the two
test columns side by side. One quiet difference: `table()` sorts labels
alphabetically and `which.max()` takes the first maximum, so a tied vote
would go to `kama`, not to the nearer label. With odd k there is no tie.
The usual built-in, `knn()`, lives in the `class` package, which isn't
installed in this image.

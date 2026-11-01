The split search has no loop over thresholds. `outer(days[[f]],
thresholds, "<=")` builds a TRUE/FALSE table with one row per day and one
column per threshold, so `colSums()` gives every threshold's left-side
size at once, and multiplying the table by the rain column first gives the
rainy counts. `gini()` then scores all the thresholds in one vector, and
`which.min()` takes the first minimum, which is the tie rule.

The tree is nested lists: a leaf is the string `"yes"` or `"no"`, a split
is a list holding its two subtrees, and `is.list()` tells them apart. We
avoided `mean()`. The usual tool, `rpart()`, is one of R's recommended
packages, which this image removes, so it isn't installed here.

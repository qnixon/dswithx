Every statistic here is a base R function. R was built for this, so there's
nothing to import: `mean`, `median`, `var`, and `sd` are there the moment R
starts, and each takes the whole column at once.

Two details are worth knowing. `var` and `sd` are the sample versions,
dividing by n − 1, and base R has no population version at all. And
`range` doesn't return a number: it returns the minimum and maximum as a
pair, so we take `diff` of that pair to get the width the from-scratch
version computes as `max - min`.

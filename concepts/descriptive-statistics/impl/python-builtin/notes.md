This is how you'd write it in real Python. The `statistics` module ships
with the language, and `mean`, `median`, `variance`, and `stdev` each take a
list and return one number. `median` sorts a copy for you and averages the
two middle values when the count is even, so 120 values need no special
case.

Watch the names. `variance` and `stdev` are the sample versions, dividing by
n − 1, which is what we want here. Their population twins, `pvariance` and
`pstdev`, divide by n, and on [1, 2, 3, 4] they give 1.25 instead of 1.67.

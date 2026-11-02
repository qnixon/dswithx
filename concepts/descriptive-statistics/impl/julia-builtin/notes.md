`Statistics` is one of Julia's standard libraries: it ships with Julia but
has to be loaded with `using`, like `Printf`. It supplies `mean`, `median`,
`var`, and `std`. `sum` and `extrema` are in Base Julia; `extrema` returns
the minimum and maximum together.

By default `var` and `std` are the sample versions, dividing by n − 1.
Passing `corrected=false` switches to dividing by n, so on [1, 2, 3, 4]
`var` gives 1.67 and `var(x, corrected=false)` gives 1.25. Unlike the
from-scratch version, nothing here sorts the data first: `median` does
that internally.

Julia's standard library includes `Statistics`, with `mean`, `median`,
`var`, and `std`, and `std` already divides by n − 1. We skipped it so the
arithmetic stays visible. In real code you'd reach for it.

The dot does the work instead of a loop: `values .- mean` subtracts the mean
from every value, and `.^ 2` squares each result, so the variance is one
line. The trap is indexing, as in R: Julia counts from 1, so with 120
values and `middle = n ÷ 2`, the middle pair is `values[middle]` and
`values[middle + 1]`. `÷` is integer division; plain `/` always gives a
float.

Python is the baseline the other languages are measured against, and this
version shows why: each formula is close to one line. `csv.DictReader`
reads the column by its header name, and `sum` with a generator expression
turns the variance formula into a single readable line.

The interesting choice is what we left out. The standard library's
`statistics` module has `mean`, `median`, `variance`, and `stdev`, and
`variance` already divides by n − 1. We skipped it so the arithmetic stays
visible. In real code you'd reach for it.

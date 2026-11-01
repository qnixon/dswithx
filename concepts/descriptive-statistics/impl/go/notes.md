Go has no statistics package, so there are no built-ins to avoid: the sum,
mean, and variance are plain `for` loops, and `slices.Sort` orders the
values for the median. `encoding/csv` reads the file, and `slices.Index`
finds the `minutes` column by its header name.

The trap is types. Go never converts numbers for you, so `total / n` with an
`int` count doesn't compile; you write `total / float64(n)`. Integer
division truncates, which is what we want for the middle index: `120 / 2`
is `60`, and with an even count the median averages positions 59 and 60
(Go counts from 0). Errors come back as values, so reading the file checks
`err` at each step.

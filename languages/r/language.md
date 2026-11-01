---
name: R
first_appeared: 1993
paradigm: Functional, array-oriented
toolchain: R 4.6.2
image: r-base:4.6.2 (recommended packages removed)
highlight: r
---

R was built by statisticians for statistics, so almost everything this
site implements by hand is already one built-in call: `mean()`, `median()`,
`var()`, `sd()`, `cor()`, `lm()`, and `kmeans()` all come with base R. The
from-scratch versions avoid them and show the arithmetic instead. R's
packages from CRAN are where most of its data science lives; this image
removes even the recommended packages that normally ship with R, leaving
only base R and its standard packages, such as `stats` and `utils`.

## Quirks

- Arithmetic is vectorized: `x - mean(x)` subtracts the mean from every
  element at once, with no loop.
- Vectors are indexed from 1.
- `var()` divides by n − 1, like the formulas on this site.

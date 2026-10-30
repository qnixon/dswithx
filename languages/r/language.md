---
name: R
first_appeared: 1993
paradigm: Functional, array-oriented
toolchain: R 4.6.2
image: r-base:4.6.2 (recommended packages removed)
highlight: r
---

<!-- Placeholder text: to be written. -->

R was built by statisticians for statistics, so most of what this site
implements by hand is already a single built-in function. Here the
from-scratch versions avoid those functions to show the arithmetic.

## Quirks

- Vectors are 1-indexed, and arithmetic is vectorized: `values - m` subtracts
  `m` from every element at once.
- `mean()`, `median()`, `var()`, and `sd()` are built in; from-scratch
  implementations avoid them.

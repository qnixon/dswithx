---
name: Python
first_appeared: 1991
paradigm: Multi-paradigm (imperative, object-oriented, functional)
toolchain: CPython 3.15.2
image: python:3.15.2-slim-trixie
highlight: python
---

Python is the most common language for data science today, but almost
always with NumPy, pandas, and scikit-learn doing the work. None of those
ship with Python, and pip is removed from this image, so here it has only
its standard library. That library is generous: `csv` reads the data by
header name, `math` has square roots, logs, and `math.dist`, and
`statistics` has `mean`, `median`, `variance`, `stdev`, and even
`linear_regression` and `correlation`. The from-scratch versions skip
`statistics` so the arithmetic stays visible, which makes Python the
baseline the other languages are compared against.

## Quirks

- `/` always gives a float, so `7 / 2` is `3.5`; `//` is floor division.
- `statistics.variance` divides by n − 1, like the formulas on this site.
- `sorted` is stable, so ties keep their original order.

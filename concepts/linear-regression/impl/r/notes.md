<!-- Placeholder text: to be written. -->

**Easy:** the formulas map almost symbol for symbol. Vectorized arithmetic
makes each sum one expression, such as `sum((x - mean_x) * (y - mean_y))`, and
`read.csv` hands back the columns by name. As with descriptive statistics, the
from-scratch version is the long way round in R: `lm(score ~ hours)` fits the
line and `cor()` gives r in one call each.

**Hard:** nothing about the arithmetic. The only care needed is to avoid
`mean()`, `cor()`, and `lm()`, which are the idiomatic R answer.

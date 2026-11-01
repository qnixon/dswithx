---
name: PostgreSQL
first_appeared: 1996
paradigm: Declarative (SQL)
toolchain: PostgreSQL 18.6
image: postgres:18.6-trixie
highlight: sql
---

SQL is where most data already lives, and PostgreSQL brings a lot of
statistics with it: `avg`, `stddev_samp`, `var_samp`, `percentile_cont`,
`corr`, and `regr_slope` are all built-in aggregates. The from-scratch
versions avoid them and use only basic aggregates such as `sum`, `count`,
`min`, and `max`, plus ordinary arithmetic and window functions. SQL describes results rather than steps, so iterative
methods take some ingenuity: k-means repeats its two steps with a recursive
query, `WITH RECURSIVE`.

## Quirks

- The runner loads `data.csv` into a table named `data`, with numeric
  columns as `double precision` and a `row_id` column numbering rows in
  file order, from 1. Tables otherwise have no order.
- The final query returns two columns, `name` and `value`, one row per
  result.
- Integer division truncates: `7 / 2` is `3`, and `7 / 2.0` is `3.5`.

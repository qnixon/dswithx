---
name: PostgreSQL
first_appeared: 1996
paradigm: Declarative (SQL)
toolchain: PostgreSQL 18.6
image: postgres:18.6-trixie
highlight: sql
---

<!-- Placeholder text: to be written. -->

SQL is the language most data already lives in. PostgreSQL adds window
functions, common table expressions, and a rich set of statistical
aggregates, so a lot of data science can happen without the data leaving the
database.

## Quirks

- The harness loads `data.csv` into a table named `data`; numeric columns
  become `double precision`. Tables have no row order, so an extra `row_id`
  column numbers the rows in file order, from 1.
- The final query returns two columns, `name` and `value`, one row per result.
- Built-in aggregates such as `avg()`, `stddev_samp()`, and
  `percentile_cont()` are avoided in from-scratch versions.

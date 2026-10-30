In SQL you describe results instead of writing loops. Count, sum, minimum,
and maximum are basic aggregates, and named common table expressions
(`WITH totals AS (...)`) let the query read from top to bottom like a
script.

The median is where SQL resists. A table has no "middle row" until you
number the rows with a window function, `row_number() OVER (ORDER BY
minutes)`, and pick positions 60 and 61. PostgreSQL could do it in one call
with `percentile_cont(0.5) WITHIN GROUP (ORDER BY minutes)`, and `avg`,
`var_samp`, and `stddev_samp` cover the rest. We avoided them here.

We never loop. A two-row `VALUES` list holds the thresholds, and a cross
join pairs each threshold with all 200 parts. `GROUP BY` then gives one row
per threshold, and `count(*) FILTER (WHERE ...)` fills in each cell of the
confusion matrix.

The AUC is a self-join: every defective part joined to every good one, 5,511
rows. A `CASE` scores each pair 2, 1, or 0, and `sum` adds them up. Counts
are integers, and integer division drops the fraction (7 / 2 is 3), so we
cast to `numeric` before dividing. Sort columns keep the output in
order, since a query's rows have none of their own.

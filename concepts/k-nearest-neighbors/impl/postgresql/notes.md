SQL suits the shape of kNN. "Every test seed against every training seed"
is a `CROSS JOIN`, 7,500 pairs here. `row_number() OVER (PARTITION BY
test.id ORDER BY ...)` ranks the training seeds for each test seed, the vote
is a `GROUP BY` with `count(*)`, and `DISTINCT ON (id) ... ORDER BY id, n
DESC` keeps the winning variety.

Row order is where it pushes back. A table has none, so ties are broken by
the `row_id` column the harness adds in file order, as `train.id` in the
`ORDER BY`. The distance is written out with `sqrt` and `^`. PostgreSQL's
geometric `point` type has a distance operator, `point(0, 0) <-> point(3,
4)` returns 5, which would count as a general tool too. There is no kNN
classifier built in to skip.

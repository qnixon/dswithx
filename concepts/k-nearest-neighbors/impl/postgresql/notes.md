<!-- Placeholder text: to be written. -->

**Easy:** "every test seed against every training seed" is a `CROSS JOIN`,
and "the 5 nearest for each test seed" is `row_number() OVER (PARTITION BY
test seed ORDER BY distance)`. The vote is a `GROUP BY` and `DISTINCT ON`
picks the winner. SQL is good at exactly this kind of set work.

**Hard:** row order. A table has no order, so file order (needed only to
break distance ties) comes from the `row_id` column the harness adds while
loading. There is also no distance function for plain columns; the Euclidean
formula is written out.

<!-- Placeholder text: to be written. -->

**Easy:** naive Bayes is counting, and counting is what `GROUP BY` does. The
label counts, the (feature, value, label) counts, and the number of distinct
values per feature are each one small query, and `DISTINCT ON ... ORDER BY
score DESC, label` picks the winner with the alphabetical tie-break built in.

**Hard:** the features are three separate columns, so they are turned into
rows first (`LATERAL (VALUES ...)`) to count them all the same way. Unseen
(feature, value, label) combinations have no count row at all, so the join
to the counts has to be a `LEFT JOIN` with `coalesce(count, 0)` before adding
one. PostgreSQL has no naive Bayes built in.

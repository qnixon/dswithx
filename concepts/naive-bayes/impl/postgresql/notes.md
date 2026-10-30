Naive Bayes is counting, and counting is what `GROUP BY` does. The label
counts, the (feature, value, label) counts, and the number of distinct
values per feature are each a short common table expression. The winner
comes from `DISTINCT ON (id) ... ORDER BY id, score DESC, label`, which keeps
the first row for each email, with the alphabetical tie-break built into the
ordering.

The features are three separate columns, so `LATERAL (VALUES ...)` first
turns each email into three (feature, value) rows that can all be counted
the same way. A combination that never occurs in training has no count row
at all, so the join to the counts is a `LEFT JOIN` with
`coalesce(vc.n_cv, 0)` before adding one. PostgreSQL has no naive Bayes
built in.

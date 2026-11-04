SQL has no loops, so a recursive CTE builds the splits. Each row of `picks`
is a partial split: how many plants it holds, their total grams, and the
last plant id. Each step joins on `plants.id > picks.last_id`, so a set of
plants is built in one order only. The CTE makes 39,202 partial rows, and
the 12,870 with 8 plants are the splits.

run.sh loads grams as double precision, so we cast them to `integer` and
every total is exact. `group` is a reserved word; unquoted, it's a syntax
error.

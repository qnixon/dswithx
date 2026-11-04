-- Exact two-sided permutation test for a difference in means, in PostgreSQL.
--
-- If compost made no difference, the "compost" and "control" labels are
-- arbitrary, and any 8 of the 16 plants could have carried the compost label.
-- We try every one of those splits and count how many give a difference at
-- least as large as the one we observed. That fraction is the p-value.

WITH RECURSIVE plants AS (
    -- run.sh loads grams as double precision; they are whole numbers, so we
    -- turn them back into integers and every total below stays exact.
    -- "group" is a reserved word in SQL, so its column name needs quotes.
    SELECT row_id AS id, "group" AS label, grams::integer AS grams FROM data
),
summary AS (
    SELECT count(*) FILTER (WHERE label = 'control') AS control_count,
           count(*) FILTER (WHERE label = 'compost') AS compost_count,
           sum(grams) FILTER (WHERE label = 'control') AS control_sum,
           sum(grams) FILTER (WHERE label = 'compost') AS compost_sum,
           sum(grams) AS total
    FROM plants
),
picks AS (
    -- A recursive CTE grows its rows step by step. Each row is a partial
    -- split: how many plants it has chosen, their grams, and the last id
    -- chosen. A step adds one plant with a larger id, so every set of ids is
    -- built once, in increasing order, and never twice in another order.
    SELECT id AS last_id, 1 AS size, grams AS chosen FROM plants
    UNION ALL
    SELECT plants.id, picks.size + 1, picks.chosen + plants.grams
    FROM picks
    JOIN plants ON plants.id > picks.last_id
    CROSS JOIN summary
    WHERE picks.size < summary.compost_count
),
splits AS (
    -- The finished splits have as many plants as the compost group. Both
    -- groups have the same size, so comparing totals is the same as
    -- comparing means, and integers have no floating-point near-ties.
    SELECT picks.chosen - (summary.total - picks.chosen) AS difference
    FROM picks CROSS JOIN summary
    WHERE picks.size = summary.compost_count
),
test AS (
    SELECT count(*) AS splits,
           count(*) FILTER (WHERE abs(difference) >=   -- two-sided
                            (SELECT abs(compost_sum - control_sum) FROM summary))
               AS as_extreme
    FROM splits
)
SELECT name, value
FROM (
    -- Dividing numeric values and rounding to 6 places prints 6 decimals.
    SELECT 1 AS position, 'control_count' AS name, control_count::text AS value FROM summary
    UNION ALL SELECT 2, 'compost_count', compost_count::text FROM summary
    UNION ALL SELECT 3, 'control_mean', round(control_sum::numeric / control_count, 6)::text FROM summary
    UNION ALL SELECT 4, 'compost_mean', round(compost_sum::numeric / compost_count, 6)::text FROM summary
    UNION ALL SELECT 5, 'observed_difference',
                     round((compost_sum - control_sum)::numeric / compost_count, 6)::text FROM summary
    UNION ALL SELECT 6, 'splits', splits::text FROM test
    UNION ALL SELECT 7, 'as_extreme', as_extreme::text FROM test
    UNION ALL SELECT 8, 'p_value', round(as_extreme::numeric / splits, 6)::text FROM test
) AS results
ORDER BY position;

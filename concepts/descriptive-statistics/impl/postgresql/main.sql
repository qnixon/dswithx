-- Descriptive statistics on one column, in PostgreSQL.
--
-- run.sh loads data.csv into a table named data. PostgreSQL has avg(),
-- var_samp(), stddev_samp(), and percentile_cont() built in; they are avoided
-- here so the arithmetic stays visible.

WITH totals AS (
    SELECT count(*) AS n, sum(minutes) AS total, min(minutes) AS lo, max(minutes) AS hi
    FROM data
),
mean AS (
    SELECT total / n AS mean FROM totals
),
variance AS (
    -- Sample variance divides by n - 1, not n (Bessel's correction).
    SELECT sum((minutes - mean) ^ 2) / (n - 1) AS variance
    FROM data, mean, totals
    GROUP BY n
),
ranked AS (
    SELECT minutes, row_number() OVER (ORDER BY minutes) AS position
    FROM data
),
median AS (
    -- The middle value, or the mean of the two middle values when n is even.
    -- Integer division: for n = 120 this picks positions 60 and 61.
    SELECT sum(minutes) / count(*) AS median
    FROM ranked, totals
    WHERE position IN ((n + 1) / 2, (n + 2) / 2)
)
SELECT name, value
FROM totals, mean, variance, median,
LATERAL (VALUES
    (1, 'count',    n::text),
    (2, 'sum',      round(total::numeric, 6)::text),
    (3, 'mean',     round(mean::numeric, 6)::text),
    (4, 'median',   round(median::numeric, 6)::text),
    (5, 'min',      round(lo::numeric, 6)::text),
    (6, 'max',      round(hi::numeric, 6)::text),
    (7, 'range',    round((hi - lo)::numeric, 6)::text),
    (8, 'variance', round(variance::numeric, 6)::text),
    (9, 'std_dev',  round(sqrt(variance)::numeric, 6)::text)
) AS results (position, name, value)
ORDER BY position;

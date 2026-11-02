-- Descriptive statistics on one column, with PostgreSQL's aggregates.
--
-- The built-in version of ../postgresql/main.sql. run.sh loads data.csv into
-- a table named data. avg(), var_samp(), and stddev_samp() do the arithmetic,
-- and percentile_cont(0.5) is the median, averaging the two middle values
-- when there is an even number of rows.

WITH stats AS (
    SELECT
        count(*) AS n,
        sum(minutes) AS total,
        avg(minutes) AS mean,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY minutes) AS median,
        min(minutes) AS lo,
        max(minutes) AS hi,
        var_samp(minutes) AS variance,
        stddev_samp(minutes) AS std_dev
    FROM data
)
SELECT name, value
FROM stats,
LATERAL (VALUES
    (1, 'count',    n::text),
    (2, 'sum',      round(total::numeric, 6)::text),
    (3, 'mean',     round(mean::numeric, 6)::text),
    (4, 'median',   round(median::numeric, 6)::text),
    (5, 'min',      round(lo::numeric, 6)::text),
    (6, 'max',      round(hi::numeric, 6)::text),
    (7, 'range',    round((hi - lo)::numeric, 6)::text),
    (8, 'variance', round(variance::numeric, 6)::text),
    (9, 'std_dev',  round(std_dev::numeric, 6)::text)
) AS results (position, name, value)
ORDER BY position;

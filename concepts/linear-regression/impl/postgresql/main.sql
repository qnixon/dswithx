-- Simple linear regression by least squares, in PostgreSQL.
--
-- Fits score = intercept + slope * hours. PostgreSQL has regr_slope(),
-- regr_intercept(), corr(), and regr_r2() built in; they are avoided here so
-- the sums stay visible.

WITH means AS (
    SELECT count(*) AS n, sum(hours) / count(*) AS mean_x, sum(score) / count(*) AS mean_y
    FROM data
),
sums AS (
    -- Sums of squared deviations and of cross-products.
    SELECT sum((hours - mean_x) ^ 2)               AS sxx,
           sum((score - mean_y) ^ 2)               AS syy,
           sum((hours - mean_x) * (score - mean_y)) AS sxy
    FROM data, means
),
fit AS (
    SELECT sxy / sxx                        AS slope,
           mean_y - (sxy / sxx) * mean_x    AS intercept,
           sxy / sqrt(sxx * syy)            AS r
    FROM means, sums
)
SELECT name, value
FROM means, fit,
LATERAL (VALUES
    (1, 'count',     n::text),
    (2, 'slope',     round(slope::numeric, 6)::text),
    (3, 'intercept', round(intercept::numeric, 6)::text),
    (4, 'r',         round(r::numeric, 6)::text),
    (5, 'r_squared', round((r * r)::numeric, 6)::text)
) AS results (position, name, value)
ORDER BY position;

-- Simple linear regression with PostgreSQL's regression aggregates.
--
-- The built-in version of ../postgresql/main.sql. Each regr_* aggregate takes
-- (y, x), with y first: regr_slope(score, hours) fits
-- score = intercept + slope * hours.

WITH fit AS (
    SELECT count(*)                     AS n,
           regr_slope(score, hours)     AS slope,
           regr_intercept(score, hours) AS intercept,
           corr(score, hours)           AS r,
           regr_r2(score, hours)        AS r_squared
    FROM data
)
SELECT name, value
FROM fit,
LATERAL (VALUES
    (1, 'count',     n::text),
    (2, 'slope',     round(slope::numeric, 6)::text),
    (3, 'intercept', round(intercept::numeric, 6)::text),
    (4, 'r',         round(r::numeric, 6)::text),
    (5, 'r_squared', round(r_squared::numeric, 6)::text)
) AS results (position, name, value)
ORDER BY position;

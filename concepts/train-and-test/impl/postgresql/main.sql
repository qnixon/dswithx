-- Train and test error for polynomials of degree 1 to 8, in PostgreSQL.
--
-- Each polynomial is fitted by least squares to the training drives only: we
-- build the normal equations and solve them by Gaussian elimination. Then we
-- measure its root-mean-square error on the training drives and on the test
-- drives it never saw. Each system is a two-dimensional double precision[][]
-- array, and elimination is a WITH RECURSIVE query whose rows are one step
-- each: (degree, column, matrix).

WITH RECURSIVE range AS (
    -- Map the training speeds onto -1 to 1. Raw speeds to the 16th power
    -- (the largest entry at degree 8) would swamp the small ones and make
    -- the equations hard to solve accurately.
    SELECT (min(speed) + max(speed)) / 2 AS mid, (max(speed) - min(speed)) / 2 AS half
    FROM data
    WHERE split = 'train'
),
drives AS (
    SELECT split, (speed - mid) / half AS z, litres AS y
    FROM data, range
),
degrees AS (
    SELECT d FROM generate_series(1, 8) AS d
),
entries AS (
    -- The augmented normal equations, one row per entry (array positions
    -- start at 1). Columns 1 to d + 1 hold sum z^(i+j); the last column,
    -- d + 2, holds b, sum y z^i.
    SELECT d, i, j,
           CASE WHEN j <= d + 1 THEN sum(z ^ (i + j - 2))
                ELSE sum(y * z ^ (i - 1)) END AS v
    FROM degrees,
         generate_series(1, d + 1) AS i,
         generate_series(1, d + 2) AS j,
         drives
    WHERE split = 'train'
    GROUP BY d, i, j
),
systems AS (
    -- array_agg of one-dimensional arrays stacks them into a matrix.
    SELECT d, array_agg(row ORDER BY i) AS m
    FROM (SELECT d, i, array_agg(v ORDER BY j) AS row FROM entries GROUP BY d, i) AS rows
    GROUP BY d
),
elimination (d, k, m) AS (
    SELECT d, 0, m FROM systems

    UNION ALL

    -- k counts the columns already cleared, and this step clears column
    -- k + 1 below the diagonal. First the row with the largest entry in that
    -- column (at or below row k + 1) swaps up to row k + 1, which keeps the
    -- rounding error small; then each lower row subtracts a multiple of it. Aggregates aren't allowed directly in the
    -- recursive step, so they sit in LATERAL.
    SELECT e.d, e.k + 1, next.m
    FROM elimination e,
    LATERAL (
        SELECT r AS pivot
        FROM generate_series(e.k + 1, e.d + 1) AS r
        ORDER BY abs(e.m[r][e.k + 1]) DESC, r
        LIMIT 1
    ) AS p,
    LATERAL (
        -- s is the row of the old matrix that lands at row r after the swap,
        -- so swapped row r, column c is e.m[s][c], and the new row k is
        -- e.m[p.pivot].
        SELECT array_agg(row ORDER BY r) AS m
        FROM (
            SELECT r, array_agg(
                       CASE WHEN r <= e.k + 1 OR c < e.k + 1 THEN e.m[s][c]
                            ELSE e.m[s][c] - e.m[s][e.k + 1] / e.m[p.pivot][e.k + 1]
                                             * e.m[p.pivot][c] END
                       ORDER BY c) AS row
            FROM generate_series(1, e.d + 1) AS r,
                 LATERAL (SELECT CASE r WHEN e.k + 1 THEN p.pivot
                                        WHEN p.pivot THEN e.k + 1
                                        ELSE r END AS s) AS swap,
                 generate_series(1, e.d + 2) AS c
            GROUP BY r
        ) AS rows
    ) AS next
    WHERE e.k < e.d  -- the last column has no rows below it
),
triangular AS (
    SELECT d, m FROM elimination WHERE k = d
),
back (d, r, x) AS (
    -- Back substitution, from the last unknown up. x starts as zeros, and
    -- each step fills in x[r].
    SELECT d, d + 2, array_fill(0::double precision, ARRAY[d + 1])
    FROM triangular

    UNION ALL

    SELECT b.d, b.r - 1, next.x
    FROM back b JOIN triangular t USING (d),
    LATERAL (
        SELECT b.x[:b.r - 2]
               || (t.m[b.r - 1][b.d + 2] - coalesce(sum(t.m[b.r - 1][c] * b.x[c]), 0))
                  / t.m[b.r - 1][b.r - 1]
               || b.x[b.r:] AS x
        FROM generate_series(b.r, b.d + 1) AS c
    ) AS next
    WHERE b.r > 1
),
coefficients AS (
    SELECT d, x FROM back WHERE r = 1
),
errors AS (
    -- Root-mean-square error of each fit, on each split.
    SELECT c.d, s.split, sqrt(sum((s.predicted - s.y) ^ 2) / count(*)) AS rmse
    FROM coefficients c,
    LATERAL (
        SELECT dr.split, dr.y, (SELECT sum(c.x[i] * dr.z ^ (i - 1))
                                FROM generate_series(1, c.d + 1) AS i) AS predicted
        FROM drives dr
    ) AS s
    GROUP BY c.d, s.split
),
results (position, name, value) AS (
    SELECT 1, 'train_count', count(*)::text FROM data WHERE split = 'train'
    UNION ALL
    SELECT 2, 'test_count', count(*)::text FROM data WHERE split = 'test'
    UNION ALL
    SELECT CASE split WHEN 'train' THEN 10 ELSE 20 END + d,
           split || '_rmse_d' || d, round(rmse::numeric, 6)::text
    FROM errors
)
SELECT name, value FROM results ORDER BY position;

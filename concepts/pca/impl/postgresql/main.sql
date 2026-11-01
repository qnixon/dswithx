-- Principal component analysis by power iteration, in PostgreSQL.
--
-- Standardizes the four scores, builds their correlation matrix, and finds the
-- top two eigenvectors (the principal components): power iteration finds the
-- first, then deflation removes it from the matrix so the same steps find the
-- second. Matrices are stored long, one row per (i, j) entry, and each power
-- iteration is a WITH RECURSIVE query whose state is one row: the step number
-- and the vector, as an array of four numbers.

WITH RECURSIVE scores AS (
    -- One row per (student, subject). j numbers the subjects 1 to 4, which is
    -- also each subject's position in the vectors below.
    SELECT d.row_id, s.j, s.subject, s.x
    FROM data d,
    LATERAL (VALUES (1, 'math', d.math), (2, 'physics', d.physics),
                    (3, 'reading', d.reading), (4, 'writing', d.writing)) AS s (j, subject, x)
),
means AS (
    -- avg() would do this; sum and count keep the arithmetic visible.
    SELECT j, count(*) AS n, sum(x) / count(*) AS mean
    FROM scores
    GROUP BY j
),
spread AS (
    -- Sample standard deviation (divide by n - 1), instead of stddev_samp().
    SELECT j, sqrt(sum((x - mean) ^ 2) / (n - 1)) AS sd
    FROM scores JOIN means USING (j)
    GROUP BY j, n
),
z AS (
    -- Each score standardized to mean 0 and standard deviation 1.
    SELECT row_id, j, subject, (x - mean) / sd AS z
    FROM scores JOIN means USING (j) JOIN spread USING (j)
),
corr AS (
    -- The correlation matrix: the covariance of the standardized columns,
    -- pairing every student's subject i with the same student's subject j.
    SELECT a.j AS i, b.j AS j, sum(a.z * b.z) / (count(*) - 1) AS r
    FROM z a JOIN z b USING (row_id)
    GROUP BY a.j, b.j
),
power_1 (step, v) AS (
    SELECT 0, ARRAY[1, 0, 0, 0]::double precision[]

    UNION ALL

    -- One step: v <- M v, rescaled to length 1. Aggregates aren't allowed
    -- directly in the recursive step, so they sit in LATERAL.
    SELECT p.step + 1, next.v
    FROM power_1 p,
    LATERAL (
        SELECT array_agg(mv / len ORDER BY i) AS v
        FROM (
            SELECT i, mv, sqrt(sum(mv ^ 2) OVER ()) AS len
            FROM (SELECT i, sum(r * p.v[j]) AS mv FROM corr GROUP BY i) AS product
        ) AS lengths
    ) AS next
    WHERE p.step < 1000
),
pc_1 AS (
    -- unnest turns the array back into rows, numbered from 1. An eigenvector
    -- can point either way; multiplying by sign(v[1]) makes v[1] positive.
    SELECT u.j, u.v * sign(p.v[1]) AS v
    FROM power_1 p, unnest(p.v) WITH ORDINALITY AS u (v, j)
    WHERE p.step = 1000
),
value_1 AS (
    -- The eigenvalue is v . (M v).
    SELECT sum(a.v * c.r * b.v) AS value
    FROM corr c JOIN pc_1 a ON a.j = c.i JOIN pc_1 b ON b.j = c.j
),
deflated AS (
    -- Deflation: subtract the first component's share, leaving the rest.
    SELECT c.i, c.j, c.r - value * a.v * b.v AS r
    FROM corr c JOIN pc_1 a ON a.j = c.i JOIN pc_1 b ON b.j = c.j, value_1
),
power_2 (step, v) AS (
    -- The same steps again, on the deflated matrix.
    SELECT 0, ARRAY[1, 0, 0, 0]::double precision[]

    UNION ALL

    SELECT p.step + 1, next.v
    FROM power_2 p,
    LATERAL (
        SELECT array_agg(mv / len ORDER BY i) AS v
        FROM (
            SELECT i, mv, sqrt(sum(mv ^ 2) OVER ()) AS len
            FROM (SELECT i, sum(r * p.v[j]) AS mv FROM deflated GROUP BY i) AS product
        ) AS lengths
    ) AS next
    WHERE p.step < 1000
),
pc_2 AS (
    SELECT u.j, u.v * sign(p.v[1]) AS v
    FROM power_2 p, unnest(p.v) WITH ORDINALITY AS u (v, j)
    WHERE p.step = 1000
),
value_2 AS (
    SELECT sum(a.v * c.r * b.v) AS value
    FROM deflated c JOIN pc_2 a ON a.j = c.i JOIN pc_2 b ON b.j = c.j
),
components AS (
    SELECT 1 AS c, value, j, v FROM value_1, pc_1
    UNION ALL
    SELECT 2, value, j, v FROM value_2, pc_2
),
student_1 AS (
    -- The first student in file order, in the new coordinates.
    SELECT p.c, sum(z.z * p.v) AS score
    FROM z JOIN components p USING (j)
    WHERE z.row_id = 1
    GROUP BY p.c
),
results (position, name, value) AS (
    SELECT 0, 'count', n::text FROM means WHERE j = 1
    UNION ALL
    SELECT c * 10, 'eigenvalue_' || c, round(value::numeric, 6)::text
    FROM components WHERE j = 1
    UNION ALL
    -- Standardized columns each have variance 1, so the total is 4.
    SELECT c * 10 + 1, 'explained_' || c, round((value / 4)::numeric, 6)::text
    FROM components WHERE j = 1
    UNION ALL
    SELECT c * 10 + 1 + p.j, 'pc' || c || '_' || subject, round(v::numeric, 6)::text
    FROM components p JOIN (SELECT DISTINCT j, subject FROM scores) AS s USING (j)
    UNION ALL
    SELECT 100 + c, 'student_1_pc' || c, round(score::numeric, 6)::text
    FROM student_1
)
SELECT name, value FROM results ORDER BY position;

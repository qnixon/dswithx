-- Logistic regression by gradient descent, in PostgreSQL.
--
-- Predicts whether a student passed from study hours and sleep. Each feature
-- is rescaled with the training rows' mean and sample standard deviation, then
-- the weights start at zero and take 1000 steps of batch gradient descent on
-- the average log-loss. The loop is a WITH RECURSIVE query whose state is one
-- row: the step number and the three weights.

WITH RECURSIVE train AS (
    SELECT hours, sleep, passed FROM data WHERE split = 'train'
),
means AS (
    -- avg() would do this; sum and count keep the arithmetic visible.
    SELECT count(*) AS n,
           sum(hours) / count(*) AS mean_hours,
           sum(sleep) / count(*) AS mean_sleep
    FROM train
),
spread AS (
    -- Sample standard deviation (divide by n - 1), instead of stddev_samp().
    SELECT sqrt(sum((hours - mean_hours) ^ 2) / (n - 1)) AS sd_hours,
           sqrt(sum((sleep - mean_sleep) ^ 2) / (n - 1)) AS sd_sleep
    FROM train, means
    GROUP BY n
),
scaled AS (
    -- Every row, scaled with the training statistics. The intercept's
    -- input is a constant 1, so it needs no column.
    SELECT split,
           (hours - mean_hours) / sd_hours AS x1,
           (sleep - mean_sleep) / sd_sleep AS x2,
           passed AS y
    FROM data, means, spread
),
steps (step, w0, w1, w2) AS (
    SELECT 0, 0::double precision, 0::double precision, 0::double precision

    UNION ALL

    -- One step: the gradient is the mean of (p - y) times each input, with p
    -- from the old weights; then all three weights move together. Aggregates
    -- aren't allowed directly in the recursive step, so they sit in LATERAL.
    SELECT s.step + 1,
           s.w0 - 0.5 * g.g0,
           s.w1 - 0.5 * g.g1,
           s.w2 - 0.5 * g.g2
    FROM steps s,
    LATERAL (
        SELECT sum(e) / count(*) AS g0,
               sum(e * x1) / count(*) AS g1,
               sum(e * x2) / count(*) AS g2
        FROM (
            SELECT x1, x2,
                   1 / (1 + exp(-(s.w0 + s.w1 * x1 + s.w2 * x2))) - y AS e
            FROM scaled
            WHERE split = 'train'
        ) AS errors
    ) AS g
    WHERE s.step < 1000
),
final AS (
    SELECT * FROM steps WHERE step = 1000
),
scored AS (
    -- Each row's predicted probability under the final weights.
    SELECT c.split, c.y,
           1 / (1 + exp(-(f.w0 + f.w1 * c.x1 + f.w2 * c.x2))) AS p
    FROM scaled c, final f
),
loss AS (
    SELECT -sum(y * ln(p) + (1 - y) * ln(1 - p)) / count(*) AS log_loss
    FROM scored WHERE split = 'train'
),
test AS (
    -- Predict 1 when p >= 0.5, and count the matches.
    SELECT count(*) AS n,
           sum(CASE WHEN (p >= 0.5) = (y = 1) THEN 1 ELSE 0 END) AS correct
    FROM scored WHERE split = 'test'
)
SELECT name, value
FROM means, final, loss, test,
LATERAL (VALUES
    (1, 'train_count',  means.n::text),
    (2, 'test_count',   test.n::text),
    (3, 'intercept',    round(w0::numeric, 6)::text),
    (4, 'weight_hours', round(w1::numeric, 6)::text),
    (5, 'weight_sleep', round(w2::numeric, 6)::text),
    (6, 'log_loss',     round(log_loss::numeric, 6)::text),
    (7, 'correct',      correct::text),
    (8, 'accuracy',     round((correct::numeric / test.n), 6)::text)
) AS results (position, name, value)
ORDER BY position;

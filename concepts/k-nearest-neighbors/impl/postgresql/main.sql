-- k-nearest neighbors classification (k = 5), in PostgreSQL.
--
-- Each test seed is labelled with the majority variety among its 5 nearest
-- training seeds, by Euclidean distance.

WITH seeds AS (
    -- A table has no row order; run.sh numbers rows in file order as row_id.
    -- It only matters for breaking distance ties, which the data avoids.
    SELECT row_id AS id, length_mm, width_mm, variety, split
    FROM data
),
train AS (SELECT * FROM seeds WHERE split = 'train'),
test  AS (SELECT * FROM seeds WHERE split = 'test'),
ranked AS (
    -- Every (test, train) pair, ranked by distance within each test seed.
    SELECT test.id, test.variety AS actual, train.variety AS neighbor,
           row_number() OVER (
               PARTITION BY test.id
               ORDER BY sqrt((test.length_mm - train.length_mm) ^ 2
                           + (test.width_mm  - train.width_mm) ^ 2),
                        train.id
           ) AS rank
    FROM test CROSS JOIN train
),
votes AS (
    -- How many of the 5 nearest neighbors have each variety.
    SELECT id, actual, neighbor, count(*) AS n
    FROM ranked
    WHERE rank <= 5
    GROUP BY id, actual, neighbor
),
predictions AS (
    -- The variety with the most votes. With two varieties and k = 5 it cannot tie.
    SELECT DISTINCT ON (id) id, actual, neighbor AS predicted
    FROM votes
    ORDER BY id, n DESC
),
totals AS (
    SELECT (SELECT count(*) FROM train)                 AS train_count,
           (SELECT count(*) FROM test)                  AS test_count,
           count(*) FILTER (WHERE predicted = actual)   AS correct
    FROM predictions
)
SELECT name, value
FROM totals,
LATERAL (VALUES
    (1, 'train_count', train_count::text),
    (2, 'test_count',  test_count::text),
    (3, 'correct',     correct::text),
    (4, 'accuracy',    round(correct::numeric / test_count, 6)::text)
) AS results (position, name, value)
ORDER BY position;

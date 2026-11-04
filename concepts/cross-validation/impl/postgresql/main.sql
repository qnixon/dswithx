-- 5-fold cross-validation for k-nearest neighbors, in PostgreSQL.
--
-- Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
-- holding out one fold at a time, picks the k with the best accuracy, and
-- then scores that k once on the untouched test seeds. There are no loops:
-- the folds and the values of k are columns, joined and grouped.

WITH train AS (
    -- run.sh numbers rows in file order as row_id. Numbering the training
    -- rows from 0 puts rows 0-29 in fold 0, rows 30-59 in fold 1, and so on.
    SELECT row_id AS id, length_mm, width_mm, variety,
           (row_number() OVER (ORDER BY row_id) - 1)
               / (count(*) OVER () / 5) AS fold   -- integer division
    FROM data
    WHERE split = 'train'
),
test AS (SELECT row_id AS id, length_mm, width_mm, variety FROM data WHERE split = 'test'),
ks AS (SELECT k FROM generate_series(1, 15, 2) AS k),   -- odd k, so votes can't tie
ranked AS (
    -- Each held-out seed against the training seeds in the other folds,
    -- ranked by distance. Equal distances keep the earlier row, train.id.
    SELECT held.id, held.variety AS actual, train.variety AS neighbor,
           row_number() OVER (
               PARTITION BY held.id
               ORDER BY sqrt((held.length_mm - train.length_mm) ^ 2
                           + (held.width_mm  - train.width_mm) ^ 2),
                        train.id
           ) AS rank
    FROM train AS held
    JOIN train ON train.fold <> held.fold
),
cv_votes AS (
    -- The rank list is computed once, then reused for every k: the k nearest
    -- are the rows ranked 1 to k.
    SELECT k, id, actual, neighbor, count(*) AS n
    FROM ks JOIN ranked ON rank <= k
    GROUP BY k, id, actual, neighbor
),
cv_predictions AS (
    SELECT DISTINCT ON (k, id) k, id, actual, neighbor AS predicted
    FROM cv_votes
    ORDER BY k, id, n DESC
),
cv AS (
    SELECT k, round(count(*) FILTER (WHERE predicted = actual)::numeric
                    / count(*), 6) AS accuracy
    FROM cv_predictions
    GROUP BY k
),
best AS (
    -- Highest accuracy first; on a tie, the smaller k.
    SELECT k FROM cv ORDER BY accuracy DESC, k LIMIT 1
),
test_ranked AS (
    -- Only now touch the test seeds, once, against all of the training seeds.
    SELECT test.id, test.variety AS actual, train.variety AS neighbor,
           row_number() OVER (
               PARTITION BY test.id
               ORDER BY sqrt((test.length_mm - train.length_mm) ^ 2
                           + (test.width_mm  - train.width_mm) ^ 2),
                        train.id
           ) AS rank
    FROM test CROSS JOIN train
),
test_predictions AS (
    SELECT DISTINCT ON (id) id, actual, neighbor AS predicted
    FROM (
        SELECT id, actual, neighbor, count(*) AS n
        FROM test_ranked JOIN best ON rank <= best.k
        GROUP BY id, actual, neighbor
    ) AS votes
    ORDER BY id, n DESC
),
totals AS (
    SELECT (SELECT count(*) FROM train)               AS train_count,
           (SELECT count(*) FROM test)                AS test_count,
           (SELECT k FROM best)                       AS best_k,
           count(*) FILTER (WHERE predicted = actual) AS correct
    FROM test_predictions
)
SELECT name, value
FROM (
    SELECT 1 AS position, 'train_count' AS name, train_count::text AS value FROM totals
    UNION ALL SELECT 2, 'test_count', test_count::text FROM totals
    UNION ALL SELECT 2 + k, 'cv_accuracy_k' || k, accuracy::text FROM cv
    UNION ALL SELECT 20, 'best_k', best_k::text FROM totals
    UNION ALL SELECT 21, 'test_correct', correct::text FROM totals
    UNION ALL SELECT 22, 'test_accuracy',
                     round(correct::numeric / test_count, 6)::text FROM totals
) AS results
ORDER BY position;

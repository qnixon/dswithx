-- A decision tree classifier (CART with Gini impurity), in PostgreSQL.
--
-- Grows a tree on the training days by always making the split that leaves the
-- two sides purest, then predicts rain for the test days. The tree grows one
-- level at a time in a WITH RECURSIVE query: each row is a node, named by its
-- path from the root ('' is the root, 'LR' is the root's left child's right
-- child), holding the ids of the days that reach it. Test days ride along
-- without being counted, so each one ends up in the leaf that predicts it.

WITH RECURSIVE days AS (
    SELECT row_id AS id, split, rain = 'yes' AS yes, humidity, pressure, wind FROM data
),
features AS (
    -- One row per (day, feature), so every feature is split the same way.
    -- f numbers the features in column order, which decides ties.
    SELECT d.id, d.split, d.yes, v.f, v.value
    FROM days d,
    LATERAL (VALUES (1, d.humidity), (2, d.pressure), (3, d.wind)) AS v (f, value)
),
tree (path, depth, members, split_f, split_t) AS (
    SELECT '', 0, array_agg(id ORDER BY id), NULL::int, NULL::double precision
    FROM days

    UNION ALL

    -- Split a node into two children. Each child row also records the split
    -- that made it (the parent's feature and threshold). A node that should
    -- stay a leaf fails the WHERE clause and gets no children.
    SELECT s.path || side, s.depth + 1, child.members, best.f, best.threshold
    FROM tree s,
    LATERAL (
        -- The node's training days and its Gini impurity, 1 - p^2 - (1 - p)^2,
        -- with p the share of "yes".
        SELECT n, 1 - (yes / n) ^ 2 - (1 - yes / n) ^ 2 AS gini
        FROM (
            SELECT count(*)::double precision AS n, count(*) FILTER (WHERE yes) AS yes
            FROM days
            WHERE split = 'train' AND id = ANY (s.members)
        ) AS counts
    ) AS node,
    LATERAL (
        -- Every candidate split and its weighted Gini; the lowest wins, and a
        -- tie goes to the earlier feature, then the smaller threshold.
        SELECT c.f, c.threshold,
               (nl * (1 - (yl / nl) ^ 2 - (1 - yl / nl) ^ 2)
                + nr * (1 - (yr / nr) ^ 2 - (1 - yr / nr) ^ 2)) / node.n AS score
        FROM (
            -- Thresholds: midpoints of consecutive distinct values.
            SELECT f, (value + lead(value) OVER (PARTITION BY f ORDER BY value)) / 2 AS threshold
            FROM (
                SELECT DISTINCT f, value FROM features
                WHERE split = 'train' AND id = ANY (s.members)
            ) AS distinct_values
        ) AS c,
        LATERAL (
            -- Left is value <= threshold. The casts avoid integer division.
            SELECT count(*) FILTER (WHERE value <= c.threshold)::double precision AS nl,
                   count(*) FILTER (WHERE value <= c.threshold AND yes) AS yl,
                   count(*) FILTER (WHERE value > c.threshold)::double precision AS nr,
                   count(*) FILTER (WHERE value > c.threshold AND yes) AS yr
            FROM features
            WHERE f = c.f AND split = 'train' AND id = ANY (s.members)
        ) AS sides
        WHERE c.threshold IS NOT NULL
        ORDER BY score, c.f, c.threshold
        LIMIT 1
    ) AS best,
    LATERAL (VALUES ('L'), ('R')) AS sides (side),
    LATERAL (
        -- Route every day, training or test, to its side.
        SELECT array_agg(id ORDER BY id) AS members
        FROM features
        WHERE f = best.f AND id = ANY (s.members)
          AND (value <= best.threshold) = (side = 'L')
    ) AS child
    -- Stop at a pure node, a node with fewer than 5 days, depth 3, or when no
    -- split makes the sides purer.
    WHERE node.gini > 0 AND node.n >= 5 AND s.depth < 3 AND best.score < node.gini
),
nodes AS (
    -- Number the nodes in preorder. In byte order ("C" collation) a path
    -- sorts right after its parent's, and 'L' before 'R'.
    SELECT t.path, t.members,
           row_number() OVER (ORDER BY t.path COLLATE "C") AS k,
           left_child.split_f, left_child.split_t
    FROM tree t
    LEFT JOIN tree left_child ON left_child.path = t.path || 'L'
),
leaves AS (
    -- A leaf predicts "yes" only if most of its training days are "yes";
    -- an even split predicts "no".
    SELECT k, members,
           (SELECT count(*) FILTER (WHERE yes) > count(*) / 2.0
            FROM days WHERE split = 'train' AND id = ANY (members)) AS predict_yes
    FROM nodes
    WHERE split_f IS NULL
),
scores AS (
    -- Every day sits in exactly one leaf, whose prediction it gets.
    SELECT count(*) FILTER (WHERE d.split = 'train') AS train_count,
           count(*) FILTER (WHERE d.split = 'train' AND d.yes = l.predict_yes) AS train_correct,
           count(*) FILTER (WHERE d.split = 'test') AS test_count,
           count(*) FILTER (WHERE d.split = 'test' AND d.yes = l.predict_yes) AS correct
    FROM leaves l
    JOIN days d ON d.id = ANY (l.members)
)
SELECT name, value
FROM (
    SELECT 1 AS position, 0 AS line, 'train_count' AS name, train_count::text AS value FROM scores
    UNION ALL
    SELECT 2, 0, 'test_count', test_count::text FROM scores
    UNION ALL
    -- A split prints two lines and a leaf one, all in preorder.
    SELECT 3, 2 * k, format('node_%s_feature', k),
           (ARRAY['humidity', 'pressure', 'wind'])[split_f]
    FROM nodes WHERE split_f IS NOT NULL
    UNION ALL
    SELECT 3, 2 * k + 1, format('node_%s_threshold', k), round(split_t::numeric, 6)::text
    FROM nodes WHERE split_f IS NOT NULL
    UNION ALL
    SELECT 3, 2 * k, format('node_%s_predict', k), CASE WHEN predict_yes THEN 'yes' ELSE 'no' END
    FROM leaves
    UNION ALL
    SELECT 4, 0, 'leaves', count(*)::text FROM leaves
    UNION ALL
    SELECT 5, 0, 'train_accuracy', round(train_correct::numeric / train_count, 6)::text FROM scores
    UNION ALL
    SELECT 6, 0, 'correct', correct::text FROM scores
    UNION ALL
    SELECT 7, 0, 'accuracy', round(correct::numeric / test_count, 6)::text FROM scores
) AS results
ORDER BY position, line;

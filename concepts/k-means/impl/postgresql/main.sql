-- k-means clustering (Lloyd's algorithm, k = 3), in PostgreSQL.
--
-- Starts from the first 3 points as centroids, then alternates two steps until
-- no point changes cluster: assign each point to its nearest centroid, and move
-- each centroid to the mean of its points. The loop is a WITH RECURSIVE query
-- whose state is one row of arrays: the centroids and every point's cluster.

WITH RECURSIVE points AS (
    -- A table has no row order; run.sh numbers rows in file order as row_id.
    SELECT row_id AS id, x, y FROM data
),
steps (iteration, cx, cy, assignment, done) AS (
    -- Iteration 0: the first 3 points are the centroids; nothing is assigned yet.
    SELECT 0,
           array_agg(x ORDER BY id),
           array_agg(y ORDER BY id),
           NULL::int[],
           false
    FROM points
    WHERE id <= 3

    UNION ALL

    SELECT s.iteration + 1, moved.cx, moved.cy, assigned.assignment,
           assigned.assignment IS NOT DISTINCT FROM s.assignment
    FROM steps s,
    LATERAL (
        -- Assign: each point's nearest centroid (ties go to the lower index).
        SELECT array_agg(nearest.j ORDER BY p.id) AS assignment
        FROM points p,
        LATERAL (
            SELECT j FROM generate_series(1, 3) AS j
            ORDER BY sqrt((p.x - s.cx[j]) ^ 2 + (p.y - s.cy[j]) ^ 2), j
            LIMIT 1
        ) AS nearest
    ) AS assigned,
    LATERAL (
        -- Update: each centroid moves to the mean of its points; an empty
        -- cluster keeps its old centroid.
        SELECT array_agg(coalesce(sum_x / n, s.cx[j]) ORDER BY j) AS cx,
               array_agg(coalesce(sum_y / n, s.cy[j]) ORDER BY j) AS cy
        FROM (
            SELECT j, sum(p.x) AS sum_x, sum(p.y) AS sum_y, nullif(count(p.id), 0) AS n
            FROM generate_series(1, 3) AS j
            LEFT JOIN points p ON assigned.assignment[p.id] = j
            GROUP BY j
        ) AS clusters
    ) AS moved
    -- Stop once an assignment pass changed nothing (or after 100 passes).
    WHERE NOT s.done AND s.iteration < 100
),
final AS (
    SELECT * FROM steps ORDER BY iteration DESC LIMIT 1
),
members AS (
    -- Each point with its final cluster.
    SELECT p.x, p.y, a.j, f.cx[a.j] AS cx, f.cy[a.j] AS cy
    FROM final f,
    unnest(f.assignment) WITH ORDINALITY AS a (j, id)
    JOIN points p ON p.id = a.id
),
sizes AS (
    -- count(m.j) is 0 for an empty cluster.
    SELECT j, count(m.j) AS size
    FROM generate_series(1, 3) AS j
    LEFT JOIN members m USING (j)
    GROUP BY j
),
inertia AS (
    SELECT sum((x - cx) ^ 2 + (y - cy) ^ 2) AS inertia FROM members
)
SELECT name, value
FROM (
    SELECT 0 AS position, 'iterations' AS name, iteration::text AS value FROM final
    UNION ALL
    SELECT 2 * j - 1, format('centroid_%s_x', j), round(f.cx[j]::numeric, 6)::text
    FROM final f, generate_series(1, 3) AS j
    UNION ALL
    SELECT 2 * j, format('centroid_%s_y', j), round(f.cy[j]::numeric, 6)::text
    FROM final f, generate_series(1, 3) AS j
    UNION ALL
    SELECT 6 + j, format('size_%s', j), size::text FROM sizes
    UNION ALL
    SELECT 10, 'inertia', round(inertia::numeric, 6)::text FROM inertia
) AS results
ORDER BY position;

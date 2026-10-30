-- Categorical naive Bayes with add-one (Laplace) smoothing, in PostgreSQL.
--
-- Learns P(label) and P(feature value | label) by counting training rows, then
-- labels each test row with the label that has the highest log-probability.

WITH emails AS (
    SELECT row_id AS id, has_link, mentions_money, known_sender, label, split FROM data
),
features AS (
    -- One row per (email, feature), so every feature is counted the same way.
    SELECT id, label, split, feature, value
    FROM emails,
    LATERAL (VALUES
        ('has_link',       has_link),
        ('mentions_money', mentions_money),
        ('known_sender',   known_sender)
    ) AS f (feature, value)
),
label_counts AS (
    -- n_c, and the training total n.
    SELECT label, count(*) AS n_c, (sum(count(*)) OVER ())::bigint AS n
    FROM emails
    WHERE split = 'train'
    GROUP BY label
),
value_counts AS (
    -- n_{c,v}: training emails with label c whose feature has value v.
    SELECT feature, value, label, count(*) AS n_cv
    FROM features
    WHERE split = 'train'
    GROUP BY feature, value, label
),
distinct_values AS (
    -- m_j: how many distinct values each feature takes in the training data.
    SELECT feature, count(DISTINCT value) AS m
    FROM features
    WHERE split = 'train'
    GROUP BY feature
),
scores AS (
    -- log P(c) + sum over features of log P(v_j | c), for each test email and label.
    SELECT t.id, t.label AS actual, c.label,
           ln(c.n_c::double precision / c.n)
             + sum(ln((coalesce(vc.n_cv, 0) + 1)::double precision / (c.n_c + d.m))) AS score
    FROM features t
    CROSS JOIN label_counts c
    JOIN distinct_values d USING (feature)
    LEFT JOIN value_counts vc
           ON vc.feature = t.feature AND vc.value = t.value AND vc.label = c.label
    WHERE t.split = 'test'
    GROUP BY t.id, t.label, c.label, c.n_c, c.n
),
predictions AS (
    -- Highest score wins; an exact tie goes to the alphabetically first label.
    SELECT DISTINCT ON (id) id, actual, label AS predicted
    FROM scores
    ORDER BY id, score DESC, label
),
totals AS (
    SELECT (SELECT sum(n_c) FROM label_counts)          AS train_count,
           count(*)                                     AS test_count,
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

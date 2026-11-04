-- Evaluation metrics for a binary classifier, in PostgreSQL.
--
-- Reads each part's true label and the model's score, then reports the
-- confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
-- the accuracy of never flagging anything, and the area under the ROC curve.

WITH parts AS (
    -- run.sh loads both columns as double precision. The label is 0 or 1,
    -- so we turn it into a boolean; scores that are equal text in the file
    -- load as equal doubles, so ties stay ties.
    SELECT defective = 1 AS defective, score FROM data
),
thresholds (suffix, threshold) AS (
    VALUES ('50', 0.5::double precision), ('30', 0.3)
),
counts AS (
    -- One row per threshold. A part is flagged when its score reaches the
    -- threshold; FILTER counts only the rows its condition keeps.
    SELECT suffix, threshold,
           count(*) FILTER (WHERE score >= threshold AND defective) AS tp,
           count(*) FILTER (WHERE score >= threshold AND NOT defective) AS fp,
           count(*) FILTER (WHERE score < threshold AND defective) AS fn,
           count(*) FILTER (WHERE score < threshold AND NOT defective) AS tn
    FROM thresholds CROSS JOIN parts
    GROUP BY suffix, threshold
),
metrics AS (
    -- count(*) gives whole numbers, and dividing integers in SQL drops the
    -- fraction, so we cast to numeric first.
    SELECT suffix, threshold, tp, fp, fn, tn,
           (tp + tn)::numeric / (tp + fp + fn + tn) AS accuracy,
           tp::numeric / (tp + fp) AS precision,   -- of the flagged, how many defective
           tp::numeric / (tp + fn) AS recall       -- of the defective, how many flagged
    FROM counts
),
auc AS (
    -- The chance that a random defective part outscores a random good one.
    -- Join every defective part with every good one, score 2 for a win and
    -- 1 for a tie, and divide the whole-number total once at the end.
    SELECT sum(CASE WHEN d.score > g.score THEN 2
                    WHEN d.score = g.score THEN 1
                    ELSE 0 END)::numeric / (2 * count(*)) AS auc
    FROM parts AS d JOIN parts AS g ON d.defective AND NOT g.defective
),
summary AS (
    SELECT count(*) AS parts, count(*) FILTER (WHERE defective) AS defective
    FROM parts
)
SELECT name, value
FROM (
    -- Rounding a numeric to 6 places prints 6 decimals. Rows sort by
    -- section, then threshold from high to low, then line within a
    -- threshold's group of eight; rows outside the groups use threshold 0.
    SELECT 1 AS section, 0 AS threshold, 0 AS line, 'parts' AS name, parts::text AS value
    FROM summary
    UNION ALL SELECT 2, 0, 0, 'defective', defective::text FROM summary
    UNION ALL SELECT 3, 0, 0, 'baseline_accuracy',
                     round((parts - defective)::numeric / parts, 6)::text FROM summary
    UNION ALL SELECT 4, threshold, 1, 'tp_at_' || suffix, tp::text FROM metrics
    UNION ALL SELECT 4, threshold, 2, 'fp_at_' || suffix, fp::text FROM metrics
    UNION ALL SELECT 4, threshold, 3, 'fn_at_' || suffix, fn::text FROM metrics
    UNION ALL SELECT 4, threshold, 4, 'tn_at_' || suffix, tn::text FROM metrics
    UNION ALL SELECT 4, threshold, 5, 'accuracy_at_' || suffix, round(accuracy, 6)::text
              FROM metrics
    UNION ALL SELECT 4, threshold, 6, 'precision_at_' || suffix, round(precision, 6)::text
              FROM metrics
    UNION ALL SELECT 4, threshold, 7, 'recall_at_' || suffix, round(recall, 6)::text
              FROM metrics
    UNION ALL SELECT 4, threshold, 8, 'f1_at_' || suffix,
                     round(2 * precision * recall / (precision + recall), 6)::text
              FROM metrics
    UNION ALL SELECT 5, 0, 0, 'auc', round(auc, 6)::text FROM auc
) AS results
ORDER BY section, threshold DESC, line;

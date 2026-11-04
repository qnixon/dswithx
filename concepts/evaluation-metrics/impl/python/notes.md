Each part becomes a pair of a bool and a float, and one loop per threshold
sorts every part into one of four counts: true positives, false
positives, false negatives, and true negatives. Every metric is a ratio of
those counts.

The AUC compares every defective part with every good one, 33 times 167
pairs. A win scores 2 and a tie 1, so the total stays a whole number until
the last division.
scikit-learn's `roc_auc_score` and `classification_report` do this, but
scikit-learn isn't installed.

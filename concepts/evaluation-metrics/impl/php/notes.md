Each part becomes a pair of a bool and a float, and one loop per
threshold sorts every part into one of four counts: true positives, false
positives, false negatives, and true negatives. `foreach` unpacks each
pair straight into two variables. Every metric is a ratio of those counts.

For the AUC we use the spaceship operator: `$d <=> $g` returns 1, 0, or
-1, so adding 1 scores a win as 2, a tie as 1, and a loss as 0 across all
33 times 167 pairs. `array_filter` counts the defective parts. Composer
packages aren't installed.

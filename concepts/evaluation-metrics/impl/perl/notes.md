Each part becomes a two-element array reference, a label and a score, and
one loop per threshold sorts every part into one of four counts: true
positives, false positives, false negatives, and true negatives. Every
metric is a ratio of those counts.

For the AUC we lean on the spaceship operator: `$d <=> $g` returns 1, 0,
or -1, so adding 1 scores a win as 2, a tie as 1, and a loss as 0, with no
branching. `grep` in scalar context counts the defective parts. CPAN
modules, such as Statistics::ROC, aren't installed.

The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in and two more parameters, `lo` and `hi`, naming rows to skip. That
is how we build folds: awk can't slice or copy an array in one step, so
nothing is copied. Each held-out seed is classified against every training
row outside `lo` to `hi`, and the final test run passes `1, 0`, a range that
skips nothing.

POSIX awk has no sort, so `classify` still picks the nearest unused seed k
times, with a strict `<` that keeps the earlier row on equal distances. At
k = 15 that's 15 scans of 150 rows per seed, and it still finishes quickly.

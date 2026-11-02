Each email is a `struct` holding its three feature values, label, and split
as fixed-size character arrays, and the training set is an array of pointers
into the rows, so it copies no data. C has no dictionary, so we store no
counts at all: `count_rows` recounts matching training rows, comparing text
with `strcmp`, each time a score needs one.

The distinct labels go through `qsort` with `strcmp`, which orders by
character code, so `"Spam"` would sort before `"ham"`; all our labels are
lowercase. Only a strictly higher score replaces the best, so an exact tie
goes to the alphabetically first label. C has no naive Bayes function to
avoid.

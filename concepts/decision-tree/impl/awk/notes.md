A tree is recursive, and so is the `grow` function. Each call gets the ids
of its days in an array, finds the best split, and calls itself on the two
halves. That works since locals declared as extra parameters, arrays like
`ldays` and `rdays` included, are fresh in every call. There are no records,
so node `k` lives in parallel arrays, `split_f`, `split_t`, `left`, `right`,
and `predict`, numbered in preorder as it's grown.

POSIX awk has no sort (mawk answers `asort` with "function asort never
defined"), so each feature's distinct values are kept sorted by insertion.
awk has no decision tree built in. It runs unchanged on mawk, which the
tests use, and on macOS awk.

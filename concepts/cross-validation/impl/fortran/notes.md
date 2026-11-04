The classifier from the k-nearest neighbors page now takes the reference
seeds and `k` as arguments. Each fold comes from array sections:
`train(first:last)` is the held-out block of 30, and the array constructor
`[ ... ]` joins `train(:first - 1)` and `train(last + 1:)`, the rows before
and after it, into a new array of 120. For the first fold, `train(:0)` is an empty
section, so nothing special is needed at the edges.

Fortran has no sort, so `minloc` with a mask still picks the nearest seeds
one at a time, and its first-of-equals rule keeps file order on ties.
Labels such as `cv_accuracy_k7` are built with an internal `write`.

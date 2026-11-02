Each email's three feature values go in a two-dimensional text array,
`V$(row, feature)`, and the training rows are listed by number in `T`. We
store no counts: subroutine 5000 rescans the training rows, comparing text
with `=`, each time a score needs one, then adds the logs with `LOG`.

One surprise shaped the code: in this interpreter, `FOR E = 1 TO 0` still
runs its body once, so the searches over earlier rows and the insertion sort
of labels use `WHILE`, which skips an empty range. `<=` compares text by
character code, so `"Spam"` would sort before `"ham"`; our labels are
lowercase, and an exact tie goes to the first in that order. BASIC has no naive Bayes function.

Fortran is at home with the arithmetic: `sum((values - mean)**2)` works on
the whole array at once, with no loop. It has no `mean`, `median`, or
variance intrinsic, so there was nothing to skip.

What it lacks is everything around the numbers. There's no sort, since a
call to `sort` fails to link, so we write an insertion sort. There's no CSV
reader either, so `field` cuts a line at its commas, and an internal
`read` turns the text into a number. The array grows one value at a time
with `column_values = [column_values, value]`, which reallocates it to
fit. Most of the 134 lines are this plumbing.

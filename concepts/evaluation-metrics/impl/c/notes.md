We read the labels and scores into two parallel arrays. `report` makes
one pass per threshold, sorting each part into true positives, false
positives, false negatives, or true negatives. Each metric is a ratio of
those four `int` counts, and we cast one side to `double` before dividing,
since `int / int` in C drops the fraction.

The AUC uses two nested loops, skipping the wrong label in
each, so every defective part meets every good one. A win adds 2 points and
a tie 1, the total stays a `long`, and we divide only once, at the end.
Scores that are equal text in the file parse to equal doubles, so `==`
catches the 3 tied pairs.

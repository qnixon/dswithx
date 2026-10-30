The algorithm maps neatly onto COBOL paragraphs: `ASSIGN-POINTS`,
`MOVE-CENTROIDS`, and a `DISTANCE` helper, repeated with `PERFORM UNTIL`
until nothing changes. Each point's row in the table stores its cluster
number, so a change is noticed the moment it happens. Numbers are
fixed-point decimals, with centroids held to 12 places in `PIC
S9(9)V9(12)`.

Paragraphs take no arguments, though. `DISTANCE` works on whatever the
shared `I` and `J` hold, so every caller sets them first. Printing names
like `centroid_2_x` takes a `STRING` statement and an edited picture to
drop the leading zero. The result is 227 lines, about four times the
Python's 55. GnuCOBOL has `MEAN` and `VARIANCE` functions, but nothing for
clustering.

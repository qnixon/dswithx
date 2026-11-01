Assignment is one table: `∘.-` subtracts every centroid from every point, so
squaring, adding, and taking `*0.5` gives a 150 by 3 table of distances.
For each row, `⍵⍳⌊/⍵` finds the first minimum, so a tie goes to the lower
centroid. To move the centroids, `A∘.=⍳K` marks each point's cluster with a
1, and a matrix product, `(⍉B)+.×P`, sums each cluster's points in one step.

GNU APL's `{}` functions fit on one line, so the loop is a `∇` function that
jumps to a label with `→`. One trap: `0÷0` is 1 in APL, not an error, so we
divide only for clusters that have points.

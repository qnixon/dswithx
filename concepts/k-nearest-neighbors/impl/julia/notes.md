Each seed is a small `struct` holding its point and its variety, and the
nearest five come from `sort(train, by = ...)`. Julia's default sort is
documented as stable, so seeds at equal distances keep their file order, as
in Python. The distance is written out as
`sqrt(sum((a .- b) .^ 2))`; Base has no distance function to avoid.

Julia has no `Counter`, so the votes go into a `Dict` with
`get(votes, variety, 0) + 1`. A `Dict` doesn't keep insertion order, so a
tied vote is settled by walking the nearest seeds in order and taking the
first variety with the most votes.

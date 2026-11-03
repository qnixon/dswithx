We read every row into a map keyed by the header's column names, split the
rows into training and test seeds with `Enum.split_with`, and, for each test
seed, sort all 150 training seeds by Euclidean distance and let the 5
nearest vote.

`Enum.sort_by` is a stable merge sort, so seeds at exactly equal distances
keep file order. `Enum.frequencies` counts the votes, but its map doesn't
keep first-seen order, so we walk the varieties as they appear and let
`Enum.max_by`, which returns the first of equal maxima, pick the winner.
Nothing here is a kNN classifier, and Hex packages such as Nx aren't
installed.

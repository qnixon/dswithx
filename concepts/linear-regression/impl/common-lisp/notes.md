We read `hours` and `score` as two separate lists of doubles, each found by
its header name, and pair them back up with `mapcar`. Given two lists,
`mapcar` walks them side by side, so `(mapcar #'* dxs dys)` multiplies each
hours deviation by the score deviation from the same row, and
`(reduce #'+ ...)` adds the products into Sxy.

Common Lisp has no mean, so a small `mean` function divides the `reduce`
total by `length`. The two passes are the order of the `let*`: the means
come first, then the deviation lists built from them. No regression or
correlation function is called, and there's none in the standard to skip.

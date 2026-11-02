Every expression is a list with the operator first, so the mean is
`(/ sum n)` and the variance sums `(expt (- x mean) 2)` over the list with
`mapcar` and `reduce`. Common Lisp has no mean, median, or variance to
skip, and no string split, so `split-on-comma` is a short `loop`.

Watch the first `setf`. The Lisp reader turns `28.6` into a single float
unless told otherwise, and without that line the sum comes out 3561.300007
and the max 61.299999. Watch `sort`, too: it may take apart the list you
give it, so we keep only the list it returns.

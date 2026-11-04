A matrix is a list of rows, and the elimination is recursive. `foldl`
walks the rows to find the one with the largest first entry (partial
pivoting), `selectchk` takes it out, and every other row has a multiple
of it subtracted. The smaller system that's left goes back into
`eliminate`.

The speeds are read as integers, and SWI-Prolog's `/` returns an integer
when it divides exactly: `(75-42)/33` is `1`, but `7/2` is `3.5`. So
`float/1` makes every z a float. The sums use `aggregate_all(sum(...))`,
and no solver or fitting predicate is called.

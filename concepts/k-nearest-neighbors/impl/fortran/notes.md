Each seed is a derived type holding its two measurements and its variety, and
`norm2(point - train(i)%point)` is the distance: `norm2` gives the Euclidean
length of a vector, a general tool like Python's `math.dist`.

Fortran has no sort intrinsic, so we pick the nearest five one at a time with
`minloc(distance, dim=1, mask=.not. taken)`. `minloc` returns the first of
equal minimums, so equal distances keep file order, as a stable sort would.
`maxloc` does the same for votes, so a tie goes to the variety seen first. One
gfortran surprise: an internal `read` can't parse straight from a function's
result, so each field is copied into a variable first.

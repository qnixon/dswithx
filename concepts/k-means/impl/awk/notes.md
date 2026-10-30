The arithmetic is easy in awk. Assigning points and averaging clusters are
short loops, and the "did anything change?" check happens inside the loop
that makes the assignment. `assign[i]` starts out empty, so the first pass
always counts as a change with no special case.

Structure is where awk pushes back. POSIX awk has no arrays of arrays, so
points and centroids are pairs of parallel arrays, `px`, `py`, `cx`, and
`cy`, which the helper functions `dist2` and `nearest` share as globals. And
since every point is needed before the first pass, all the real work sits
in `END`. awk has no clustering built in.

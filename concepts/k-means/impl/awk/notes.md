<!-- Placeholder text: to be written. -->

**Easy:** the arithmetic. Assigning points and averaging clusters are short
loops, and comparing the new assignment with the old one happens in the same
loop that makes it.

**Hard:** structure. awk has no arrays of points or arrays of arrays, so
points and centroids are pairs of parallel arrays (`px`, `py`, `cx`, `cy`)
shared as globals by the helper functions. The whole file must also be read
before the first iteration, so all the work sits in `END`.

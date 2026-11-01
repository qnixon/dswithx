Rust gives each piece a precise type. A point is `[f64; 2]`, a fixed-size
array, and "no assignment yet" is `None` rather than a sentinel value, so
the first pass can't be mistaken for a repeat. Two assignments are compared
with `==` on vectors, which checks every element.

Nearest-centroid search is a plain loop. Only a strictly smaller distance
replaces the best, so a tie goes to the lower index. We compare squared
distances, which needs no square root, and inertia uses them directly. An
empty cluster keeps its old centroid. The standard library has no clustering,
so there was no built-in to skip.

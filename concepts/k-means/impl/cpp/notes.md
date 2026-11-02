Each point is a small `struct` with `x` and `y` fields, as in C, but the
points, centroids, and assignment all live in a `std::vector`, which grows
as you `push_back`, so there's no `realloc`.

Where C sets a flag as it goes, we notice that nothing changed by comparing
the whole assignment with the last one: `==` on two vectors checks their
lengths and then every element, and the first pass compares against an
empty vector, so it never matches. `nearest` hands squared distances to
`std::min_element`, which returns the first of equal smallest values, so
ties go to the lower index. C++ has no k-means function to avoid.

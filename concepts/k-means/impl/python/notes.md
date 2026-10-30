Python keeps the whole loop short. `math.dist` gives the Euclidean distance,
and `min(range(K), key=...)` picks the nearest centroid; `min` returns the
first of equal values, so a tie would go to the lower index. Points are
plain tuples, and comparing two lists with `==` tells you when the
assignments stopped changing.

The one trap is an empty cluster, which has no mean. Our data never
produces one, but the code keeps the old centroid if it does.

There was no built-in to skip this time: the standard library has no
clustering at all, so in real code you'd reach for a third-party package.

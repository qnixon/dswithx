Each point is the term `X-Y`. The `-` only pairs the two numbers, since
only `is` does arithmetic, and `pairs_keys_values` splits points back
into their x and y lists. Prolog has no loops, so `run` repeats by calling
itself with the moved centroids. Its previous assignment starts as the
atom `none`, and "nothing changed" is one `==` between whole lists.

`nearest` asks `aggregate_all(min(D, I), ...)` for the smallest squared
distance and the centroid number that went with it. When several
solutions share the minimum, it keeps the first, so a tie goes to the
lower index. There's no clustering, mean, or distance built in to skip.

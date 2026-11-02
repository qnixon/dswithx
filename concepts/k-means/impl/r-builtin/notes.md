`kmeans()` is part of base R's `stats` package, but its defaults don't run
the method on this page. It picks random starting centroids, and it uses
the Hartigan-Wong algorithm, which moves single points between clusters
whenever that lowers the total.

So we pass `centers = points[1:k, ]` to start from the first three points
and `algorithm = "Lloyd"` for the assign-then-update loop, and the results
match exactly. `fit$iter` counts the passes the same way, including the
last one, and `tot.withinss`, the total within-cluster sum of squares, is
the inertia.

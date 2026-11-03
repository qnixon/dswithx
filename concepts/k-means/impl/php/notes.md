Each point is a two-element array, so `$p[0]` is its x. PHP arrays are
values, not references: assigning one makes a copy, so the centroids start
as copies of the first three points, and moving a centroid never moves a
point. A loop keeps the first nearest centroid, and only a strictly smaller
distance replaces it, so ties go to the lower index.

In PHP, `===` compares two whole arrays, key by key and
value by value, so one comparison tells you the assignments stopped
changing. `array_column` pulls out every x or every y for the means. PHP has
no clustering built in, so there's nothing to skip.

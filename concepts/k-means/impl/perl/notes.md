Each point is a reference to a two-element array, so `$p->[0]` is its x,
and the centroids start as copies of the first three points, so moving a
centroid never moves a point. A loop keeps the first nearest centroid, and
only a strictly smaller distance replaces it, so ties go to the lower
index.

Perl arrays have no `==`, so we compare whole assignments as strings:
putting an array inside quotes, as in `"@assignment"`, joins its cluster
numbers with spaces, and `eq` compares the two strings. `sum` comes from List::Util, a core module. Perl has no clustering
built in, so there's nothing to skip.

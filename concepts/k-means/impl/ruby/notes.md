Ruby reads close to the description of the algorithm. Points are
two-element arrays, `min_by` picks the nearest centroid and returns the
first of equal values, and `transpose` turns a cluster's points into an x
column and a y column, so the new centroid is one `map`. Array `==`
compares element by element, which makes "did anything change?" a single
comparison.

Ruby pushed back only on reading the file. `csv` is a bundled gem rather
than part of the standard library, so we split each line on commas by
hand, which is fine for this file. The standard library has no clustering
to skip.

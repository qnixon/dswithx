<!-- Placeholder text: to be written. -->

**Easy:** `min_by` returns the first of equal values, so "ties go to the lower
index" comes for free. `transpose` turns a cluster's points into columns, so
the new centroid is one `map`. Array `==` compares element by element, which
makes the "did anything change?" check a single comparison.

**Hard:** little. The loop needs care to count the final, unchanged assignment
pass as an iteration, but that is the algorithm, not Ruby.

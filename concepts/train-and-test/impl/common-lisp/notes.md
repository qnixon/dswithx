The normal equations sit in a 2-D array built with `make-array` and read
with `aref`. A 2-D array has no row objects to swap, so partial pivoting
swaps the two rows one entry at a time with `rotatef`, which exchanges the
values in two places. Elimination updates entries in place with `decf`.

Powers come from `expt`, and the sums are `loop ... sum` clauses. We read
every decimal as a double, since Common Lisp would otherwise read them as
single floats. No solver or fitting function is called: elimination, back
substitution, and the error sums are all written out.

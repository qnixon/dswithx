`encoding/csv` reads the file, and each drive becomes a `point` struct
sorted into train or test. The matrix is a slice of row slices, so a
parallel assignment, `m[a], m[b] = m[b], m[a]`, swaps two rows by swapping
slice headers, without copying the numbers inside. Elimination and back
substitution are plain nested `for` loops.

Powers come from `math.Pow`, which takes and returns `float64`, so each
exponent is wrapped in `float64(...)`. Go's standard library has no
linear algebra package, so there was no solver to skip; gonum has one, but
it isn't installed.

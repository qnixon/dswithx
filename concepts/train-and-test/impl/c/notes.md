We keep the training and test drives in separate parallel arrays of
doubles, then fit each degree from the training arrays alone. `fit` adds
up the normal equations into one fixed-size augmented matrix, a 2D array
with b as its last column, and `solve` runs Gaussian elimination with
partial pivoting on it.

C can't assign one array row to another, so the pivot swap trades the two
rows entry by entry. Everything beyond `pow`, `fabs`, and `sqrt` from `math.h` is a
plain loop.

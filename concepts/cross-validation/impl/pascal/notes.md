The kNN classifier is the one from the k-nearest neighbors page, with `K`
passed in instead of fixed at 5. Pascal's `for` loop only steps by one, so
we count from 0 to 7 and take K as 2I + 1. For each fold,
`Copy(Train, Start, Size)` copies the held-out block of a dynamic array,
and `Concat` joins copies of the rows before and after it into the rest.

Free Pascal has no cross-validation or kNN. `TArrayHelper.Sort` isn't
stable, so our comparison breaks distance ties by row number, and a
loop counts the votes, since `TDictionary` won't compile with warnings as
errors.

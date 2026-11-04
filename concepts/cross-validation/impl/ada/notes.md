The kNN classifier is the one from the k-nearest neighbors page, with `K`
passed in instead of fixed at 5. Ada's `for` loop has no step, so the loop
over K uses an Ada 2022 filter, `when K mod 2 = 1`, to keep the odd values.
`Ada.Containers.Vectors` has no slices, so for each fold we walk the
training rows and append each one to the held-out vector or the rest,
using a membership test, `I in A .. B`, for the block.

Ada has no cross-validation or kNN. `Generic_Array_Sort` is a heapsort, so
our `Nearer` comparison breaks distance ties by row number, and a loop
counts the votes.

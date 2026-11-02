C has no kNN classifier, hash table, or counter type, so we build the
pieces. A `struct seed` holds a seed's length, width, and variety, with the
variety copied into a fixed 16-character array, and the training and test
sets are arrays that grow with `realloc`.

For each test seed we fill a scratch array with every training seed's
distance and row number, then sort it with `qsort`. The C standard leaves
the order of equal elements unspecified, so the comparison function breaks
distance ties by row number, keeping file order. The vote compares labels
with `strcmp`, since `==` on two strings only compares their addresses.

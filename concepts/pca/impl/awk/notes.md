awk has no matrices, so the data, the correlation matrix, and its deflated
copy all live in arrays keyed like `m[i, j]`, which awk joins into one
string key with `SUBSEP`. Every product is a written-out loop. Power
iteration is one function used twice. An awk function can't return an
array, but arrays are passed by reference, so `top_eigenvector` fills in
the vector it's given and returns the eigenvalue. Its extra parameters are
how awk declares local variables. awk has no linear algebra built in, so
there was nothing to skip. It sticks to POSIX awk and runs on mawk and on
macOS awk.

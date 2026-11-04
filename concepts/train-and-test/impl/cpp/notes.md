We store each drive as a `Point` struct and the normal equations as a
vector of vectors, one vector per row. `solve` appends b to each row to
make the augmented matrix, then runs Gaussian elimination with partial
pivoting.

The pivot swap is a single `std::swap` of two row vectors, which trades
their internal buffers rather than copying entries. The training range
comes from one `std::minmax_element` pass. The C++ standard library has
no linear solver or polynomial fit, so we skip nothing beyond the
arithmetic in `<cmath>`.

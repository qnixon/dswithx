mawk, the awk in this image, has no arrays of arrays, so the augmented matrix is `m[i, j]`, a single
key that joins the two indices with `SUBSEP`. Column `size + 1` holds the
right-hand side. With no row objects to exchange, the pivot swap moves the
two rows cell by cell through a temporary.

The coefficients land in a global array, `coef`, and `rmse` takes the
train or test arrays as arguments, since awk passes arrays by reference.
This image's mawk raises a negative scaled speed to a whole power with `^`
correctly, so no power function is needed.

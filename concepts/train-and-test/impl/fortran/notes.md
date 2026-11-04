Fortran's whole-array operations carry most of the work. The design matrix
has a column of z to each power, and `matmul(transpose(zm), zm)` builds the
normal equations; multiplying matrices is a general tool, not the fit
itself. The Gaussian elimination is written out: `maxloc` finds the pivot
row, a temporary array swaps two rows, and one statement updates the rest
of a row at once.

Fortran's usual solver library, LAPACK, isn't part of the language
standard, and it isn't installed in this image. Coefficient arrays count
from 0, matching the powers.

Java has no matrix type, so the correlation matrix is a `double[][]`, an
array of row arrays. That makes `m[i]` a whole row, and `matVec` is one
call to `dot` per row. Power iteration, deflation, and the sign rule are
short loops around it.

Watch the copy. Writing `deflated = corr` copies only the reference, so
changing `deflated` would change `corr` too, and even `corr.clone()` shares
the rows. We build the deflated matrix as a new array instead. The JDK has
no eigenvalue routine to skip, and libraries such as Apache Commons Math
aren't installed.

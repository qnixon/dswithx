# Train and test error for polynomials of degree 1 to 8, in POSIX awk.
#
# Each polynomial is fitted by least squares to the training drives only:
# we build the normal equations and solve them by Gaussian elimination. Then
# we measure its root-mean-square error on the training drives and on the
# test drives it never saw. Rows are stored as they are read; the work
# happens in END.

BEGIN { FS = ","; MAX_DEGREE = 8 }

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == "speed") c_speed = i
        if ($i == "litres") c_litres = i
        if ($i == "split") c_split = i
    }
    if (!c_speed || !c_litres || !c_split) {
        print "missing a column (speed, litres, split)" > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Train and test drives go into separate arrays, numbered from 1.
$c_split == "train" { n_train++; train_x[n_train] = $c_speed; train_y[n_train] = $c_litres; next }
{ n_test++; test_x[n_test] = $c_speed; test_y[n_test] = $c_litres }

function scale(x) { return (x - mid) / half }

# Least squares: the coefficients solve (Z^T Z) c = Z^T y, where row i of Z
# is 1, z_i, z_i^2, ..., z_i^degree. awk has no 2D arrays, so m[i, j] is a
# single key "i SUBSEP j". Column size + 1 holds the right-hand side, making
# m the augmented matrix. The answer lands in the global array coef[1..size].
function fit(degree,    size, i, j, p, z) {
    size = degree + 1
    for (i = 1; i <= size; i++)
        for (j = 1; j <= size + 1; j++) m[i, j] = 0
    for (p = 1; p <= n_train; p++) {
        z = scale(train_x[p])
        for (i = 1; i <= size; i++) {
            m[i, size + 1] += train_y[p] * z ^ (i - 1)
            for (j = 1; j <= size; j++) m[i, j] += z ^ (i + j - 2)
        }
    }
    solve(size)
}

# Gaussian elimination with partial pivoting on the augmented matrix m.
function solve(n,    col, r, c, pivot, t, factor, total) {
    for (col = 1; col <= n; col++) {
        # Swap up the row with the largest entry in this column, which keeps
        # the rounding error small. With no row objects, swap cell by cell.
        pivot = col
        for (r = col + 1; r <= n; r++)
            if (abs(m[r, col]) > abs(m[pivot, col])) pivot = r
        for (c = 1; c <= n + 1; c++) {
            t = m[col, c]; m[col, c] = m[pivot, c]; m[pivot, c] = t
        }
        for (r = col + 1; r <= n; r++) {
            factor = m[r, col] / m[col, col]
            for (c = col; c <= n + 1; c++) m[r, c] -= factor * m[col, c]
        }
    }
    # Back substitution, from the last unknown up.
    for (r = n; r >= 1; r--) {
        total = m[r, n + 1]
        for (c = r + 1; c <= n; c++) total -= m[r, c] * coef[c]
        coef[r] = total / m[r, r]
    }
}

function abs(v) { return v < 0 ? -v : v }

# Arrays are passed by reference, so one function serves both sets.
function rmse(size, xs, ys, count,    p, i, z, predicted, total) {
    total = 0
    for (p = 1; p <= count; p++) {
        z = scale(xs[p])
        predicted = 0
        for (i = 1; i <= size; i++) predicted += coef[i] * z ^ (i - 1)
        total += (predicted - ys[p]) ^ 2
    }
    return sqrt(total / count)
}

END {
    if (failed) exit 1

    # Map the training speeds onto -1 to 1. Raw speeds to the 16th power
    # (the largest entry at degree 8) would swamp the small ones and make
    # the equations hard to solve accurately. The + 0 makes each a number.
    low = high = train_x[1] + 0
    for (p = 2; p <= n_train; p++) {
        if (train_x[p] < low) low = train_x[p] + 0
        if (train_x[p] > high) high = train_x[p] + 0
    }
    mid = (low + high) / 2
    half = (high - low) / 2

    printf "train_count %d\n", n_train
    printf "test_count %d\n", n_test
    for (d = 1; d <= MAX_DEGREE; d++) {
        fit(d)
        train_rmse[d] = rmse(d + 1, train_x, train_y, n_train)
        test_rmse[d] = rmse(d + 1, test_x, test_y, n_test)
    }
    for (d = 1; d <= MAX_DEGREE; d++) printf "train_rmse_d%d %.6f\n", d, train_rmse[d]
    for (d = 1; d <= MAX_DEGREE; d++) printf "test_rmse_d%d %.6f\n", d, test_rmse[d]
}

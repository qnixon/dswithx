# Simple linear regression by least squares, in POSIX awk.
#
# Fits score = intercept + slope * hours. The means are needed before the
# sums of deviations, so the values are stored in arrays and the work is
# done in END, after the whole file has been read.

BEGIN { FS = ","; xname = "hours"; yname = "score" }

# The header line: find which fields hold the two columns.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == xname) xcol = i
        if ($i == yname) ycol = i
    }
    if (!xcol || !ycol) {
        print "missing column " xname " or " yname > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Every other line: keep the pair and add it to the running totals.
{
    n++
    x[n] = $xcol + 0
    y[n] = $ycol + 0
    sum_x += x[n]
    sum_y += y[n]
}

END {
    if (failed) exit 1

    mean_x = sum_x / n
    mean_y = sum_y / n

    # Sums of squared deviations and of cross-products.
    for (i = 1; i <= n; i++) {
        dx = x[i] - mean_x
        dy = y[i] - mean_y
        sxx += dx * dx
        syy += dy * dy
        sxy += dx * dy
    }

    slope = sxy / sxx
    intercept = mean_y - slope * mean_x
    r = sxy / sqrt(sxx * syy)

    printf "count %d\n", n
    printf "slope %.6f\n", slope
    printf "intercept %.6f\n", intercept
    printf "r %.6f\n", r
    printf "r_squared %.6f\n", r * r
}

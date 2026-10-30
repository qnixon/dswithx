# Descriptive statistics on one CSV column, in POSIX awk.
#
# awk reads the file one line at a time, running each pattern { action } block
# on every line it matches. POSIX awk has no sort function, so values are kept
# in order as they arrive (insertion sort).

BEGIN { FS = ","; column = "minutes" }

# The header line: find which field holds the column.
NR == 1 {
    for (i = 1; i <= NF; i++)
        if ($i == column) col = i
    if (!col) {
        print "no column " column > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Every other line: insert the value into the sorted array v[1..n].
{
    x = $col + 0
    for (i = n; i > 0 && v[i] > x; i--)
        v[i + 1] = v[i]
    v[i + 1] = x
    n++
    total += x
}

END {
    if (failed) exit 1

    mean = total / n
    middle = int(n / 2)
    median = (n % 2 == 1) ? v[middle + 1] : (v[middle] + v[middle + 1]) / 2

    # Sample variance divides by n - 1, not n (Bessel's correction).
    for (i = 1; i <= n; i++)
        squares += (v[i] - mean) ^ 2
    variance = squares / (n - 1)

    printf "count %d\n", n
    printf "sum %.6f\n", total
    printf "mean %.6f\n", mean
    printf "median %.6f\n", median
    printf "min %.6f\n", v[1]
    printf "max %.6f\n", v[n]
    printf "range %.6f\n", v[n] - v[1]
    printf "variance %.6f\n", variance
    printf "std_dev %.6f\n", sqrt(variance)
}

# Principal component analysis by power iteration, in POSIX awk.
#
# Standardizes the four scores, builds their correlation matrix, and finds the
# top two eigenvectors (the principal components): power iteration finds the
# first, then deflation removes it from the matrix so the same steps find the
# second. Rows are stored as they are read; the analysis happens in END.

BEGIN { FS = ","; K = 4; STEPS = 1000; split("math physics reading writing", subject, " ") }

# The header line: find each subject's column by name.
NR == 1 {
    for (i = 1; i <= NF; i++)
        for (j = 1; j <= K; j++)
            if ($i == subject[j]) col[j] = i
    for (j = 1; j <= K; j++) {
        if (!col[j]) {
            print "missing a column (math, physics, reading, writing)" > "/dev/stderr"
            failed = 1
            exit 1
        }
    }
    next
}

# x[i, j] is subject j of row i; awk fakes 2-D arrays with a joined key.
{
    n++
    for (j = 1; j <= K; j++) x[n, j] = $col[j] + 0
}

# Power iteration on the K-by-K matrix m. Functions can't return arrays, so
# the eigenvector is written into v and the eigenvalue is returned. The extra
# parameters are awk's way of declaring local variables.
function top_eigenvector(m, v,    step, i, j, mv, len, value) {
    v[1] = 1
    for (i = 2; i <= K; i++) v[i] = 0
    for (step = 1; step <= STEPS; step++) {
        # v <- m v, then rescale to length 1.
        len = 0
        for (i = 1; i <= K; i++) {
            mv[i] = 0
            for (j = 1; j <= K; j++) mv[i] += m[i, j] * v[j]
            len += mv[i] ^ 2
        }
        len = sqrt(len)
        for (i = 1; i <= K; i++) v[i] = mv[i] / len
    }
    # An eigenvector can point either way; make its first entry positive.
    if (v[1] < 0)
        for (i = 1; i <= K; i++) v[i] = -v[i]
    # The eigenvalue is v . (m v).
    value = 0
    for (i = 1; i <= K; i++)
        for (j = 1; j <= K; j++) value += v[i] * m[i, j] * v[j]
    return value
}

END {
    if (failed) exit 1

    # Standardize each column to mean 0 and sample standard deviation 1
    # (divide by n - 1), in place.
    for (j = 1; j <= K; j++) {
        total = 0
        for (i = 1; i <= n; i++) total += x[i, j]
        mean = total / n
        ss = 0
        for (i = 1; i <= n; i++) ss += (x[i, j] - mean) ^ 2
        sd = sqrt(ss / (n - 1))
        for (i = 1; i <= n; i++) x[i, j] = (x[i, j] - mean) / sd
    }

    # The correlation matrix: the covariance of the standardized columns.
    for (a = 1; a <= K; a++) {
        for (b = 1; b <= K; b++) {
            total = 0
            for (i = 1; i <= n; i++) total += x[i, a] * x[i, b]
            corr[a, b] = total / (n - 1)
        }
    }

    value[1] = top_eigenvector(corr, pc1)
    # Deflation: subtract the first component's share, leaving the rest.
    for (a = 1; a <= K; a++)
        for (b = 1; b <= K; b++) deflated[a, b] = corr[a, b] - value[1] * pc1[a] * pc1[b]
    value[2] = top_eigenvector(deflated, pc2)

    printf "count %d\n", n
    for (c = 1; c <= 2; c++) {
        printf "eigenvalue_%d %.6f\n", c, value[c]
        # Standardized columns each have variance 1, so the total is K.
        printf "explained_%d %.6f\n", c, value[c] / K
        for (j = 1; j <= K; j++)
            printf "pc%d_%s %.6f\n", c, subject[j], (c == 1 ? pc1[j] : pc2[j])
    }
    # The first student's scores in the new coordinates.
    s1 = s2 = 0
    for (j = 1; j <= K; j++) { s1 += x[1, j] * pc1[j]; s2 += x[1, j] * pc2[j] }
    printf "student_1_pc1 %.6f\n", s1
    printf "student_1_pc2 %.6f\n", s2
}

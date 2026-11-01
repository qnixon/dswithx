# Logistic regression by gradient descent, in POSIX awk.
#
# Predicts whether a student passed from study hours and sleep. Each feature is
# rescaled with the training rows' mean and standard deviation, then the
# weights start at zero and take STEPS fixed steps of batch gradient descent
# on the average log-loss. Rows are stored as they are read; the fitting
# happens in END.

BEGIN { FS = ","; RATE = 0.5; STEPS = 1000 }

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == "hours") c_hours = i
        if ($i == "sleep") c_sleep = i
        if ($i == "passed") c_lab = i
        if ($i == "split") c_split = i
    }
    if (!c_hours || !c_sleep || !c_lab || !c_split) {
        print "missing a column (hours, sleep, passed, split)" > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Every other line goes into the training or the test arrays. x[i, j] is
# feature j of training row i; awk fakes 2-D arrays with a joined key.
$c_split == "train" {
    n++
    x[n, 1] = $c_hours + 0; x[n, 2] = $c_sleep + 0; y[n] = $c_lab + 0
    next
}
$c_split == "test" {
    m++
    q[m, 1] = $c_hours + 0; q[m, 2] = $c_sleep + 0; qy[m] = $c_lab + 0
}

function sigmoid(z) { return 1 / (1 + exp(-z)) }

# w . (1, x1, x2) for already-scaled inputs.
function score(x1, x2) { return w[0] + w[1] * x1 + w[2] * x2 }

END {
    if (failed) exit 1

    # Training means and sample standard deviations (divide by n - 1), then
    # scale the training rows in place. w[0] is the intercept, whose input
    # is always 1, so it needs no column.
    for (j = 1; j <= 2; j++) {
        total = 0
        for (i = 1; i <= n; i++) total += x[i, j]
        mean[j] = total / n
        ss = 0
        for (i = 1; i <= n; i++) ss += (x[i, j] - mean[j]) ^ 2
        sd[j] = sqrt(ss / (n - 1))
        for (i = 1; i <= n; i++) x[i, j] = (x[i, j] - mean[j]) / sd[j]
    }

    w[0] = w[1] = w[2] = 0
    for (step = 1; step <= STEPS; step++) {
        # Gradient of the average log-loss: the mean of (p - y) times each
        # input, all computed with the old weights before any update.
        g0 = g1 = g2 = 0
        for (i = 1; i <= n; i++) {
            e = sigmoid(score(x[i, 1], x[i, 2])) - y[i]
            g0 += e; g1 += e * x[i, 1]; g2 += e * x[i, 2]
        }
        w[0] -= RATE * g0 / n
        w[1] -= RATE * g1 / n
        w[2] -= RATE * g2 / n
    }

    loss = 0
    for (i = 1; i <= n; i++) {
        p = sigmoid(score(x[i, 1], x[i, 2]))
        loss -= y[i] * log(p) + (1 - y[i]) * log(1 - p)
    }

    # Test rows are scaled with the training means and sds.
    correct = 0
    for (i = 1; i <= m; i++) {
        p = sigmoid(score((q[i, 1] - mean[1]) / sd[1], (q[i, 2] - mean[2]) / sd[2]))
        if ((p >= 0.5 ? 1 : 0) == qy[i]) correct++
    }

    printf "train_count %d\n", n
    printf "test_count %d\n", m
    printf "intercept %.6f\n", w[0]
    printf "weight_hours %.6f\n", w[1]
    printf "weight_sleep %.6f\n", w[2]
    printf "log_loss %.6f\n", loss / n
    printf "correct %d\n", correct
    printf "accuracy %.6f\n", correct / m
}

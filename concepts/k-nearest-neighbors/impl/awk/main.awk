# k-nearest neighbors classification, in POSIX awk.
#
# Each test seed is labelled with the majority variety among its K nearest
# training seeds, by Euclidean distance. Rows are stored as they are read;
# the classifying happens in END.

BEGIN { FS = ","; K = 5 }

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == "length_mm") c_len = i
        if ($i == "width_mm") c_wid = i
        if ($i == "variety") c_lab = i
        if ($i == "split") c_split = i
    }
    if (!c_len || !c_wid || !c_lab || !c_split) {
        print "missing a column (length_mm, width_mm, variety, split)" > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Every other line goes into the training or the test arrays.
$c_split == "train" {
    n_train++
    tx[n_train] = $c_len + 0; ty[n_train] = $c_wid + 0; tlab[n_train] = $c_lab
    next
}
$c_split == "test" {
    n_test++
    qx[n_test] = $c_len + 0; qy[n_test] = $c_wid + 0; qlab[n_test] = $c_lab
}

# Label the point (px, py) by a vote of its K nearest training seeds.
# Locals are declared as extra parameters, the awk idiom for local variables.
function classify(px, py,    i, j, best, dist, used, votes, label, winner) {
    # Squared distance is enough for ranking, and skips the square root.
    for (i = 1; i <= n_train; i++)
        dist[i] = (tx[i] - px) ^ 2 + (ty[i] - py) ^ 2

    # Repeated selection: pick the nearest unused seed K times. The strict
    # "<" keeps the earlier training row on equal distances.
    winner = ""
    for (j = 1; j <= K; j++) {
        best = 0
        for (i = 1; i <= n_train; i++)
            if (!(i in used) && (best == 0 || dist[i] < dist[best]))
                best = i
        used[best] = 1
        label = tlab[best]
        votes[label]++
        # Highest vote wins; a tie stays with the label seen first (nearest).
        if (winner == "" || votes[label] > votes[winner])
            winner = label
    }
    return winner
}

END {
    if (failed) exit 1

    for (t = 1; t <= n_test; t++)
        if (classify(qx[t], qy[t]) == qlab[t]) correct++

    printf "train_count %d\n", n_train
    printf "test_count %d\n", n_test
    printf "correct %d\n", correct
    printf "accuracy %.6f\n", correct / n_test
}

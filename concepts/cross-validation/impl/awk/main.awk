# 5-fold cross-validation for k-nearest neighbors, in POSIX awk.
#
# Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
# holding out one fold at a time, picks the k with the best average
# accuracy, and then scores that k once on the untouched test seeds. Rows
# are stored as they are read; the work happens in END.

BEGIN { FS = ","; FOLDS = 5 }

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

# Label the point (px, py) by a vote of its k nearest training seeds,
# skipping rows lo to hi (the held-out fold; lo > hi skips nothing).
# Locals are declared as extra parameters, the awk idiom for local variables.
function classify(px, py, k, lo, hi,    i, j, best, dist, used, votes, label, winner) {
    # Squared distance is enough for ranking, and skips the square root.
    for (i = 1; i <= n_train; i++)
        dist[i] = (tx[i] - px) ^ 2 + (ty[i] - py) ^ 2

    # Repeated selection: pick the nearest unused seed k times. The strict
    # "<" keeps the earlier training row on equal distances.
    winner = ""
    for (j = 1; j <= k; j++) {
        best = 0
        for (i = 1; i <= n_train; i++)
            if ((i < lo || i > hi) && !(i in used) && (best == 0 || dist[i] < dist[best]))
                best = i
        used[best] = 1
        label = tlab[best]
        votes[label]++
        # Highest vote wins; with two varieties and odd k, no vote ties.
        if (winner == "" || votes[label] > votes[winner])
            winner = label
    }
    return winner
}

# Fold f (from 0) is rows f*size+1 to (f+1)*size. The rows are already
# shuffled, so consecutive blocks make fair folds. Nothing is copied: the
# held-out rows are classified against all others, skipped by index.
function cv_accuracy(k,    size, f, lo, hi, i, correct) {
    size = int(n_train / FOLDS)
    correct = 0
    for (f = 0; f < FOLDS; f++) {
        lo = f * size + 1
        hi = (f + 1) * size
        for (i = lo; i <= hi; i++)
            if (classify(tx[i], ty[i], k, lo, hi) == tlab[i]) correct++
    }
    return correct / n_train
}

END {
    if (failed) exit 1

    printf "train_count %d\n", n_train
    printf "test_count %d\n", n_test
    best_k = 0; best_accuracy = -1
    for (k = 1; k <= 15; k += 2) {   # odd k only
        accuracy = cv_accuracy(k)
        printf "cv_accuracy_k%d %.6f\n", k, accuracy
        # Strictly better, so ties keep the smaller k.
        if (accuracy > best_accuracy) { best_k = k; best_accuracy = accuracy }
    }

    # Only now touch the test seeds, once, with the chosen k and all of train.
    for (t = 1; t <= n_test; t++)
        if (classify(qx[t], qy[t], best_k, 1, 0) == qlab[t]) correct++

    printf "best_k %d\n", best_k
    printf "test_correct %d\n", correct
    printf "test_accuracy %.6f\n", correct / n_test
}

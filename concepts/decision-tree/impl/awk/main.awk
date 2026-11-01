# A decision tree classifier (CART with Gini impurity), in POSIX awk.
#
# Grows a tree on the training days by always making the split that leaves the
# two sides purest, then predicts rain for the test days. Nodes are numbered in
# preorder as they are grown, so the tree prints in that order.

BEGIN {
    FS = ","
    nf = split("humidity,pressure,wind", feature, ",")
    MAX_DEPTH = 3; MIN_SIZE = 5
}

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        for (f = 1; f <= nf; f++)
            if ($i == feature[f]) fcol[f] = i
        if ($i == "rain") c_lab = i
        if ($i == "split") c_split = i
    }
    for (f = 1; f <= nf; f++)
        if (!fcol[f]) missing = missing " " feature[f]
    if (!c_lab) missing = missing " rain"
    if (!c_split) missing = missing " split"
    if (missing != "") {
        print "missing column(s):" missing > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Every other line goes into the training or the test arrays. x[i, f] is
# feature f of training day i; awk fakes 2-D arrays with a joined key.
$c_split == "train" {
    n++
    for (f = 1; f <= nf; f++) x[n, f] = $fcol[f] + 0
    y[n] = $c_lab
    next
}
$c_split == "test" {
    m++
    for (f = 1; f <= nf; f++) q[m, f] = $fcol[f] + 0
    qy[m] = $c_lab
}

# Chance that two days drawn at random (with replacement) disagree.
function gini(yes, total,    p) {
    p = yes / total
    return 1 - p * p - (1 - p) * (1 - p)
}

# Grow the node holding the training days listed in days[1..count], and return
# its number. awk has no records, so node k lives in parallel arrays: split_f,
# split_t, left, and right for a split, and predict for a leaf. Locals are
# declared as extra parameters, so each recursive call gets its own.
function grow(days, count, depth,
              k, i, j, s, f, v, nv, a, t, nl, yl, yes, score, node_gini,
              best, best_f, best_t, ldays, rdays, nr) {
    k = ++nodes
    yes = 0
    for (i = 1; i <= count; i++) if (y[days[i]] == "yes") yes++
    # An even split predicts "no".
    predict[k] = (yes > count / 2) ? "yes" : "no"
    node_gini = gini(yes, count)
    if (node_gini == 0 || count < MIN_SIZE || depth == MAX_DEPTH) return k

    # Features in column order, thresholds from smallest to largest; only a
    # strictly lower score replaces the best, so the first of a tie wins.
    best = ""
    for (f = 1; f <= nf; f++) {
        # The distinct values, kept sorted by insertion (POSIX awk has no sort).
        nv = 0
        for (i = 1; i <= count; i++) {
            a = x[days[i], f]
            for (j = nv; j > 0 && v[j] > a; j--) ;  # find a's place
            if (j > 0 && v[j] == a) continue         # already listed
            for (s = nv; s > j; s--) v[s + 1] = v[s]
            v[j + 1] = a; nv++
        }
        for (j = 1; j < nv; j++) {
            t = (v[j] + v[j + 1]) / 2
            nl = yl = 0
            for (i = 1; i <= count; i++)
                if (x[days[i], f] <= t) { nl++; if (y[days[i]] == "yes") yl++ }
            score = (nl * gini(yl, nl) + (count - nl) * gini(yes - yl, count - nl)) / count
            if (best == "" || score < best) { best = score; best_f = f; best_t = t }
        }
    }
    if (best == "" || best >= node_gini) return k  # no split makes the sides purer

    nl = nr = 0
    for (i = 1; i <= count; i++)
        if (x[days[i], best_f] <= best_t) ldays[++nl] = days[i]
        else rdays[++nr] = days[i]
    split_f[k] = best_f; split_t[k] = best_t
    left[k] = grow(ldays, nl, depth + 1)
    right[k] = grow(rdays, nr, depth + 1)
    return k
}

# Walk from the root to a leaf; z[f] holds the day's features.
function classify(z,    k) {
    k = 1
    while (k in split_f) k = (z[split_f[k]] <= split_t[k]) ? left[k] : right[k]
    return predict[k]
}

END {
    if (failed) exit 1

    for (i = 1; i <= n; i++) all[i] = i
    grow(all, n, 0)

    printf "train_count %d\n", n
    printf "test_count %d\n", m
    for (k = 1; k <= nodes; k++) {
        if (k in split_f) {
            printf "node_%d_feature %s\n", k, feature[split_f[k]]
            printf "node_%d_threshold %.6f\n", k, split_t[k]
        } else {
            printf "node_%d_predict %s\n", k, predict[k]
            leaves++
        }
    }
    printf "leaves %d\n", leaves

    for (i = 1; i <= n; i++) {
        for (f = 1; f <= nf; f++) z[f] = x[i, f]
        if (classify(z) == y[i]) train_correct++
    }
    for (i = 1; i <= m; i++) {
        for (f = 1; f <= nf; f++) z[f] = q[i, f]
        if (classify(z) == qy[i]) correct++
    }
    printf "train_accuracy %.6f\n", train_correct / n
    printf "correct %d\n", correct
    printf "accuracy %.6f\n", correct / m
}

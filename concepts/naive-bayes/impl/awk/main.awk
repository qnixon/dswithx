# Categorical naive Bayes with add-one (Laplace) smoothing, in POSIX awk.
#
# Learns P(label) and P(feature value | label) by counting training rows, then
# labels each test row with the label that has the highest log-probability.
# awk's associative arrays do the counting; keys like "has_link,yes,spam" are
# built by joining strings, since POSIX awk has no nested arrays.

BEGIN {
    FS = ","
    nf = split("has_link,mentions_money,known_sender", feature, ",")
    label_name = "label"
}

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        for (f = 1; f <= nf; f++)
            if ($i == feature[f]) fcol[f] = i
        if ($i == label_name) c_lab = i
        if ($i == "split") c_split = i
    }
    for (f = 1; f <= nf; f++)
        if (!fcol[f]) missing = missing " " feature[f]
    if (!c_lab) missing = missing " " label_name
    if (!c_split) missing = missing " split"
    if (missing != "") {
        print "missing column(s):" missing > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# A training row: count its label and each (feature, value, label) triple.
$c_split == "train" {
    n_train++
    label = $c_lab
    if (!(label in label_count)) add_label(label)
    label_count[label]++
    for (f = 1; f <= nf; f++) {
        value = $fcol[f]
        value_count[f "," value "," label]++
        # Count the distinct values of each feature (m_j in the formula).
        if (!((f "," value) in seen)) { seen[f "," value] = 1; distinct[f]++ }
    }
    next
}

# A test row: keep it for END, after training has seen every row.
$c_split == "test" {
    n_test++
    test_label[n_test] = $c_lab
    for (f = 1; f <= nf; f++)
        test_value[n_test "," f] = $fcol[f]
}

# Insert a new label into labels[1..n_labels], kept in alphabetical order
# (POSIX awk has no sort, and the order decides ties).
function add_label(name,    i) {
    for (i = n_labels; i > 0 && labels[i] > name; i--)
        labels[i + 1] = labels[i]
    labels[i + 1] = name
    n_labels++
}

# log P(label) + sum over features of log P(value | label), add-one smoothed.
# Logs turn the product of probabilities into a sum, avoiding underflow.
function log_score(t, label,    f, score) {
    score = log(label_count[label] / n_train)
    for (f = 1; f <= nf; f++)
        score += log((value_count[f "," test_value[t "," f] "," label] + 1) / \
                     (label_count[label] + distinct[f]))
    return score
}

END {
    if (failed) exit 1

    for (t = 1; t <= n_test; t++) {
        # Labels are tried alphabetically and only a strictly higher score
        # replaces the best, so an exact tie goes to the first label.
        best = labels[1]
        best_score = log_score(t, best)
        for (i = 2; i <= n_labels; i++) {
            s = log_score(t, labels[i])
            if (s > best_score) { best = labels[i]; best_score = s }
        }
        if (best == test_label[t]) correct++
    }

    printf "train_count %d\n", n_train
    printf "test_count %d\n", n_test
    printf "correct %d\n", correct
    printf "accuracy %.6f\n", correct / n_test
}

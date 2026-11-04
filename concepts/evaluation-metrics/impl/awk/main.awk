# Evaluation metrics for a binary classifier, in POSIX awk.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.
# Rows are stored as they are read; the work happens in END.

BEGIN { FS = "," }

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == "defective") c_label = i
        if ($i == "score") c_score = i
    }
    if (!c_label || !c_score) {
        print "missing a column (defective, score)" > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Scores have three decimals, so we keep them as whole thousandths: 0.174
# becomes 174. Whole numbers compare exactly, so tied scores stay tied.
{
    n++
    label[n] = ($c_label == 1)
    score[n] = int($c_score * 1000 + 0.5)
    if (label[n]) n_defective++
}

# Thresholds are in thousandths too: 500 is 0.5. awk passes scalars by value,
# and the counts after the real parameters are locals.
function report(suffix, threshold,    i, flagged, tp, fp, fn, tn,
                accuracy, precision, recall, f1) {
    # A part is flagged when its score reaches the threshold.
    tp = fp = fn = tn = 0
    for (i = 1; i <= n; i++) {
        flagged = (score[i] >= threshold)
        if (flagged && label[i]) tp++
        else if (flagged) fp++
        else if (label[i]) fn++
        else tn++
    }

    accuracy = (tp + tn) / n
    precision = tp / (tp + fp)   # of the flagged parts, how many are defective
    recall = tp / (tp + fn)      # of the defective parts, how many are flagged
    f1 = 2 * precision * recall / (precision + recall)

    printf "tp_at_%s %d\n", suffix, tp
    printf "fp_at_%s %d\n", suffix, fp
    printf "fn_at_%s %d\n", suffix, fn
    printf "tn_at_%s %d\n", suffix, tn
    printf "accuracy_at_%s %.6f\n", suffix, accuracy
    printf "precision_at_%s %.6f\n", suffix, precision
    printf "recall_at_%s %.6f\n", suffix, recall
    printf "f1_at_%s %.6f\n", suffix, f1
}

# The chance that a random defective part outscores a random good one.
# Compare every pair, scoring 2 for a win and 1 for a tie, so the count
# stays a whole number until the final division.
function auc(    i, j, points) {
    points = 0
    for (i = 1; i <= n; i++) {
        if (!label[i]) continue
        for (j = 1; j <= n; j++) {
            if (label[j]) continue
            if (score[i] > score[j]) points += 2
            else if (score[i] == score[j]) points += 1
        }
    }
    return points / (2 * n_defective * (n - n_defective))
}

END {
    if (failed) exit 1
    printf "parts %d\n", n
    printf "defective %d\n", n_defective
    # Never flagging anything is right about every good part.
    printf "baseline_accuracy %.6f\n", (n - n_defective) / n
    report("50", 500)
    report("30", 300)
    printf "auc %.6f\n", auc()
}

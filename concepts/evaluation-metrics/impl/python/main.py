"""Evaluation metrics for a binary classifier, using only the standard
library.

Reads each part's true label and the model's score, then reports the
confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
the accuracy of never flagging anything, and the area under the ROC curve.
"""

import csv
import sys

THRESHOLDS = (("50", 0.5), ("30", 0.3))  # name suffix, threshold


def read(path):
    with open(path, newline="") as f:
        return [(row["defective"] == "1", float(row["score"]))
                for row in csv.DictReader(f)]


def report(parts, suffix, threshold):
    # A part is flagged when its score reaches the threshold.
    tp = fp = fn = tn = 0
    for defective, score in parts:
        flagged = score >= threshold
        if flagged and defective:
            tp += 1
        elif flagged:
            fp += 1
        elif defective:
            fn += 1
        else:
            tn += 1

    accuracy = (tp + tn) / len(parts)
    precision = tp / (tp + fp)  # of the flagged parts, how many are defective
    recall = tp / (tp + fn)     # of the defective parts, how many are flagged
    f1 = 2 * precision * recall / (precision + recall)

    print(f"tp_at_{suffix} {tp}")
    print(f"fp_at_{suffix} {fp}")
    print(f"fn_at_{suffix} {fn}")
    print(f"tn_at_{suffix} {tn}")
    print(f"accuracy_at_{suffix} {accuracy:.6f}")
    print(f"precision_at_{suffix} {precision:.6f}")
    print(f"recall_at_{suffix} {recall:.6f}")
    print(f"f1_at_{suffix} {f1:.6f}")


def auc(parts):
    # The chance that a random defective part outscores a random good one.
    # Compare every pair, scoring 2 for a win and 1 for a tie, so the count
    # stays a whole number until the final division.
    defective = [score for is_defective, score in parts if is_defective]
    good = [score for is_defective, score in parts if not is_defective]
    points = 0
    for d in defective:
        for g in good:
            if d > g:
                points += 2
            elif d == g:
                points += 1
    return points / (2 * len(defective) * len(good))


def main():
    parts = read(sys.argv[1])
    defective = sum(is_defective for is_defective, _ in parts)

    print(f"parts {len(parts)}")
    print(f"defective {defective}")
    # Never flagging anything is right about every good part.
    print(f"baseline_accuracy {(len(parts) - defective) / len(parts):.6f}")
    for suffix, threshold in THRESHOLDS:
        report(parts, suffix, threshold)
    print(f"auc {auc(parts):.6f}")


if __name__ == "__main__":
    main()

"""Categorical naive Bayes with add-one (Laplace) smoothing, standard library only.

Learns P(label) and P(feature value | label) by counting training rows, then
labels each test row with the label that has the highest log-probability.
"""

import csv
import math
import sys
from collections import Counter

FEATURES = ("has_link", "mentions_money", "known_sender")
LABEL = "label"


def main():
    with open(sys.argv[1], newline="") as f:
        rows = list(csv.DictReader(f))
    train = [row for row in rows if row["split"] == "train"]
    test = [row for row in rows if row["split"] == "test"]

    label_counts = Counter(row[LABEL] for row in train)
    # value_counts[(feature, value, label)] = number of training rows
    value_counts = Counter((f, row[f], row[LABEL]) for row in train for f in FEATURES)
    distinct_values = {f: len({row[f] for row in train}) for f in FEATURES}

    def log_score(row, label):
        # Logs turn the product of probabilities into a sum, avoiding underflow.
        score = math.log(label_counts[label] / len(train))
        for f in FEATURES:
            # Add-one smoothing: an unseen value never gets probability zero.
            count = value_counts[(f, row[f], label)] + 1
            score += math.log(count / (label_counts[label] + distinct_values[f]))
        return score

    def classify(row):
        # Labels are tried in alphabetical order, so an exact tie goes to the first.
        return max(sorted(label_counts), key=lambda label: log_score(row, label))

    correct = sum(classify(row) == row[LABEL] for row in test)

    print(f"train_count {len(train)}")
    print(f"test_count {len(test)}")
    print(f"correct {correct}")
    print(f"accuracy {correct / len(test):.6f}")


if __name__ == "__main__":
    main()

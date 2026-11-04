"""5-fold cross-validation for k-nearest neighbors, using only the standard
library.

Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
holding out one fold at a time, picks the k with the best average accuracy,
and then scores that k once on the untouched test seeds.
"""

import csv
import math
import sys
from collections import Counter

FOLDS = 5
KS = range(1, 16, 2)  # odd k only, so two varieties can't tie
FEATURES = ("length_mm", "width_mm")
LABEL = "variety"


def read(path):
    train, test = [], []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            point = (tuple(float(row[name]) for name in FEATURES), row[LABEL])
            (train if row["split"] == "train" else test).append(point)
    return train, test


def classify(point, train, k):
    # Sort training seeds by distance (a stable sort, so equal distances keep
    # file order) and let the k nearest vote.
    nearest = sorted(train, key=lambda seed: math.dist(point, seed[0]))[:k]
    votes = Counter(label for _, label in nearest)
    return votes.most_common(1)[0][0]


def count_correct(points, train, k):
    return sum(classify(point, train, k) == label for point, label in points)


def cv_accuracy(train, k):
    # Fold f is rows f*size up to (f+1)*size. The rows are already shuffled,
    # so consecutive blocks make fair folds.
    size = len(train) // FOLDS
    correct = 0
    for f in range(FOLDS):
        held_out = train[f * size:(f + 1) * size]
        rest = train[:f * size] + train[(f + 1) * size:]
        correct += count_correct(held_out, rest, k)
    return correct / len(train)


def main():
    train, test = read(sys.argv[1])

    print(f"train_count {len(train)}")
    print(f"test_count {len(test)}")
    best_k, best_accuracy = None, -1.0
    for k in KS:
        accuracy = cv_accuracy(train, k)
        print(f"cv_accuracy_k{k} {accuracy:.6f}")
        if accuracy > best_accuracy:  # strictly better, so ties keep the smaller k
            best_k, best_accuracy = k, accuracy

    # Only now touch the test seeds, once, with the chosen k and all of train.
    correct = count_correct(test, train, best_k)
    print(f"best_k {best_k}")
    print(f"test_correct {correct}")
    print(f"test_accuracy {correct / len(test):.6f}")


if __name__ == "__main__":
    main()

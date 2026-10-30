"""k-nearest neighbors classification, using only the standard library.

Each test seed is labelled with the majority variety among its K nearest
training seeds, by Euclidean distance.
"""

import csv
import math
import sys
from collections import Counter

K = 5
FEATURES = ("length_mm", "width_mm")
LABEL = "variety"


def read(path):
    train, test = [], []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            point = (tuple(float(row[name]) for name in FEATURES), row[LABEL])
            (train if row["split"] == "train" else test).append(point)
    return train, test


def classify(point, train):
    # Sort training seeds by distance (a stable sort, so equal distances keep
    # file order) and let the K nearest vote.
    nearest = sorted(train, key=lambda seed: math.dist(point, seed[0]))[:K]
    votes = Counter(label for _, label in nearest)
    return votes.most_common(1)[0][0]


def main():
    train, test = read(sys.argv[1])
    correct = sum(classify(point, train) == label for point, label in test)

    print(f"train_count {len(train)}")
    print(f"test_count {len(test)}")
    print(f"correct {correct}")
    print(f"accuracy {correct / len(test):.6f}")


if __name__ == "__main__":
    main()

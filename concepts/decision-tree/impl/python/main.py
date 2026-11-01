"""A decision tree classifier (CART with Gini impurity), standard library only.

Grows a tree on the training days by always making the split that leaves the
two sides purest, then predicts rain for the test days. Prints the tree in
preorder: each node is either a split (feature and threshold) or a leaf
(its prediction).
"""

import csv
import sys

FEATURES = ("humidity", "pressure", "wind")
MAX_DEPTH = 3
MIN_SIZE = 5


def read(path):
    train, test = [], []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            day = ([float(row[name]) for name in FEATURES], row["rain"])
            (train if row["split"] == "train" else test).append(day)
    return train, test


def gini(labels):
    # Chance that two days drawn at random (with replacement) disagree.
    p = labels.count("yes") / len(labels)
    return 1 - p * p - (1 - p) * (1 - p)


def majority(labels):
    # An even split predicts "no".
    return "yes" if labels.count("yes") > len(labels) / 2 else "no"


def best_split(days):
    """The (score, feature, threshold) with the lowest weighted Gini impurity.
    Features are tried in column order and thresholds from smallest to largest;
    only a strictly lower score replaces the best so far."""
    best = None
    for f in range(len(FEATURES)):
        values = sorted({x[f] for x, _ in days})
        for a, b in zip(values, values[1:]):
            threshold = (a + b) / 2
            left = [label for x, label in days if x[f] <= threshold]
            right = [label for x, label in days if x[f] > threshold]
            score = (len(left) * gini(left) + len(right) * gini(right)) / len(days)
            if best is None or score < best[0]:
                best = (score, f, threshold)
    return best


def grow(days, depth=0):
    """A leaf is a label; a split is (feature, threshold, left, right)."""
    labels = [label for _, label in days]
    if gini(labels) == 0 or len(days) < MIN_SIZE or depth == MAX_DEPTH:
        return majority(labels)
    split = best_split(days)
    if split is None or split[0] >= gini(labels):
        return majority(labels)  # no split makes the sides purer
    _, f, threshold = split
    left = [d for d in days if d[0][f] <= threshold]
    right = [d for d in days if d[0][f] > threshold]
    return (f, threshold, grow(left, depth + 1), grow(right, depth + 1))


def predict(node, x):
    while isinstance(node, tuple):
        f, threshold, left, right = node
        node = left if x[f] <= threshold else right
    return node


def preorder(node):
    yield node
    if isinstance(node, tuple):
        yield from preorder(node[2])
        yield from preorder(node[3])


def main():
    train, test = read(sys.argv[1])
    tree = grow(train)

    print(f"train_count {len(train)}")
    print(f"test_count {len(test)}")
    leaves = 0
    for k, node in enumerate(preorder(tree), start=1):
        if isinstance(node, tuple):
            print(f"node_{k}_feature {FEATURES[node[0]]}")
            print(f"node_{k}_threshold {node[1]:.6f}")
        else:
            print(f"node_{k}_predict {node}")
            leaves += 1
    print(f"leaves {leaves}")

    train_correct = sum(predict(tree, x) == label for x, label in train)
    correct = sum(predict(tree, x) == label for x, label in test)
    print(f"train_accuracy {train_correct / len(train):.6f}")
    print(f"correct {correct}")
    print(f"accuracy {correct / len(test):.6f}")


if __name__ == "__main__":
    main()

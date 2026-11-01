"""Logistic regression by gradient descent, using only the standard library.

Predicts whether a student passed from study hours and sleep. Each feature is
rescaled with the training rows' mean and standard deviation, then the weights
start at zero and take STEPS fixed steps of batch gradient descent on the
average log-loss.
"""

import csv
import math
import sys

FEATURES = ("hours", "sleep")
LABEL = "passed"
LEARNING_RATE = 0.5
STEPS = 1000


def read(path):
    train, test = [], []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            example = ([float(row[name]) for name in FEATURES], int(row[LABEL]))
            (train if row["split"] == "train" else test).append(example)
    return train, test


def sigmoid(z):
    return 1 / (1 + math.exp(-z))


def main():
    train, test = read(sys.argv[1])

    # Scale each feature to mean 0 and (sample) standard deviation 1, using
    # the training rows only. The leading 1 multiplies the intercept.
    columns = list(zip(*(x for x, _ in train)))
    means = [sum(c) / len(c) for c in columns]
    sds = [math.sqrt(sum((v - m) ** 2 for v in c) / (len(c) - 1)) for c, m in zip(columns, means)]

    def scale(x):
        return [1.0] + [(v - m) / s for v, m, s in zip(x, means, sds)]

    xs = [scale(x) for x, _ in train]
    ys = [y for _, y in train]
    n = len(xs)

    weights = [0.0] * len(xs[0])
    for _ in range(STEPS):
        # Gradient of the average log-loss: the mean of (p - y) times each input.
        errors = [sigmoid(sum(w * v for w, v in zip(weights, x))) - y for x, y in zip(xs, ys)]
        gradient = [sum(e * x[j] for e, x in zip(errors, xs)) / n for j in range(len(weights))]
        weights = [w - LEARNING_RATE * g for w, g in zip(weights, gradient)]

    probabilities = [sigmoid(sum(w * v for w, v in zip(weights, x))) for x in xs]
    log_loss = -sum(y * math.log(p) + (1 - y) * math.log(1 - p) for p, y in zip(probabilities, ys)) / n

    def predict(x):
        return 1 if sigmoid(sum(w * v for w, v in zip(weights, scale(x)))) >= 0.5 else 0

    correct = sum(predict(x) == y for x, y in test)

    print(f"train_count {n}")
    print(f"test_count {len(test)}")
    print(f"intercept {weights[0]:.6f}")
    print(f"weight_hours {weights[1]:.6f}")
    print(f"weight_sleep {weights[2]:.6f}")
    print(f"log_loss {log_loss:.6f}")
    print(f"correct {correct}")
    print(f"accuracy {correct / len(test):.6f}")


if __name__ == "__main__":
    main()

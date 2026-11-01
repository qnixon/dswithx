"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 200 students' weekly study hours and nightly hours of
sleep, and whether they passed the exam (1) or not (0). Each student passes
with probability 1 / (1 + e^-z), where z = -6 + 0.6 × hours + 0.5 × sleep,
so both study and sleep help. Rows are shuffled; the first 150 are marked
train and the last 50 test.

The generator fits the model the way the implementations do and rejects any
draw where a test student's score lands near the 0.5 cutoff, so tiny
floating-point differences between languages can never flip a prediction.

    python3 make_data.py > data.csv
"""

import math
import random
import statistics

SEED = 20261101
TRUE_INTERCEPT, TRUE_HOURS, TRUE_SLEEP = -6.0, 0.6, 0.5
LEARNING_RATE = 0.5
STEPS = 1000
MARGIN = 1e-3  # smallest allowed |z| for a test student


def draw(rng):
    rows = []
    for _ in range(200):
        hours = round(rng.uniform(0.5, 10), 1)
        sleep = round(rng.uniform(4, 9), 1)
        z = TRUE_INTERCEPT + TRUE_HOURS * hours + TRUE_SLEEP * sleep
        passed = 1 if rng.random() < 1 / (1 + math.exp(-z)) else 0
        rows.append((hours, sleep, passed))
    rng.shuffle(rows)
    return rows[:150], rows[150:]


def fit_scores(train, test):
    """Test students' z after the same scaling and gradient descent as main.py."""
    columns = list(zip(*train))[:2]
    means = [statistics.fmean(c) for c in columns]
    sds = [statistics.stdev(c) for c in columns]
    scale = lambda row: [1.0] + [(row[j] - means[j]) / sds[j] for j in range(2)]
    xs, ys = [scale(r) for r in train], [r[2] for r in train]
    w = [0.0, 0.0, 0.0]
    for _ in range(STEPS):
        errors = [1 / (1 + math.exp(-sum(a * b for a, b in zip(w, x)))) - y for x, y in zip(xs, ys)]
        w = [w[j] - LEARNING_RATE * sum(e * x[j] for e, x in zip(errors, xs)) / len(xs) for j in range(3)]
    return [sum(a * b for a, b in zip(w, scale(r))) for r in test]


def near_cutoff(train, test):
    return any(abs(z) < MARGIN for z in fit_scores(train, test))


rng = random.Random(SEED)
train, test = draw(rng)
while near_cutoff(train, test):
    train, test = draw(rng)

print("hours,sleep,passed,split")
for split, rows in (("train", train), ("test", test)):
    for hours, sleep, passed in rows:
        print(f"{hours:.1f},{sleep:.1f},{passed},{split}")

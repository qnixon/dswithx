"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 200 days of humidity (%), air pressure (hPa), and wind
speed (km/h), and whether it rained the next day. The true rule is "rain when
humidity is at least 75 and pressure is below 1012, or when pressure is below
1000"; wind plays no part. Then 10% of the labels are flipped at random, so no
rule is perfect. Rows are shuffled; the first 150 are marked train and the
last 50 test.

The generator grows the tree the way the implementations do, but scores
splits with exact fractions. It rejects any draw where the best split at a
node is tied with, or within MARGIN of, a split that divides the days
differently, so tiny floating-point differences between languages can never
change the tree.

    python3 make_data.py > data.csv
"""

import random
from fractions import Fraction

SEED = 20261102
FEATURES = ("humidity", "pressure", "wind")
MAX_DEPTH = 3
MIN_SIZE = 5
NOISE = 0.10
MARGIN = Fraction(1, 10**9)


def draw(rng):
    rows = []
    for _ in range(200):
        humidity = rng.randint(30, 100)
        pressure = round(rng.uniform(990, 1030), 1)
        wind = rng.randint(0, 40)
        rain = (humidity >= 75 and pressure < 1012) or pressure < 1000
        if rng.random() < NOISE:
            rain = not rain
        rows.append((humidity, pressure, wind, "yes" if rain else "no"))
    rng.shuffle(rows)
    return rows[:150], rows[150:]


def gini(labels):
    n = len(labels)
    p = Fraction(labels.count("yes"), n)
    return 1 - p * p - (1 - p) * (1 - p)


def candidates(rows):
    """Every split as (score, feature, threshold, left counts, right counts)."""
    for f in range(3):
        values = sorted({r[f] for r in rows})
        for a, b in zip(values, values[1:]):
            t = Fraction(str(a)) / 2 + Fraction(str(b)) / 2
            left = [r[3] for r in rows if r[f] <= t]
            right = [r[3] for r in rows if r[f] > t]
            score = (len(left) * gini(left) + len(right) * gini(right)) / len(rows)
            counts = (left.count("yes"), len(left), right.count("yes"), len(right))
            yield score, f, t, counts


def grow(rows, depth, bad):
    """Grow the tree; set bad[0] if any choice is too close to call. A leaf
    predicts rain only when most of its days had rain; an even split is no."""
    labels = [r[3] for r in rows]
    parent = gini(labels)
    if parent == 0 or len(rows) < MIN_SIZE or depth == MAX_DEPTH:
        return labels.count("yes") * 2 > len(labels)
    splits = list(candidates(rows))
    best = min(splits, key=lambda s: s[0])  # min keeps the first of ties
    for s in splits:
        if s[3] != best[3] and abs(s[0] - best[0]) < MARGIN:
            bad[0] = True
    if abs(best[0] - parent) < MARGIN and best[0] != parent:
        bad[0] = True
    if best[0] >= parent:
        return labels.count("yes") * 2 > len(labels)
    _, f, t, _ = best
    return (f, t,
            grow([r for r in rows if r[f] <= t], depth + 1, bad),
            grow([r for r in rows if r[f] > t], depth + 1, bad))


def unsafe(train):
    bad = [False]
    grow(train, 0, bad)
    return bad[0]


rng = random.Random(SEED)
train, test = draw(rng)
while unsafe(train):
    train, test = draw(rng)

print(",".join(FEATURES) + ",rain,split")
for split, rows in (("train", train), ("test", test)):
    for humidity, pressure, wind, rain in rows:
        print(f"{humidity},{pressure:.1f},{wind},{rain},{split}")

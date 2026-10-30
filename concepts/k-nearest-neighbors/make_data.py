"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 200 seeds of two wheat varieties, kama and rosa, with
kernel length and width in millimetres. The varieties overlap a little, so
some test seeds are genuinely hard to classify. Rows are shuffled; the first
150 are marked train and the last 50 test.

The generator rejects any draw where a test seed's 5th and 6th nearest
training seeds are (almost) the same distance away, so tie-breaking never
decides a result and every language agrees.

    python3 make_data.py > data.csv
"""

import math
import random

SEED = 20261031
K = 5
VARIETIES = {"kama": ((5.5, 0.25), (3.2, 0.15)), "rosa": ((6.2, 0.30), (3.6, 0.18))}


def draw(rng):
    rows = [
        (round(rng.gauss(*length), 2), round(rng.gauss(*width), 2), variety)
        for variety, (length, width) in VARIETIES.items()
        for _ in range(100)
    ]
    rng.shuffle(rows)
    return rows[:150], rows[150:]


def has_near_tie(train, test):
    for x, y, _ in test:
        distances = sorted(math.dist((x, y), (tx, ty)) for tx, ty, _ in train)
        if distances[K] - distances[K - 1] < 1e-6:
            return True
    return False


rng = random.Random(SEED)
train, test = draw(rng)
while has_near_tie(train, test):
    train, test = draw(rng)

print("length_mm,width_mm,variety,split")
for split, rows in (("train", train), ("test", test)):
    for length, width, variety in rows:
        print(f"{length:.2f},{width:.2f},{variety},{split}")

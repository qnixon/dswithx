"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 150 points in three round blobs of 50. The first three
rows come from different blobs, because k-means here starts from the first
three rows as its centroids; the rest are shuffled.

The generator rejects any draw where, during k-means, a point is (almost)
equally close to two centroids, so tie-breaking never decides a result and
every language agrees.

    python3 make_data.py > data.csv
"""

import math
import random

SEED = 20261101
K = 3
CENTERS = [(2.0, 2.0), (6.0, 3.0), (3.5, 6.0)]


def draw(rng):
    blobs = [[(round(rng.gauss(cx, 1.3), 2), round(rng.gauss(cy, 1.3), 2)) for _ in range(50)]
             for cx, cy in CENTERS]
    first = [blob.pop() for blob in blobs]
    rest = [p for blob in blobs for p in blob]
    rng.shuffle(rest)
    return first + rest


def has_near_tie(points):
    centroids = points[:K]
    assignment = None
    for _ in range(100):
        new = []
        for p in points:
            d = sorted(math.dist(p, c) for c in centroids)
            if d[1] - d[0] < 1e-6:
                return True
            new.append(min(range(K), key=lambda j: math.dist(p, centroids[j])))
        if new == assignment:
            return False
        assignment = new
        centroids = [
            tuple(sum(c) / len(c) for c in zip(*[p for p, a in zip(points, new) if a == j]))
            for j in range(K)
        ]
    return True


rng = random.Random(SEED)
points = draw(rng)
while has_near_tie(points):
    points = draw(rng)

print("x,y")
for x, y in points:
    print(f"{x:.2f},{y:.2f}")

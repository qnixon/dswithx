"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 100 students' scores (0 to 100) in math, physics,
reading, and writing. Each score comes from two hidden traits plus noise: a
general ability that lifts all four, and a lean that raises math and physics
while lowering reading and writing (or the reverse). PCA should recover both
traits from the scores alone.

The generator finds the correlation matrix's eigenvalues and eigenvectors
independently (by Jacobi rotations) and rejects any draw where:
  - the top three eigenvalues are not well separated, so power iteration
    might converge slowly;
  - the first entry of either of the top two eigenvectors is near zero, so
    the sign rule (first entry positive) could flip between languages.

    python3 make_data.py > data.csv
"""

import math
import random

SEED = 20261103
SUBJECTS = ("math", "physics", "reading", "writing")
ABILITY = (10, 10, 10, 10)  # how much general ability moves each score
LEAN = (6, 5, -6, -5)       # how much the math-versus-language lean moves it
NOISE = 5
MAX_RATIO = 0.8             # largest allowed eigenvalue ratio, next / current
MIN_FIRST = 0.1             # smallest allowed |first entry| of a top eigenvector


def draw(rng):
    rows = []
    for _ in range(100):
        g, lean = rng.gauss(0, 1), rng.gauss(0, 1)
        rows.append([max(0, min(100, round(70 + a * g + b * lean + rng.gauss(0, NOISE))))
                     for a, b in zip(ABILITY, LEAN)])
    return rows


def correlation(rows):
    n, k = len(rows), len(rows[0])
    cols = list(zip(*rows))
    means = [sum(c) / n for c in cols]
    sds = [math.sqrt(sum((v - m) ** 2 for v in c) / (n - 1)) for c, m in zip(cols, means)]
    z = [[(r[j] - means[j]) / sds[j] for j in range(k)] for r in rows]
    return [[sum(r[i] * r[j] for r in z) / (n - 1) for j in range(k)] for i in range(k)]


def jacobi(a):
    """Eigenvalues (descending) and eigenvectors (as rows) of a symmetric matrix."""
    k = len(a)
    a = [row[:] for row in a]
    v = [[float(i == j) for j in range(k)] for i in range(k)]
    for _ in range(100):
        for p in range(k):
            for q in range(p + 1, k):
                if abs(a[p][q]) < 1e-15:
                    continue
                theta = (a[q][q] - a[p][p]) / (2 * a[p][q])
                t = math.copysign(1, theta) / (abs(theta) + math.sqrt(theta * theta + 1))
                c = 1 / math.sqrt(t * t + 1)
                s = t * c
                for r in range(k):
                    arp, arq = a[r][p], a[r][q]
                    a[r][p], a[r][q] = c * arp - s * arq, s * arp + c * arq
                for r in range(k):
                    apr, aqr = a[p][r], a[q][r]
                    a[p][r], a[q][r] = c * apr - s * aqr, s * apr + c * aqr
                for r in range(k):
                    vrp, vrq = v[r][p], v[r][q]
                    v[r][p], v[r][q] = c * vrp - s * vrq, s * vrp + c * vrq
    pairs = sorted(((a[i][i], [v[r][i] for r in range(k)]) for i in range(k)), reverse=True)
    return [p[0] for p in pairs], [p[1] for p in pairs]


def unsafe(rows):
    values, vectors = jacobi(correlation(rows))
    if values[1] / values[0] > MAX_RATIO or values[2] / values[1] > MAX_RATIO:
        return True
    return any(abs(vectors[i][0]) < MIN_FIRST for i in range(2))


if __name__ == "__main__":
    rng = random.Random(SEED)
    rows = draw(rng)
    while unsafe(rows):
        rows = draw(rng)
    print(",".join(SUBJECTS))
    for row in rows:
        print(",".join(str(v) for v in row))

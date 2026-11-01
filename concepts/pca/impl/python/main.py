"""Principal component analysis by power iteration, using only the standard library.

Standardizes the four scores, builds their correlation matrix, and finds the
top two eigenvectors (the principal components): power iteration finds the
first, then deflation removes it from the matrix so the same steps find the
second.
"""

import csv
import math
import sys

SUBJECTS = ("math", "physics", "reading", "writing")
STEPS = 1000


def mat_vec(m, v):
    return [sum(a * b for a, b in zip(row, v)) for row in m]


def dot(u, v):
    return sum(a * b for a, b in zip(u, v))


def normalize(v):
    length = math.sqrt(dot(v, v))
    return [x / length for x in v]


def top_eigenvector(m):
    """Power iteration: multiply by the matrix and rescale, STEPS times."""
    v = [1.0] + [0.0] * (len(m) - 1)
    for _ in range(STEPS):
        v = normalize(mat_vec(m, v))
    # An eigenvector can point either way; make its first entry positive.
    if v[0] < 0:
        v = [-x for x in v]
    return dot(v, mat_vec(m, v)), v  # eigenvalue, eigenvector


def main():
    with open(sys.argv[1], newline="") as f:
        rows = [[float(row[s]) for s in SUBJECTS] for row in csv.DictReader(f)]
    n, k = len(rows), len(SUBJECTS)

    # Standardize each column to mean 0 and (sample) standard deviation 1.
    columns = list(zip(*rows))
    means = [sum(c) / n for c in columns]
    sds = [math.sqrt(sum((x - m) ** 2 for x in c) / (n - 1)) for c, m in zip(columns, means)]
    z = [[(x - m) / s for x, m, s in zip(row, means, sds)] for row in rows]

    # The correlation matrix: the covariance of the standardized columns.
    corr = [[sum(r[i] * r[j] for r in z) / (n - 1) for j in range(k)] for i in range(k)]

    value_1, pc_1 = top_eigenvector(corr)
    # Deflation: subtract the first component's share, leaving the rest.
    deflated = [[corr[i][j] - value_1 * pc_1[i] * pc_1[j] for j in range(k)] for i in range(k)]
    value_2, pc_2 = top_eigenvector(deflated)

    print(f"count {n}")
    for c, (value, pc) in enumerate([(value_1, pc_1), (value_2, pc_2)], start=1):
        print(f"eigenvalue_{c} {value:.6f}")
        # Standardized columns each have variance 1, so the total is k.
        print(f"explained_{c} {value / k:.6f}")
        for subject, loading in zip(SUBJECTS, pc):
            print(f"pc{c}_{subject} {loading:.6f}")
    print(f"student_1_pc1 {dot(z[0], pc_1):.6f}")
    print(f"student_1_pc2 {dot(z[0], pc_2):.6f}")


if __name__ == "__main__":
    main()

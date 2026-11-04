"""Train and test error for polynomials of degree 1 to 8, using only the
standard library.

Each polynomial is fitted by least squares to the training drives only:
we build the normal equations and solve them by Gaussian elimination. Then
we measure its root-mean-square error on the training drives and on the
test drives it never saw.
"""

import csv
import math
import sys

MAX_DEGREE = 8


def read(path):
    train, test = [], []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            point = (float(row["speed"]), float(row["litres"]))
            (train if row["split"] == "train" else test).append(point)
    return train, test


def solve(a, b):
    """Solve a x = b by Gaussian elimination with partial pivoting."""
    n = len(b)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]  # augmented matrix
    for col in range(n):
        # Swap up the row with the largest entry in this column, which keeps
        # the rounding error small.
        pivot = max(range(col, n), key=lambda r: abs(m[r][col]))
        m[col], m[pivot] = m[pivot], m[col]
        for r in range(col + 1, n):
            factor = m[r][col] / m[col][col]
            for c in range(col, n + 1):
                m[r][c] -= factor * m[col][c]
    # Back substitution, from the last unknown up.
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (m[r][n] - sum(m[r][c] * x[c] for c in range(r + 1, n))) / m[r][r]
    return x


def fit(points, degree, scale):
    # Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
    # of Z is 1, z_i, z_i^2, ..., z_i^degree.
    size = degree + 1
    a = [[0.0] * size for _ in range(size)]
    b = [0.0] * size
    for x, y in points:
        z = scale(x)
        for i in range(size):
            b[i] += y * z ** i
            for j in range(size):
                a[i][j] += z ** (i + j)
    return solve(a, b)


def rmse(coefs, points, scale):
    total = 0.0
    for x, y in points:
        z = scale(x)
        predicted = sum(c * z ** i for i, c in enumerate(coefs))
        total += (predicted - y) ** 2
    return math.sqrt(total / len(points))


def main():
    train, test = read(sys.argv[1])

    # Map the training speeds onto -1 to 1. Raw speeds to the 16th power
    # (the largest entry at degree 8) would swamp the small ones and make
    # the equations hard to solve accurately.
    low = min(x for x, _ in train)
    high = max(x for x, _ in train)
    mid, half = (low + high) / 2, (high - low) / 2

    def scale(x):
        return (x - mid) / half

    print(f"train_count {len(train)}")
    print(f"test_count {len(test)}")
    errors = []
    for degree in range(1, MAX_DEGREE + 1):
        coefs = fit(train, degree, scale)
        errors.append((degree, rmse(coefs, train, scale), rmse(coefs, test, scale)))
    for degree, train_error, _ in errors:
        print(f"train_rmse_d{degree} {train_error:.6f}")
    for degree, _, test_error in errors:
        print(f"test_rmse_d{degree} {test_error:.6f}")


if __name__ == "__main__":
    main()

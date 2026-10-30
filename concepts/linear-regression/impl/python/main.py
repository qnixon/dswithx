"""Simple linear regression by least squares, using only the standard library.

Fits score = intercept + slope * hours. (statistics.linear_regression would do
it in one call; the sums are written out so the formulas stay visible.)
"""

import csv
import math
import sys

X, Y = "hours", "score"


def main():
    with open(sys.argv[1], newline="") as f:
        rows = list(csv.DictReader(f))
    xs = [float(row[X]) for row in rows]
    ys = [float(row[Y]) for row in rows]

    n = len(xs)
    mean_x = sum(xs) / n
    mean_y = sum(ys) / n

    # Sums of squared deviations and of cross-products.
    sxx = sum((x - mean_x) ** 2 for x in xs)
    syy = sum((y - mean_y) ** 2 for y in ys)
    sxy = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))

    slope = sxy / sxx
    intercept = mean_y - slope * mean_x
    r = sxy / math.sqrt(sxx * syy)

    print(f"count {n}")
    print(f"slope {slope:.6f}")
    print(f"intercept {intercept:.6f}")
    print(f"r {r:.6f}")
    print(f"r_squared {r * r:.6f}")


if __name__ == "__main__":
    main()

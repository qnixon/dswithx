"""Simple linear regression with the statistics module.

The built-in version of ../python/main.py. statistics.linear_regression fits
score = intercept + slope * hours by least squares, and
statistics.correlation gives Pearson's r. Both arrived in Python 3.10.
"""

import csv
import statistics
import sys

X, Y = "hours", "score"


def main():
    with open(sys.argv[1], newline="") as f:
        rows = list(csv.DictReader(f))
    xs = [float(row[X]) for row in rows]
    ys = [float(row[Y]) for row in rows]

    slope, intercept = statistics.linear_regression(xs, ys)
    r = statistics.correlation(xs, ys)

    print(f"count {len(xs)}")
    print(f"slope {slope:.6f}")
    print(f"intercept {intercept:.6f}")
    print(f"r {r:.6f}")
    print(f"r_squared {r * r:.6f}")


if __name__ == "__main__":
    main()

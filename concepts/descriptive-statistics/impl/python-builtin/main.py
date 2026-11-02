"""Descriptive statistics on one CSV column, with the statistics module.

The built-in version of ../python/main.py: statistics.mean, median, variance,
and stdev do the arithmetic. variance and stdev are the sample versions,
dividing by n - 1.
"""

import csv
import statistics
import sys

COLUMN = "minutes"


def main():
    with open(sys.argv[1], newline="") as f:
        values = [float(row[COLUMN]) for row in csv.DictReader(f)]

    results = [
        ("sum", sum(values)),
        ("mean", statistics.mean(values)),
        ("median", statistics.median(values)),
        ("min", min(values)),
        ("max", max(values)),
        ("range", max(values) - min(values)),
        ("variance", statistics.variance(values)),
        ("std_dev", statistics.stdev(values)),
    ]

    print(f"count {len(values)}")
    for name, value in results:
        print(f"{name} {value:.6f}")


if __name__ == "__main__":
    main()

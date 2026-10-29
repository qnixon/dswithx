"""Descriptive statistics on one CSV column, using only the standard library.

The statistics module would do most of this in one call each; it is avoided
on purpose so the arithmetic stays visible.
"""

import csv
import math
import sys

COLUMN = "minutes"


def read_column(path, column):
    with open(path, newline="") as f:
        return [float(row[column]) for row in csv.DictReader(f)]


def median(sorted_values):
    n = len(sorted_values)
    middle = n // 2
    if n % 2 == 1:
        return sorted_values[middle]
    return (sorted_values[middle - 1] + sorted_values[middle]) / 2


def main():
    values = read_column(sys.argv[1], COLUMN)
    values.sort()

    n = len(values)
    total = sum(values)
    mean = total / n
    # Sample variance divides by n - 1, not n (Bessel's correction).
    variance = sum((x - mean) ** 2 for x in values) / (n - 1)

    results = [
        ("sum", total),
        ("mean", mean),
        ("median", median(values)),
        ("min", values[0]),
        ("max", values[-1]),
        ("range", values[-1] - values[0]),
        ("variance", variance),
        ("std_dev", math.sqrt(variance)),
    ]

    print(f"count {n}")
    for name, value in results:
        print(f"{name} {value:.6f}")


if __name__ == "__main__":
    main()

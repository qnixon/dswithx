"""Exact two-sided permutation test for a difference in means, using only
the standard library.

If compost made no difference, the "compost" and "control" labels are
arbitrary, and any 8 of the 16 plants could have carried the compost label.
We try every one of those splits and count how many give a difference at
least as large as the one we observed. That fraction is the p-value.
"""

import csv
import sys
from itertools import combinations


def read(path):
    groups = {"control": [], "compost": []}
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            groups[row["group"]].append(int(row["grams"]))
    return groups["control"], groups["compost"]


def main():
    control, compost = read(sys.argv[1])
    n = len(compost)
    plants = control + compost
    total = sum(plants)

    # Both groups have n plants, so comparing totals is the same as comparing
    # means, and totals stay whole numbers: no floating-point near-ties.
    observed = sum(compost) - sum(control)

    splits = 0
    as_extreme = 0
    for chosen in combinations(range(len(plants)), n):
        relabeled = sum(plants[i] for i in chosen)
        difference = relabeled - (total - relabeled)
        splits += 1
        if abs(difference) >= abs(observed):  # two-sided: either direction
            as_extreme += 1

    print(f"control_count {len(control)}")
    print(f"compost_count {n}")
    print(f"control_mean {sum(control) / len(control):.6f}")
    print(f"compost_mean {sum(compost) / n:.6f}")
    print(f"observed_difference {observed / n:.6f}")
    print(f"splits {splits}")
    print(f"as_extreme {as_extreme}")
    print(f"p_value {as_extreme / splits:.6f}")


if __name__ == "__main__":
    main()

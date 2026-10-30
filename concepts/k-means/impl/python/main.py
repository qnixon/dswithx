"""k-means clustering (Lloyd's algorithm), using only the standard library.

Starts from the first K points as centroids, then alternates two steps until
no point changes cluster: assign each point to its nearest centroid, and move
each centroid to the mean of its points.
"""

import csv
import math
import sys

K = 3
MAX_ITERATIONS = 100


def nearest(point, centroids):
    # min() returns the first of equal distances, so ties go to the lower index.
    return min(range(len(centroids)), key=lambda j: math.dist(point, centroids[j]))


def main():
    with open(sys.argv[1], newline="") as f:
        points = [(float(row["x"]), float(row["y"])) for row in csv.DictReader(f)]

    centroids = points[:K]
    assignment = None
    iterations = 0
    while iterations < MAX_ITERATIONS:
        iterations += 1
        new_assignment = [nearest(p, centroids) for p in points]
        if new_assignment == assignment:
            break
        assignment = new_assignment
        for j in range(K):
            members = [p for p, a in zip(points, assignment) if a == j]
            if members:  # an empty cluster keeps its old centroid
                centroids[j] = (
                    sum(x for x, _ in members) / len(members),
                    sum(y for _, y in members) / len(members),
                )

    sizes = [assignment.count(j) for j in range(K)]
    inertia = sum(math.dist(p, centroids[a]) ** 2 for p, a in zip(points, assignment))

    print(f"iterations {iterations}")
    for j, (x, y) in enumerate(centroids, start=1):
        print(f"centroid_{j}_x {x:.6f}")
        print(f"centroid_{j}_y {y:.6f}")
    for j, size in enumerate(sizes, start=1):
        print(f"size_{j} {size}")
    print(f"inertia {inertia:.6f}")


if __name__ == "__main__":
    main()

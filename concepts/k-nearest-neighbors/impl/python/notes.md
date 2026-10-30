Python is the baseline, and kNN fits in a few lines. `csv.DictReader` reads
the columns by header name, and the whole neighbor search is one expression:
`sorted(train, key=lambda seed: math.dist(point, seed[0]))[:K]`. Because
`sorted` is stable, seeds at an equal distance keep file order with no extra
work. `collections.Counter` counts the vote, and `most_common(1)` names the
winner.

It barely pushes back. Sorting all 150 seeds to keep 5 is more work than
needed; `heapq.nsmallest` would select just the five. The standard library
has no kNN classifier, so there was no built-in to skip. In real code you'd
reach for scikit-learn's `KNeighborsClassifier`, a separate package that
isn't installed in this image.

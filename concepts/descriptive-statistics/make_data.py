"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 120 one-way commute times in minutes, drawn from a
log-normal distribution (median about 28 minutes, with a long right tail),
so the mean and median differ in an instructive way.

    python3 make_data.py > data.csv
"""

import random

SEED = 20261029
ROWS = 120

rng = random.Random(SEED)
print("day,minutes")
for day in range(1, ROWS + 1):
    minutes = rng.lognormvariate(3.33, 0.3)
    print(f"{day},{minutes:.1f}")

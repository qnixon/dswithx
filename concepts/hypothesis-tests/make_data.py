"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: the tomato yield, in whole grams, of 16 plants. Eight
are controls and eight were grown with compost. Control yields are drawn from
a normal distribution with mean 410 g and standard deviation 45 g; compost
yields from one with mean 460 g, so compost truly adds 50 g on average.

Yields are whole grams so that every language can compare group totals
exactly, with no floating-point near-ties.

We drew 20 datasets this way, seeds 20261103 to 20261122, and their two-sided
p-values ranged from 0.0002 to 0.77. We chose seed 20261108 (p = 0.031) as a
clear but not overwhelming example; the concept page says so.

    python3 make_data.py > data.csv
"""

import random

SEED = 20261108
PLANTS = 8  # per group

rng = random.Random(SEED)
control = [round(rng.gauss(410, 45)) for _ in range(PLANTS)]
compost = [round(rng.gauss(460, 45)) for _ in range(PLANTS)]

print("group,grams")
for grams in control:
    print(f"control,{grams}")
for grams in compost:
    print(f"compost,{grams}")

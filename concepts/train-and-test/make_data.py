"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 36 drives of one car, each at a steady speed (km/h,
30 to 120) with its fuel use (litres per 100 km). The true curve is a gentle
U, 4.5 + 0.0009 * (speed - 65)^2, so the car is most economical near
65 km/h; each reading adds normal noise with standard deviation 0.45. The
first 12 rows are marked train and the other 24 test. The training set is
deliberately small, so high-degree polynomials can overfit it.

This is the first seed we drew; we didn't choose among draws.

    python3 make_data.py > data.csv
"""

import random

SEED = 20261105
TRAIN, TEST = 12, 24

rng = random.Random(SEED)
print("speed,litres,split")
for i in range(TRAIN + TEST):
    speed = round(rng.uniform(30, 120))
    litres = round(4.5 + 0.0009 * (speed - 65) ** 2 + rng.gauss(0, 0.45), 2)
    print(f"{speed},{litres},{'train' if i < TRAIN else 'test'}")

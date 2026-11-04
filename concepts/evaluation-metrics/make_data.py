"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 200 parts from a production line, each with whether it
is really defective (1) or not (0), and the score a model gave it, from 0 to
1, where higher means "more likely defective". About 15% of parts are
defective. Each part's score comes from a hidden signal that runs higher for
defective parts but overlaps with the good ones, so no threshold is perfect.

This is the first seed we drew; we didn't choose among draws. No score lands
exactly on the thresholds 0.3 or 0.5.

    python3 make_data.py > data.csv
"""

import math
import random

SEED = 20261104
PARTS = 200
DEFECT_RATE = 0.15

rng = random.Random(SEED)
print("defective,score")
for _ in range(PARTS):
    defective = 1 if rng.random() < DEFECT_RATE else 0
    signal = rng.gauss(1.6 if defective else 0.0, 1.0)
    score = 1 / (1 + math.exp(-(signal - 1.8)))
    print(f"{defective},{score:.3f}")

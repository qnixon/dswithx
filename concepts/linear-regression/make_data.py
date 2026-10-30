"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 100 students' weekly study hours and exam scores. Each
score is a straight line in hours plus normal noise, kept within 0 to 100.

    python3 make_data.py > data.csv
"""

import random

SEED = 20261030
ROWS = 100

rng = random.Random(SEED)
print("hours,score")
for _ in range(ROWS):
    hours = rng.uniform(0.5, 10.0)
    score = min(100.0, max(0.0, 42.0 + 5.2 * hours + rng.gauss(0, 6)))
    print(f"{hours:.1f},{score:.1f}")

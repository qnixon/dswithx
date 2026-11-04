"""Generate data.csv for this concept. Run once; the output is committed.

Cross-validation reuses the k-nearest neighbors data unchanged: 200
synthetic wheat seeds, 150 marked train and 50 test. See
../k-nearest-neighbors/make_data.py for how they were drawn.

    python3 make_data.py > data.csv
"""

import sys
from pathlib import Path

source = Path(__file__).resolve().parent.parent / "k-nearest-neighbors" / "data.csv"
sys.stdout.write(source.read_text())

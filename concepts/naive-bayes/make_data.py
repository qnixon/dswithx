"""Generate data.csv for this concept. Run once; the output is committed.

The data is synthetic: 200 emails labelled spam or ham, each described by
three yes/no features. Spam is more likely to have a link and mention money,
and less likely to come from a known sender. Rows are shuffled; the first 150
are marked train and the last 50 test.

    python3 make_data.py > data.csv
"""

import random

SEED = 20261102
ROWS = 200
P_SPAM = 0.4
# P(feature is "yes" | label)
P_YES = {
    "has_link": {"spam": 0.8, "ham": 0.3},
    "mentions_money": {"spam": 0.7, "ham": 0.1},
    "known_sender": {"spam": 0.1, "ham": 0.7},
}

rng = random.Random(SEED)
rows = []
for _ in range(ROWS):
    label = "spam" if rng.random() < P_SPAM else "ham"
    features = ["yes" if rng.random() < P_YES[f][label] else "no" for f in P_YES]
    rows.append((*features, label))
rng.shuffle(rows)

print(",".join(P_YES) + ",label,split")
for i, row in enumerate(rows):
    print(",".join(row) + ("," + ("train" if i < 150 else "test")))
